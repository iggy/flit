// Package system implements flit.v1.SystemService.
package system

import (
	"context"

	"connectrpc.com/connect"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/buildinfo"
)

// Service implements flitv1connect.SystemServiceHandler.
type Service struct{}

var _ flitv1connect.SystemServiceHandler = Service{}

// Version implements flitv1connect.SystemServiceHandler.
func (Service) Version(context.Context, *connect.Request[flitv1.VersionRequest]) (*connect.Response[flitv1.VersionResponse], error) {
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
func (Service) Health(context.Context, *connect.Request[flitv1.HealthRequest]) (*connect.Response[flitv1.HealthResponse], error) {
	return connect.NewResponse(&flitv1.HealthResponse{
		Status: flitv1.HealthResponse_STATUS_SERVING,
	}), nil
}
