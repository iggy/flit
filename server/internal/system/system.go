// Package system implements flit.v1.SystemService.
package system

import (
	"context"
	"errors"
	"net"
	"net/url"
	"strings"

	"connectrpc.com/connect"
	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/buildinfo"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/devices"
	"github.com/iggy/flit/server/internal/store"
)

// Service implements flitv1connect.SystemServiceHandler.
type Service struct {
	// Devices pairs and lists devices. Nil disables pairing.
	Devices *devices.Registry
	// Config returns the current config (for the server URL).
	Config func() config.Config
}

var _ flitv1connect.SystemServiceHandler = (*Service)(nil)

// AdminOnly lists the procedures that need the admin token.
var AdminOnly = []string{
	flitv1connect.SystemServiceCreatePairingCodeProcedure,
	flitv1connect.SystemServiceListDevicesProcedure,
	flitv1connect.SystemServiceRevokeDeviceProcedure,
}

// Public lists the procedures that need no token.
var Public = []string{flitv1connect.SystemServicePairProcedure}

// Version implements flitv1connect.SystemServiceHandler.
func (*Service) Version(context.Context, *connect.Request[flitv1.VersionRequest]) (*connect.Response[flitv1.VersionResponse], error) {
	bi := buildinfo.Get()
	return connect.NewResponse(&flitv1.VersionResponse{
		Version:    bi.Version,
		Commit:     bi.Commit,
		BuildTime:  bi.BuildTime,
		GoVersion:  bi.GoVersion,
		Os:         bi.OS,
		Arch:       bi.Arch,
		ApiVersion: buildinfo.APIVersion,
	}), nil
}

// Health implements flitv1connect.SystemServiceHandler. A server that can
// answer is serving.
func (*Service) Health(context.Context, *connect.Request[flitv1.HealthRequest]) (*connect.Response[flitv1.HealthResponse], error) {
	return connect.NewResponse(&flitv1.HealthResponse{
		Status: flitv1.HealthResponse_STATUS_SERVING,
	}), nil
}

var errNoPairing = connect.NewError(connect.CodeUnimplemented, errors.New("pairing is not enabled"))

// CreatePairingCode implements flitv1connect.SystemServiceHandler.
func (s *Service) CreatePairingCode(context.Context, *connect.Request[flitv1.CreatePairingCodeRequest]) (*connect.Response[flitv1.CreatePairingCodeResponse], error) {
	if s.Devices == nil {
		return nil, errNoPairing
	}
	code, exp := s.Devices.CreateCode()
	res := &flitv1.CreatePairingCodeResponse{Code: code, ExpireTime: timestamppb.New(exp)}
	if s.Config != nil {
		res.ServerUrl = ServerURL(s.Config())
	}
	return connect.NewResponse(res), nil
}

// Pair implements flitv1connect.SystemServiceHandler.
func (s *Service) Pair(ctx context.Context, req *connect.Request[flitv1.PairRequest]) (*connect.Response[flitv1.PairResponse], error) {
	if s.Devices == nil {
		return nil, errNoPairing
	}
	d, token, err := s.Devices.Pair(ctx, req.Msg.Code, req.Msg.DeviceName)
	if errors.Is(err, devices.ErrBadCode) {
		return nil, connect.NewError(connect.CodePermissionDenied, err)
	}
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&flitv1.PairResponse{Device: deviceProto(d), Token: token}), nil
}

// ListDevices implements flitv1connect.SystemServiceHandler.
func (s *Service) ListDevices(ctx context.Context, req *connect.Request[flitv1.ListDevicesRequest]) (*connect.Response[flitv1.ListDevicesResponse], error) {
	if s.Devices == nil {
		return nil, errNoPairing
	}
	list, err := s.Devices.List(ctx, req.Msg.IncludeRevoked)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	res := &flitv1.ListDevicesResponse{}
	for _, d := range list {
		res.Devices = append(res.Devices, deviceProto(d))
	}
	return connect.NewResponse(res), nil
}

// RevokeDevice implements flitv1connect.SystemServiceHandler.
func (s *Service) RevokeDevice(ctx context.Context, req *connect.Request[flitv1.RevokeDeviceRequest]) (*connect.Response[flitv1.RevokeDeviceResponse], error) {
	if s.Devices == nil {
		return nil, errNoPairing
	}
	err := s.Devices.Revoke(ctx, req.Msg.DeviceId)
	if errors.Is(err, store.ErrNotFound) {
		return nil, connect.NewError(connect.CodeNotFound, err)
	}
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&flitv1.RevokeDeviceResponse{}), nil
}

func deviceProto(d store.Device) *flitv1.Device {
	p := &flitv1.Device{Id: d.ID, Name: d.Name, CreateTime: timestamppb.New(d.CreatedAt)}
	if !d.LastSeenAt.IsZero() {
		p.LastSeenTime = timestamppb.New(d.LastSeenAt)
	}
	if !d.RevokedAt.IsZero() {
		p.RevokeTime = timestamppb.New(d.RevokedAt)
	}
	return p
}

// ServerURL is the URL clients should use to reach the server: public_url
// if set, otherwise a guess from the listen address. A wildcard listen
// address (0.0.0.0, ::) becomes this machine's first non-loopback IPv4
// address.
func ServerURL(cfg config.Config) string {
	if cfg.PublicURL != "" {
		return strings.TrimSuffix(cfg.PublicURL, "/")
	}
	scheme := "http"
	if cfg.TLS.Enabled() {
		scheme = "https"
	}
	host, port, err := net.SplitHostPort(cfg.Listen)
	if err != nil {
		return ""
	}
	if ip := net.ParseIP(host); host == "" || (ip != nil && ip.IsUnspecified()) {
		host = lanIP()
		if host == "" {
			host = "127.0.0.1"
		}
	}
	return (&url.URL{Scheme: scheme, Host: net.JoinHostPort(host, port)}).String()
}

func lanIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return ""
	}
	for _, a := range addrs {
		if n, ok := a.(*net.IPNet); ok && !n.IP.IsLoopback() && n.IP.To4() != nil && !n.IP.IsLinkLocalUnicast() {
			return n.IP.String()
		}
	}
	return ""
}
