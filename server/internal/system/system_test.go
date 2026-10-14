package system_test

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	"connectrpc.com/connect"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/devices"
	"github.com/iggy/flit/server/internal/server"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/system"
)

const admin = "flit_admin-test"

type bearer string

func (b bearer) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		if b != "" {
			req.Header().Set("Authorization", "Bearer "+string(b))
		}
		return next(ctx, req)
	}
}
func (b bearer) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return next
}
func (b bearer) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return next
}

func setup(t *testing.T) string {
	t.Helper()
	st, err := store.Open(context.Background(), filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	cfg := config.Default()
	cfg.PublicURL = "https://flit.example.com/"
	current := func() config.Config { return cfg }
	m, err := agent.NewManager(context.Background(), st, current, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewServer(server.NewHandler(admin, server.Deps{Sessions: m, Devices: devices.New(st), Config: current}))
	t.Cleanup(func() {
		srv.Close()
		m.Close()
		st.Close()
	})
	return srv.URL
}

func sys(url, tok string) flitv1connect.SystemServiceClient {
	return flitv1connect.NewSystemServiceClient(http.DefaultClient, url, connect.WithInterceptors(bearer(tok)))
}

func sessions(url, tok string) flitv1connect.SessionServiceClient {
	return flitv1connect.NewSessionServiceClient(http.DefaultClient, url, connect.WithInterceptors(bearer(tok)))
}

func TestPairingFlow(t *testing.T) {
	url := setup(t)
	ctx := context.Background()

	code, err := sys(url, admin).CreatePairingCode(ctx, connect.NewRequest(&flitv1.CreatePairingCodeRequest{}))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(code.Msg.Code, "-") || len(code.Msg.Code) != 9 || code.Msg.ServerUrl != "https://flit.example.com" {
		t.Fatalf("code = %v", code.Msg)
	}

	// Pair needs no token; lower case and no dash are fine.
	typed := strings.ToLower(strings.ReplaceAll(code.Msg.Code, "-", ""))
	paired, err := sys(url, "").Pair(ctx, connect.NewRequest(&flitv1.PairRequest{Code: typed, DeviceName: "Test Phone"}))
	if err != nil {
		t.Fatal(err)
	}
	devTok := paired.Msg.Token
	if !strings.HasPrefix(devTok, "flitd_") || paired.Msg.Device.Name != "Test Phone" {
		t.Fatalf("paired = %v", paired.Msg)
	}

	// The code worked once.
	if _, err := sys(url, "").Pair(ctx, connect.NewRequest(&flitv1.PairRequest{Code: code.Msg.Code})); connect.CodeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("reused code: %v", err)
	}

	// The device token works for normal calls but not admin ones.
	if _, err := sys(url, devTok).Version(ctx, connect.NewRequest(&flitv1.VersionRequest{})); err != nil {
		t.Fatalf("device Version: %v", err)
	}
	if _, err := sessions(url, devTok).ListSessions(ctx, connect.NewRequest(&flitv1.ListSessionsRequest{})); err != nil {
		t.Fatalf("device ListSessions: %v", err)
	}
	for name, err := range map[string]error{
		"CreatePairingCode": second(sys(url, devTok).CreatePairingCode(ctx, connect.NewRequest(&flitv1.CreatePairingCodeRequest{}))),
		"ListDevices":       second(sys(url, devTok).ListDevices(ctx, connect.NewRequest(&flitv1.ListDevicesRequest{}))),
		"RevokeDevice":      second(sys(url, devTok).RevokeDevice(ctx, connect.NewRequest(&flitv1.RevokeDeviceRequest{DeviceId: "x"}))),
	} {
		if connect.CodeOf(err) != connect.CodePermissionDenied {
			t.Errorf("device %s: %v", name, err)
		}
	}
	// Admin-only calls also reject no token at all.
	if _, err := sys(url, "").ListDevices(ctx, connect.NewRequest(&flitv1.ListDevicesRequest{})); connect.CodeOf(err) != connect.CodeUnauthenticated {
		t.Fatalf("anonymous ListDevices: %v", err)
	}

	list, err := sys(url, admin).ListDevices(ctx, connect.NewRequest(&flitv1.ListDevicesRequest{}))
	if err != nil || len(list.Msg.Devices) != 1 || list.Msg.Devices[0].LastSeenTime == nil {
		t.Fatalf("ListDevices = %v, %v", list, err)
	}

	// Revocation takes effect immediately.
	if _, err := sys(url, admin).RevokeDevice(ctx, connect.NewRequest(&flitv1.RevokeDeviceRequest{DeviceId: paired.Msg.Device.Id})); err != nil {
		t.Fatal(err)
	}
	if _, err := sys(url, devTok).Version(ctx, connect.NewRequest(&flitv1.VersionRequest{})); connect.CodeOf(err) != connect.CodeUnauthenticated {
		t.Fatalf("revoked device: %v", err)
	}
	list, _ = sys(url, admin).ListDevices(ctx, connect.NewRequest(&flitv1.ListDevicesRequest{}))
	all, _ := sys(url, admin).ListDevices(ctx, connect.NewRequest(&flitv1.ListDevicesRequest{IncludeRevoked: true}))
	if len(list.Msg.Devices) != 0 || len(all.Msg.Devices) != 1 || all.Msg.Devices[0].RevokeTime == nil {
		t.Fatalf("after revoke: %v / %v", list.Msg, all.Msg)
	}
	if _, err := sys(url, admin).RevokeDevice(ctx, connect.NewRequest(&flitv1.RevokeDeviceRequest{DeviceId: "dev_nope"})); connect.CodeOf(err) != connect.CodeNotFound {
		t.Fatalf("revoke unknown: %v", err)
	}
}

func TestGuessingInvalidatesCodes(t *testing.T) {
	url := setup(t)
	ctx := context.Background()
	code, err := sys(url, admin).CreatePairingCode(ctx, connect.NewRequest(&flitv1.CreatePairingCodeRequest{}))
	if err != nil {
		t.Fatal(err)
	}
	for range 10 {
		if _, err := sys(url, "").Pair(ctx, connect.NewRequest(&flitv1.PairRequest{Code: "AAAA-AAAA"})); err == nil {
			t.Fatal("wrong code accepted")
		}
	}
	if _, err := sys(url, "").Pair(ctx, connect.NewRequest(&flitv1.PairRequest{Code: code.Msg.Code})); connect.CodeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("code survived guessing: %v", err)
	}
}

func TestServerURL(t *testing.T) {
	cfg := config.Default()
	if got := system.ServerURL(cfg); got != "http://127.0.0.1:7433" {
		t.Errorf("loopback: %s", got)
	}
	cfg.Listen = "0.0.0.0:9000"
	cfg.TLS = config.TLS{CertFile: "c", KeyFile: "k"}
	if got := system.ServerURL(cfg); !strings.HasPrefix(got, "https://") || !strings.HasSuffix(got, ":9000") || strings.Contains(got, "0.0.0.0") {
		t.Errorf("wildcard: %s", got)
	}
	cfg.PublicURL = "https://x.example/"
	if got := system.ServerURL(cfg); got != "https://x.example" {
		t.Errorf("public: %s", got)
	}
}

func second[T any](_ T, err error) error { return err }
