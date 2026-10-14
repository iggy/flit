// Package sessionsvc implements flit.v1.SessionService on top of
// agent.Manager.
package sessionsvc

import (
	"context"
	"errors"
	"strconv"

	"connectrpc.com/connect"
	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/auth"
	"github.com/iggy/flit/server/internal/store"
)

const (
	defaultPageSize = 50
	maxPageSize     = 200
)

// Service implements flitv1connect.SessionServiceHandler.
type Service struct {
	M *agent.Manager
}

var _ flitv1connect.SessionServiceHandler = (*Service)(nil)

func toProto(s store.Session) *flitv1.Session {
	return &flitv1.Session{
		Id:            s.ID,
		TeamId:        s.TeamID,
		ProjectId:     s.ProjectID,
		Title:         s.Title,
		WorkingDir:    s.WorkingDir,
		Provider:      s.Provider,
		Model:         s.Model,
		State:         s.State,
		LastSeq:       s.LastSeq,
		CreateTime:    timestamppb.New(s.CreatedAt),
		UpdateTime:    timestamppb.New(s.UpdatedAt),
		Effort:        s.Effort,
		Role:          s.Role,
		ContextTokens: s.ContextTokens,
		ContextLength: s.ContextLength,
	}
}

// connectErr maps agent errors to Connect codes.
func connectErr(err error) error {
	if err == nil {
		return nil
	}
	code := connect.CodeInternal
	switch {
	case errors.Is(err, agent.ErrNotFound):
		code = connect.CodeNotFound
	case errors.Is(err, agent.ErrInvalid):
		code = connect.CodeInvalidArgument
	case errors.Is(err, agent.ErrBusy), errors.Is(err, agent.ErrPromptGone):
		code = connect.CodeFailedPrecondition
	case errors.Is(err, agent.ErrSlowClient):
		code = connect.CodeResourceExhausted
	case errors.Is(err, context.Canceled):
		code = connect.CodeCanceled
	}
	return connect.NewError(code, err)
}

func required(name, v string) error {
	if v == "" {
		return connect.NewError(connect.CodeInvalidArgument, errors.New(name+" is required"))
	}
	return nil
}

// CreateSession implements flitv1connect.SessionServiceHandler.
func (s *Service) CreateSession(ctx context.Context, req *connect.Request[flitv1.CreateSessionRequest]) (*connect.Response[flitv1.CreateSessionResponse], error) {
	m := req.Msg
	sess, err := s.M.Create(ctx, agent.CreateOptions{
		WorkingDir: m.WorkingDir, Title: m.Title, Provider: m.Provider, Model: m.Model, Effort: m.Effort, Role: m.Role,
	})
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.CreateSessionResponse{Session: toProto(sess)}), nil
}

// ListSessions implements flitv1connect.SessionServiceHandler. Page tokens
// are opaque to clients.
func (s *Service) ListSessions(ctx context.Context, req *connect.Request[flitv1.ListSessionsRequest]) (*connect.Response[flitv1.ListSessionsResponse], error) {
	size := int(req.Msg.PageSize)
	if size <= 0 {
		size = defaultPageSize
	}
	size = min(size, maxPageSize)
	offset := 0
	if t := req.Msg.PageToken; t != "" {
		n, err := strconv.Atoi(t)
		if err != nil || n < 0 {
			return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("bad page_token"))
		}
		offset = n
	}
	list, err := s.M.List(ctx, size+1, offset)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.ListSessionsResponse{}
	if len(list) > size {
		list = list[:size]
		res.NextPageToken = strconv.Itoa(offset + size)
	}
	for _, sess := range list {
		res.Sessions = append(res.Sessions, toProto(sess))
	}
	return connect.NewResponse(res), nil
}

// GetSession implements flitv1connect.SessionServiceHandler.
func (s *Service) GetSession(ctx context.Context, req *connect.Request[flitv1.GetSessionRequest]) (*connect.Response[flitv1.GetSessionResponse], error) {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return nil, err
	}
	sess, err := s.M.Get(ctx, req.Msg.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.GetSessionResponse{Session: toProto(sess)}), nil
}

// Attach implements flitv1connect.SessionServiceHandler.
func (s *Service) Attach(ctx context.Context, req *connect.Request[flitv1.AttachRequest], stream *connect.ServerStream[flitv1.AttachResponse]) error {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return err
	}
	if _, err := s.M.Get(ctx, req.Msg.SessionId); err != nil {
		return connectErr(err)
	}
	// Send response headers now: the client's Attach call returns only once
	// it has them, and an idle session may have no events for a long time.
	if err := stream.Send(nil); err != nil {
		return err
	}
	err := s.M.Attach(ctx, req.Msg.SessionId, req.Msg.FromSeq, func(ev *flitv1.Event) error {
		return stream.Send(&flitv1.AttachResponse{Event: ev})
	})
	if ctx.Err() != nil {
		return nil // client went away
	}
	return connectErr(err)
}

// Send implements flitv1connect.SessionServiceHandler.
func (s *Service) Send(ctx context.Context, req *connect.Request[flitv1.SendRequest]) (*connect.Response[flitv1.SendResponse], error) {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return nil, err
	}
	seq, err := s.M.Send(ctx, req.Msg.SessionId, req.Msg.Text)
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.SendResponse{Seq: seq}), nil
}

// Interrupt implements flitv1connect.SessionServiceHandler.
func (s *Service) Interrupt(ctx context.Context, req *connect.Request[flitv1.InterruptRequest]) (*connect.Response[flitv1.InterruptResponse], error) {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return nil, err
	}
	ok, err := s.M.Interrupt(ctx, req.Msg.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.InterruptResponse{Interrupted: ok}), nil
}

// AnswerPrompt implements flitv1connect.SessionServiceHandler.
func (s *Service) AnswerPrompt(ctx context.Context, req *connect.Request[flitv1.AnswerPromptRequest]) (*connect.Response[flitv1.AnswerPromptResponse], error) {
	m := req.Msg
	if err := errors.Join(required("session_id", m.SessionId), required("prompt_id", m.PromptId)); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}
	var allow bool
	switch m.Decision {
	case flitv1.PromptDecision_PROMPT_DECISION_ALLOW:
		allow = true
	case flitv1.PromptDecision_PROMPT_DECISION_DENY:
	default:
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("decision must be ALLOW or DENY"))
	}
	client := m.Client
	if client == "" {
		if p, ok := auth.FromContext(ctx); ok {
			client = p.Name
		}
	}
	if err := s.M.AnswerPrompt(ctx, m.SessionId, m.PromptId, allow, client); err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.AnswerPromptResponse{}), nil
}

// SetModel implements flitv1connect.SessionServiceHandler.
func (s *Service) SetModel(ctx context.Context, req *connect.Request[flitv1.SetModelRequest]) (*connect.Response[flitv1.SetModelResponse], error) {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return nil, err
	}
	sess, err := s.M.SetModel(ctx, req.Msg.SessionId, req.Msg.Provider, req.Msg.Model)
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.SetModelResponse{Session: toProto(sess)}), nil
}

// SetEffort implements flitv1connect.SessionServiceHandler.
func (s *Service) SetEffort(ctx context.Context, req *connect.Request[flitv1.SetEffortRequest]) (*connect.Response[flitv1.SetEffortResponse], error) {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return nil, err
	}
	sess, err := s.M.SetEffort(ctx, req.Msg.SessionId, req.Msg.Effort)
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.SetEffortResponse{Session: toProto(sess)}), nil
}
