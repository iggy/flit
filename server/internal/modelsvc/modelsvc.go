// Package modelsvc implements flit.v1.ModelService and flit.v1.RoleService.
package modelsvc

import (
	"context"
	"errors"

	"connectrpc.com/connect"
	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/roles"
	"github.com/iggy/flit/server/internal/store"
)

// Models implements flitv1connect.ModelServiceHandler.
type Models struct {
	Catalog *models.Catalog
	// Store holds favorites and recents; nil means none.
	Store *store.Store
}

// prefsTeam is whose favorites and recents the API reads and writes. There
// is one team for now; this becomes the caller's team when there are more.
const prefsTeam = store.DefaultTeamID

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
		pp := &flitv1.Provider{Name: p.Name, BaseUrl: p.BaseURL, Kind: kindProto(p.Kind), ModelCount: int32(p.ModelCount), Error: p.Err, CanLoadModels: p.CanLoad}
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
func (s *Models) ListModels(ctx context.Context, req *connect.Request[flitv1.ListModelsRequest]) (*connect.Response[flitv1.ListModelsResponse], error) {
	prefs, err := s.prefs(ctx)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	res := &flitv1.ListModelsResponse{}
	for _, m := range s.Catalog.Models(req.Msg.Provider) {
		res.Models = append(res.Models, modelProto(m, prefs[store.ModelKey{Provider: m.Provider, Model: m.ID}], s.Catalog.Kind(m.Provider) == models.KindLlamaCpp))
	}
	return connect.NewResponse(res), nil
}

func (s *Models) prefs(ctx context.Context) (map[store.ModelKey]store.ModelPref, error) {
	if s.Store == nil {
		return nil, nil
	}
	return s.Store.ModelPrefs(ctx, prefsTeam)
}

func modelProto(m models.Model, pref store.ModelPref, llama bool) *flitv1.Model {
	pm := &flitv1.Model{
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
		Favorite:          pref.Favorite,
		State:             stateProto(m.State),
		CanEndReasoning:   llama && !pref.NoReasoningEnd,
	}
	if !pref.LastUsed.IsZero() {
		pm.LastUsed = timestamppb.New(pref.LastUsed)
	}
	return pm
}

func stateProto(st models.State) flitv1.ModelState {
	switch st {
	case models.StateUnloaded:
		return flitv1.ModelState_MODEL_STATE_UNLOADED
	case models.StateLoading:
		return flitv1.ModelState_MODEL_STATE_LOADING
	case models.StateLoaded:
		return flitv1.ModelState_MODEL_STATE_LOADED
	case models.StateSleeping:
		return flitv1.ModelState_MODEL_STATE_SLEEPING
	case models.StateFailed:
		return flitv1.ModelState_MODEL_STATE_FAILED
	}
	return flitv1.ModelState_MODEL_STATE_UNSPECIFIED
}

// SetFavorite implements flitv1connect.ModelServiceHandler.
func (s *Models) SetFavorite(ctx context.Context, req *connect.Request[flitv1.SetFavoriteRequest]) (*connect.Response[flitv1.SetFavoriteResponse], error) {
	m := req.Msg
	if m.Provider == "" || m.Model == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("provider and model are required"))
	}
	if s.Store == nil {
		return nil, connect.NewError(connect.CodeUnimplemented, errors.New("favorites are not enabled"))
	}
	if err := s.Store.SetFavorite(ctx, prefsTeam, store.ModelKey{Provider: m.Provider, Model: m.Model}, m.Favorite); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&flitv1.SetFavoriteResponse{}), nil
}

// LoadModel implements flitv1connect.ModelServiceHandler.
func (s *Models) LoadModel(ctx context.Context, req *connect.Request[flitv1.LoadModelRequest]) (*connect.Response[flitv1.LoadModelResponse], error) {
	m, err := s.setLoaded(ctx, req.Msg.Provider, req.Msg.Model, true)
	if err != nil {
		return nil, err
	}
	return connect.NewResponse(&flitv1.LoadModelResponse{Model: m}), nil
}

// UnloadModel implements flitv1connect.ModelServiceHandler.
func (s *Models) UnloadModel(ctx context.Context, req *connect.Request[flitv1.UnloadModelRequest]) (*connect.Response[flitv1.UnloadModelResponse], error) {
	m, err := s.setLoaded(ctx, req.Msg.Provider, req.Msg.Model, false)
	if err != nil {
		return nil, err
	}
	return connect.NewResponse(&flitv1.UnloadModelResponse{Model: m}), nil
}

func (s *Models) setLoaded(ctx context.Context, provider, model string, load bool) (*flitv1.Model, error) {
	if provider == "" || model == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("provider and model are required"))
	}
	m, err := s.Catalog.SetLoaded(ctx, provider, model, load)
	switch {
	case errors.Is(err, models.ErrCantLoad):
		return nil, connect.NewError(connect.CodeFailedPrecondition, err)
	case err != nil:
		return nil, connect.NewError(connect.CodeUnavailable, err)
	}
	prefs, err := s.prefs(ctx)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return modelProto(m, prefs[store.ModelKey{Provider: m.Provider, Model: m.ID}], s.Catalog.Kind(m.Provider) == models.KindLlamaCpp), nil
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
