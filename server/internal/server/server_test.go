package server

import (
	"context"
	"io"
	"log/slog"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/config"
)

const testToken = "flit_test-token"

func start(t *testing.T) (*Server, string) {
	t.Helper()
	srv := New(NewHandler(testToken, Deps{}), slog.New(slog.NewTextHandler(io.Discard, nil)))
	cfg := config.Default()
	cfg.Listen = "127.0.0.1:0"
	if err := srv.Apply(cfg); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = srv.Shutdown(context.Background()) })
	return srv, "http://" + srv.Addr().String()
}

func client(baseURL, token string, opts ...connecthttp.Option) flitv1connect.SystemServiceClient {
	return clientWith(http.DefaultClient, baseURL, token, opts...)
}

func clientWith(hc *http.Client, baseURL, token string, opts ...connecthttp.Option) flitv1connect.SystemServiceClient {
	if token != "" {
		return flitv1connect.NewSystemServiceClient(connect.NewClient(connecthttp.NewTransport(hc, baseURL, append(opts, connecthttp.WithReadMaxBytes(0))...), bearer(token)))
	}
	return flitv1connect.NewSystemServiceClient(connect.NewClient(connecthttp.NewTransport(hc, baseURL, append(opts, connecthttp.WithReadMaxBytes(0))...)))
}

// h2cClient speaks HTTP/2 without TLS, as gRPC clients do against a plain
// HTTP server.
func h2cClient() *http.Client {
	p := new(http.Protocols)
	p.SetUnencryptedHTTP2(true)
	return &http.Client{Transport: &http.Transport{Protocols: p}}
}

func bearer(token string) connect.ClientInterceptor {
	return func(next connect.ClientFunc) connect.ClientFunc {
		return func(ctx context.Context, spec connect.Spec) (connect.ClientStream, error) {
			ctx, info := connect.NewClientContext(ctx)
			info.RequestHeader().Set("Authorization", "Bearer "+token)
			return next(ctx, spec)
		}
	}
}

func TestAuth(t *testing.T) {
	_, url := start(t)
	ctx := context.Background()

	for name, tc := range map[string]struct {
		hc   *http.Client
		opts []connecthttp.Option
	}{
		"connect": {http.DefaultClient, nil},
		"grpc":    {h2cClient(), []connecthttp.Option{connecthttp.WithGRPC()}},
	} {
		t.Run(name, func(t *testing.T) {
			client := func(baseURL, token string) flitv1connect.SystemServiceClient {
				return clientWith(tc.hc, baseURL, token, tc.opts...)
			}
			res, err := client(url, testToken).Version(ctx, &flitv1.VersionRequest{})
			if err != nil {
				t.Fatalf("authenticated Version: %v", err)
			}
			if res.ApiVersion != "v1" || res.Version == "" {
				t.Fatalf("unexpected version response %+v", res)
			}

			health, err := client(url, testToken).Health(ctx, &flitv1.HealthRequest{})
			if err != nil {
				t.Fatalf("authenticated Health: %v", err)
			}
			if health.Status != flitv1.HealthResponse_STATUS_SERVING {
				t.Fatalf("health = %v", health.Status)
			}

			for name, tok := range map[string]string{"no token": "", "wrong token": "flit_nope"} {
				_, err := client(url, tok).Version(ctx, &flitv1.VersionRequest{})
				if connect.CodeOf(err) != connect.CodeUnauthenticated {
					t.Errorf("%s: err = %v, want unauthenticated", name, err)
				}
				_, err = client(url, tok).Health(ctx, &flitv1.HealthRequest{})
				if connect.CodeOf(err) != connect.CodeUnauthenticated {
					t.Errorf("%s: Health err = %v, want unauthenticated", name, err)
				}
			}
		})
	}
}

func TestApplyRebinds(t *testing.T) {
	srv, oldURL := start(t)
	ctx := context.Background()

	// Same settings: no rebind.
	addr := srv.Addr()
	cfg := config.Default()
	cfg.Listen = "127.0.0.1:0"
	cfg.Log.Level = "debug"
	if err := srv.Apply(cfg); err != nil {
		t.Fatal(err)
	}
	if srv.Addr() != addr {
		t.Fatal("rebound although listen/TLS did not change")
	}

	// New address: the server moves and the old one goes away.
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	newAddr := ln.Addr().String()
	ln.Close()
	cfg.Listen = newAddr
	if err := srv.Apply(cfg); err != nil {
		t.Fatal(err)
	}
	if _, err := client("http://"+newAddr, testToken).Version(ctx, &flitv1.VersionRequest{}); err != nil {
		t.Fatalf("new address: %v", err)
	}
	deadline := time.Now().Add(5 * time.Second)
	for {
		_, err := client(oldURL, testToken).Version(ctx, &flitv1.VersionRequest{})
		if connect.CodeOf(err) == connect.CodeUnavailable {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("old address still serving: err = %v", err)
		}
		time.Sleep(50 * time.Millisecond)
	}

	// An address that can't be bound leaves the current one serving.
	busy, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer busy.Close()
	cfg.Listen = busy.Addr().String()
	if err := srv.Apply(cfg); err == nil {
		t.Fatal("expected bind error")
	}
	if got := srv.Addr().String(); got != newAddr {
		t.Fatalf("serving %s after failed rebind, want %s", got, newAddr)
	}
	if _, err := client("http://"+newAddr, testToken).Version(ctx, &flitv1.VersionRequest{}); err != nil {
		t.Fatalf("after failed rebind: %v", err)
	}
}

func TestTLSMissingFiles(t *testing.T) {
	srv := New(NewHandler(testToken, Deps{}), slog.New(slog.NewTextHandler(io.Discard, nil)))
	cfg := config.Default()
	cfg.Listen = "127.0.0.1:0"
	cfg.TLS = config.TLS{CertFile: "/nonexistent/cert.pem", KeyFile: "/nonexistent/key.pem"}
	err := srv.Apply(cfg)
	if err == nil {
		_ = srv.Shutdown(context.Background())
		t.Fatal("expected error for missing cert files")
	}
}

func TestWebhooksNeedNoToken(t *testing.T) {
	var got string
	h := NewHandler(testToken, Deps{Webhooks: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		got = r.URL.Path
		w.WriteHeader(http.StatusAccepted)
	})})
	srv := httptest.NewServer(h)
	defer srv.Close()
	resp, err := http.Post(srv.URL+"/webhooks/gh", "application/json", strings.NewReader("{}"))
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusAccepted || got != "/webhooks/gh" {
		t.Fatalf("webhook: %d %q", resp.StatusCode, got)
	}
	// The API still wants the token.
	if _, err := client(srv.URL, "").Version(context.Background(), &flitv1.VersionRequest{}); connect.CodeOf(err) != connect.CodeUnauthenticated {
		t.Fatalf("Version without a token: %v", err)
	}
}
