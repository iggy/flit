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
		McpServers:    s.MCPServers,
		Yolo:          s.Yolo,
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
		ProjectID: m.ProjectId, Yolo: m.Yolo,
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
	list, err := s.M.List(ctx, req.Msg.ProjectId, size+1, offset)
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
	var answer agent.Answer
	switch m.Decision {
	case flitv1.PromptDecision_PROMPT_DECISION_ALLOW:
		answer.Allow = true
	case flitv1.PromptDecision_PROMPT_DECISION_ALLOW_SESSION:
		answer.ForSession = true
	case flitv1.PromptDecision_PROMPT_DECISION_DENY:
	default:
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("decision must be ALLOW, ALLOW_SESSION or DENY"))
	}
	client := m.Client
	if client == "" {
		client = clientName(ctx)
	}
	answer.Client = client
	if err := s.M.AnswerPrompt(ctx, m.SessionId, m.PromptId, answer); err != nil {
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

// SetYolo implements flitv1connect.SessionServiceHandler.
func (s *Service) SetYolo(ctx context.Context, req *connect.Request[flitv1.SetYoloRequest]) (*connect.Response[flitv1.SetYoloResponse], error) {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return nil, err
	}
	sess, err := s.M.SetYolo(ctx, req.Msg.SessionId, req.Msg.Yolo, clientName(ctx))
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.SetYoloResponse{Session: toProto(sess)}), nil
}

func clientName(ctx context.Context) string {
	if p, ok := auth.FromContext(ctx); ok {
		return p.Name
	}
	return ""
}

// MoveSession implements flitv1connect.SessionServiceHandler.
func (s *Service) MoveSession(ctx context.Context, req *connect.Request[flitv1.MoveSessionRequest]) (*connect.Response[flitv1.MoveSessionResponse], error) {
	if err := errors.Join(required("session_id", req.Msg.SessionId), required("project_id", req.Msg.ProjectId)); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}
	sess, err := s.M.MoveSession(ctx, req.Msg.SessionId, req.Msg.ProjectId)
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.MoveSessionResponse{Session: toProto(sess)}), nil
}

// Rate implements flitv1connect.SessionServiceHandler.
func (s *Service) Rate(ctx context.Context, req *connect.Request[flitv1.RateRequest]) (*connect.Response[flitv1.RateResponse], error) {
	m := req.Msg
	if err := required("session_id", m.SessionId); err != nil {
		return nil, err
	}
	if m.Rating == flitv1.Rating_RATING_UNSPECIFIED {
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("rating must be GOOD or BAD"))
	}
	err := s.M.Rate(ctx, m.SessionId, agent.Rating{
		Target: m.Target, Good: m.Rating == flitv1.Rating_RATING_GOOD, MessageID: m.MessageId,
		Note: m.Note, Client: clientName(ctx),
	})
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.RateResponse{}), nil
}

// ListMcpServers implements flitv1connect.SessionServiceHandler.
func (s *Service) ListMcpServers(ctx context.Context, req *connect.Request[flitv1.ListMcpServersRequest]) (*connect.Response[flitv1.ListMcpServersResponse], error) {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return nil, err
	}
	list, err := s.M.MCPServers(ctx, req.Msg.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.ListMcpServersResponse{}
	for _, st := range list {
		res.Servers = append(res.Servers, &flitv1.McpServer{
			Name: st.Name, Enabled: st.Enabled, Running: st.Running, ToolCount: int32(st.ToolCount), Error: st.Err,
		})
	}
	return connect.NewResponse(res), nil
}

// SetMcpServer implements flitv1connect.SessionServiceHandler.
func (s *Service) SetMcpServer(ctx context.Context, req *connect.Request[flitv1.SetMcpServerRequest]) (*connect.Response[flitv1.SetMcpServerResponse], error) {
	if err := errors.Join(required("session_id", req.Msg.SessionId), required("server", req.Msg.Server)); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}
	sess, err := s.M.SetMCPServer(ctx, req.Msg.SessionId, req.Msg.Server, req.Msg.Enabled)
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.SetMcpServerResponse{Session: toProto(sess)}), nil
}

// Projects implements flitv1connect.ProjectServiceHandler.
type Projects struct {
	M *agent.Manager
}

var _ flitv1connect.ProjectServiceHandler = (*Projects)(nil)

func projectProto(p store.Project) *flitv1.Project {
	return &flitv1.Project{
		Id: p.ID, TeamId: p.TeamID, Name: p.Name, Directory: p.Directory,
		SessionCount: int32(p.SessionCount), CreateTime: timestamppb.New(p.CreatedAt),
		ExportEnabled: p.ExportEnabled,
	}
}

// ListProjects implements flitv1connect.ProjectServiceHandler.
func (s *Projects) ListProjects(ctx context.Context, _ *connect.Request[flitv1.ListProjectsRequest]) (*connect.Response[flitv1.ListProjectsResponse], error) {
	list, err := s.M.Projects(ctx)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.ListProjectsResponse{}
	for _, p := range list {
		res.Projects = append(res.Projects, projectProto(p))
	}
	return connect.NewResponse(res), nil
}

// CreateProject implements flitv1connect.ProjectServiceHandler.
func (s *Projects) CreateProject(ctx context.Context, req *connect.Request[flitv1.CreateProjectRequest]) (*connect.Response[flitv1.CreateProjectResponse], error) {
	if err := required("directory", req.Msg.Directory); err != nil {
		return nil, err
	}
	p, err := s.M.CreateProject(ctx, req.Msg.Directory, req.Msg.Name)
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.CreateProjectResponse{Project: projectProto(p)}), nil
}

// SetProjectExport implements flitv1connect.ProjectServiceHandler.
func (s *Projects) SetProjectExport(ctx context.Context, req *connect.Request[flitv1.SetProjectExportRequest]) (*connect.Response[flitv1.SetProjectExportResponse], error) {
	if err := required("project_id", req.Msg.ProjectId); err != nil {
		return nil, err
	}
	p, err := s.M.SetProjectExport(ctx, req.Msg.ProjectId, req.Msg.Enabled)
	if err != nil {
		return nil, connectErr(err)
	}
	return connect.NewResponse(&flitv1.SetProjectExportResponse{Project: projectProto(p)}), nil
}

// ListSkills implements flitv1connect.SessionServiceHandler.
func (s *Service) ListSkills(ctx context.Context, req *connect.Request[flitv1.ListSkillsRequest]) (*connect.Response[flitv1.ListSkillsResponse], error) {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return nil, err
	}
	list, err := s.M.Skills(ctx, req.Msg.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.ListSkillsResponse{}
	for _, sk := range list {
		res.Skills = append(res.Skills, &flitv1.Skill{Name: sk.Name, Description: sk.Description, Source: sk.Source})
	}
	return connect.NewResponse(res), nil
}
