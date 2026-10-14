// Package modelsvc implements flit.v1.ModelService and flit.v1.RoleService.
package modelsvc

import (
	"context"

	"connectrpc.com/connect"
	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/roles"
)

// Models implements flitv1connect.ModelServiceHandler.
type Models struct {
	Catalog *models.Catalog
}

var _ flitv1connect.ModelServiceHandler = (*Models)(nil)

func kindProto(k models.Kind) flitv1.ProviderKind {
	switch k {
	case models.KindOpenAI:
		return flitv1.ProviderKind_PROVIDER_KIND_OPENAI
	case models.KindOpenRouter:
		return flitv1.ProviderKind_PROVIDER_KIND_OPENROUTER
	case models.KindLlamaCpp:
		return flitv1.ProviderKind_PROVIDER_KIND_LLAMACPP
	case models.KindGoModel:
		return flitv1.ProviderKind_PROVIDER_KIND_GOMODEL
	}
	return flitv1.ProviderKind_PROVIDER_KIND_UNSPECIFIED
}

func (s *Models) providers() []*flitv1.Provider {
	var out []*flitv1.Provider
	for _, p := range s.Catalog.Providers() {
		pp := &flitv1.Provider{Name: p.Name, BaseUrl: p.BaseURL, Kind: kindProto(p.Kind), ModelCount: int32(p.ModelCount), Error: p.Err}
		if !p.Refreshed.IsZero() {
			pp.RefreshTime = timestamppb.New(p.Refreshed)
		}
		out = append(out, pp)
	}
	return out
}

// ListProviders implements flitv1connect.ModelServiceHandler.
func (s *Models) ListProviders(context.Context, *connect.Request[flitv1.ListProvidersRequest]) (*connect.Response[flitv1.ListProvidersResponse], error) {
	return connect.NewResponse(&flitv1.ListProvidersResponse{Providers: s.providers()}), nil
}

// ListModels implements flitv1connect.ModelServiceHandler.
func (s *Models) ListModels(_ context.Context, req *connect.Request[flitv1.ListModelsRequest]) (*connect.Response[flitv1.ListModelsResponse], error) {
	res := &flitv1.ListModelsResponse{}
	for _, m := range s.Catalog.Models(req.Msg.Provider) {
		res.Models = append(res.Models, &flitv1.Model{
			Provider:          m.Provider,
			Id:                m.ID,
			DisplayName:       m.DisplayName,
			ContextLength:     m.ContextLength,
			SupportsTools:     m.SupportsTools,
			SupportsReasoning: m.SupportsReasoning,
			SupportsVision:    m.SupportsVision,
			Efforts:           m.Efforts,
			Loaded:            m.Loaded,
			Discovered:        m.Discovered,
			Overridden:        m.Overridden,
		})
	}
	return connect.NewResponse(res), nil
}

// Refresh implements flitv1connect.ModelServiceHandler.
func (s *Models) Refresh(ctx context.Context, req *connect.Request[flitv1.RefreshRequest]) (*connect.Response[flitv1.RefreshResponse], error) {
	if err := s.Catalog.Refresh(ctx, req.Msg.Provider); err != nil {
		return nil, connect.NewError(connect.CodeNotFound, err)
	}
	return connect.NewResponse(&flitv1.RefreshResponse{Providers: s.providers()}), nil
}

// Roles implements flitv1connect.RoleServiceHandler.
type Roles struct {
	Dir func() string
}

var _ flitv1connect.RoleServiceHandler = (*Roles)(nil)

// ListRoles implements flitv1connect.RoleServiceHandler.
func (s *Roles) ListRoles(context.Context, *connect.Request[flitv1.ListRolesRequest]) (*connect.Response[flitv1.ListRolesResponse], error) {
	list, err := roles.List(s.Dir())
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	res := &flitv1.ListRolesResponse{}
	for _, r := range list {
		ar := &flitv1.AgentRole{
			Name: r.Name, Description: r.Description, Provider: r.Provider,
			Model: r.Model, Effort: r.Effort, MemoryFile: r.MemoryFile,
		}
		if r.Err != nil {
			ar.Error = r.Err.Error()
		}
		res.Roles = append(res.Roles, ar)
	}
	return connect.NewResponse(res), nil
}
