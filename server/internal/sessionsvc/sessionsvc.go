// Package sessionsvc implements flit.v1.SessionService on top of
// agent.Manager.
package sessionsvc

import (
	"context"
	"errors"
	"strconv"

	"connectrpc.com/connect/v2"
	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/auth"
	"github.com/iggy/flit/server/internal/gitx"
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
		Id:              s.ID,
		TeamId:          s.TeamID,
		ProjectId:       s.ProjectID,
		Title:           s.Title,
		WorkingDir:      s.WorkingDir,
		Provider:        s.Provider,
		Model:           s.Model,
		State:           s.State,
		LastSeq:         s.LastSeq,
		CreateTime:      timestamppb.New(s.CreatedAt),
		UpdateTime:      timestamppb.New(s.UpdatedAt),
		Effort:          s.Effort,
		Role:            s.Role,
		ContextTokens:   s.ContextTokens,
		ContextLength:   s.ContextLength,
		McpServers:      s.MCPServers,
		Yolo:            s.Yolo,
		BranchId:        s.BranchID,
		BaseCommit:      s.BaseCommit,
		SourceDir:       s.SourceDir,
		WorktreePath:    s.WorktreePath,
		WorktreeBranch:  s.WorktreeBranch,
		WorktreeRemoved: s.WorktreeRemoved,
		CronJob:         s.CronID,
		Webhook:         s.WebhookID,
		Archived:        s.Archived,
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
	case errors.Is(err, agent.ErrBusy), errors.Is(err, agent.ErrPromptGone), errors.Is(err, agent.ErrNoCallToRetry), errors.Is(err, agent.ErrQueueGone), errors.Is(err, agent.ErrCantEndReasoning),
		errors.Is(err, agent.ErrQueued), errors.Is(err, agent.ErrNoWorktree), errors.Is(err, agent.ErrWorktreeGone),
		errors.Is(err, agent.ErrWorktreeDirty):
		code = connect.CodeFailedPrecondition
	case errors.Is(err, gitx.ErrNoGit):
		code = connect.CodeFailedPrecondition
	case errors.Is(err, agent.ErrSlowClient):
		code = connect.CodeResourceExhausted
	case errors.Is(err, context.Canceled):
		code = connect.CodeCanceled
	}
	return connect.NewError(code, err.Error())
}

func required(name, v string) error {
	if v == "" {
		return connect.NewError(connect.CodeInvalidArgument, errors.New(name+" is required").Error())
	}
	return nil
}

// CreateSession implements flitv1connect.SessionServiceHandler.
func (s *Service) CreateSession(ctx context.Context, req *flitv1.CreateSessionRequest) (*flitv1.CreateSessionResponse, error) {
	m := req
	sess, err := s.M.Create(ctx, agent.CreateOptions{
		WorkingDir: m.WorkingDir, Title: m.Title, Provider: m.Provider, Model: m.Model, Effort: m.Effort, Role: m.Role,
		ProjectID: m.ProjectId, Yolo: m.Yolo,
	})
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.CreateSessionResponse{Session: toProto(sess)}, nil
}

// ListSessions implements flitv1connect.SessionServiceHandler. Page tokens
// are opaque to clients.
func (s *Service) ListSessions(ctx context.Context, req *flitv1.ListSessionsRequest) (*flitv1.ListSessionsResponse, error) {
	size := int(req.PageSize)
	if size <= 0 {
		size = defaultPageSize
	}
	size = min(size, maxPageSize)
	offset := 0
	if t := req.PageToken; t != "" {
		n, err := strconv.Atoi(t)
		if err != nil || n < 0 {
			return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("bad page_token").Error())
		}
		offset = n
	}
	list, err := s.M.List(ctx, req.ProjectId, req.IncludeArchived, size+1, offset)
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
	return res, nil
}

// GetSession implements flitv1connect.SessionServiceHandler.
func (s *Service) GetSession(ctx context.Context, req *flitv1.GetSessionRequest) (*flitv1.GetSessionResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	sess, err := s.M.Get(ctx, req.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.GetSessionResponse{Session: toProto(sess)}, nil
}

// Attach implements flitv1connect.SessionServiceHandler.
func (s *Service) Attach(ctx context.Context, req *flitv1.AttachRequest, stream flitv1connect.SessionServiceAttachServerStream) error {
	if err := required("session_id", req.SessionId); err != nil {
		return err
	}
	if _, err := s.M.Get(ctx, req.SessionId); err != nil {
		return connectErr(err)
	}
	// Send response headers now: the client's Attach call returns only once
	// it has them, and an idle session may have no events for a long time.
	if err := stream.SendHeaders(); err != nil {
		return err
	}
	err := s.M.Attach(ctx, req.SessionId, req.FromSeq, func(ev *flitv1.Event) error {
		return stream.Send(&flitv1.AttachResponse{Event: ev})
	})
	if ctx.Err() != nil {
		return nil // client went away
	}
	return connectErr(err)
}

// Send implements flitv1connect.SessionServiceHandler.
func (s *Service) Send(ctx context.Context, req *flitv1.SendRequest) (*flitv1.SendResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	res, err := s.M.SendMessage(ctx, req.SessionId, req.Text, req.Client)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.SendResponse{Seq: res.Seq, QueueId: res.QueueID}, nil
}

// EndReasoning implements flitv1connect.SessionServiceHandler.
func (s *Service) EndReasoning(ctx context.Context, req *flitv1.EndReasoningRequest) (*flitv1.EndReasoningResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	if err := s.M.EndReasoning(ctx, req.SessionId, req.Client); err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.EndReasoningResponse{}, nil
}

// Compact implements flitv1connect.SessionServiceHandler.
func (s *Service) Compact(ctx context.Context, req *flitv1.CompactRequest) (*flitv1.CompactResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	queued, err := s.M.Compact(ctx, req.SessionId, req.Client, req.Instructions)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.CompactResponse{Queued: queued}, nil
}

// EditQueuedMessage implements flitv1connect.SessionServiceHandler.
func (s *Service) EditQueuedMessage(ctx context.Context, req *flitv1.EditQueuedMessageRequest) (*flitv1.EditQueuedMessageResponse, error) {
	m := req
	if err := errors.Join(required("session_id", m.SessionId), required("queue_id", m.QueueId)); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err.Error())
	}
	if err := s.M.EditQueuedMessage(ctx, m.SessionId, m.QueueId, m.Text); err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.EditQueuedMessageResponse{}, nil
}

// CancelQueuedMessage implements flitv1connect.SessionServiceHandler.
func (s *Service) CancelQueuedMessage(ctx context.Context, req *flitv1.CancelQueuedMessageRequest) (*flitv1.CancelQueuedMessageResponse, error) {
	m := req
	if err := errors.Join(required("session_id", m.SessionId), required("queue_id", m.QueueId)); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err.Error())
	}
	if err := s.M.CancelQueuedMessage(ctx, m.SessionId, m.QueueId); err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.CancelQueuedMessageResponse{}, nil
}

// Interrupt implements flitv1connect.SessionServiceHandler.
func (s *Service) Interrupt(ctx context.Context, req *flitv1.InterruptRequest) (*flitv1.InterruptResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	ok, err := s.M.Interrupt(ctx, req.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.InterruptResponse{Interrupted: ok}, nil
}

// RetryModelCall implements flitv1connect.SessionServiceHandler.
func (s *Service) RetryModelCall(ctx context.Context, req *flitv1.RetryModelCallRequest) (*flitv1.RetryModelCallResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	if err := s.M.RetryModelCall(ctx, req.SessionId); err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.RetryModelCallResponse{}, nil
}

// SetEffort implements flitv1connect.SessionServiceHandler.
func (s *Service) SetEffort(ctx context.Context, req *flitv1.SetEffortRequest) (*flitv1.SetEffortResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	sess, err := s.M.SetEffort(ctx, req.SessionId, req.Effort)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.SetEffortResponse{Session: toProto(sess)}, nil
}

// SetYolo implements flitv1connect.SessionServiceHandler.
func (s *Service) SetYolo(ctx context.Context, req *flitv1.SetYoloRequest) (*flitv1.SetYoloResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	sess, err := s.M.SetYolo(ctx, req.SessionId, req.Yolo, clientName(ctx))
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.SetYoloResponse{Session: toProto(sess)}, nil
}

func clientName(ctx context.Context) string {
	if p, ok := auth.FromContext(ctx); ok {
		return p.Name
	}
	return ""
}

// MoveSession implements flitv1connect.SessionServiceHandler.
func (s *Service) MoveSession(ctx context.Context, req *flitv1.MoveSessionRequest) (*flitv1.MoveSessionResponse, error) {
	if err := errors.Join(required("session_id", req.SessionId), required("project_id", req.ProjectId)); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err.Error())
	}
	sess, err := s.M.MoveSession(ctx, req.SessionId, req.ProjectId)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.MoveSessionResponse{Session: toProto(sess)}, nil
}

// SwitchBranch implements flitv1connect.SessionServiceHandler.
func (s *Service) SwitchBranch(ctx context.Context, req *flitv1.SwitchBranchRequest) (*flitv1.SwitchBranchResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	sess, err := s.M.SwitchBranch(ctx, req.SessionId, req.BranchId, clientName(ctx))
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.SwitchBranchResponse{Session: toProto(sess)}, nil
}

// SetModel implements flitv1connect.SessionServiceHandler.
func (s *Service) SetModel(ctx context.Context, req *flitv1.SetModelRequest) (*flitv1.SetModelResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	if req.Provider == "" || req.Model == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, "provider and model are required")
	}
	sess, err := s.M.SetModel(ctx, req.SessionId, req.Provider, req.Model)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.SetModelResponse{Session: toProto(sess)}, nil
}

// RetryFromMessage implements flitv1connect.SessionServiceHandler.
func (s *Service) RetryFromMessage(ctx context.Context, req *flitv1.RetryFromMessageRequest) (*flitv1.RetryFromMessageResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	if req.MessageId == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, "message_id is required")
	}
	res, err := s.M.RetryFromMessage(ctx, req.SessionId, req.MessageId, clientName(ctx))
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.RetryFromMessageResponse{BranchId: res.BranchID, Seq: res.Seq}, nil
}

// AnswerPrompt answers a prompt the agent is waiting on. The first answer
// resolves it; later answers fail.
func (s *Service) AnswerPrompt(ctx context.Context, req *flitv1.AnswerPromptRequest) (*flitv1.AnswerPromptResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	if req.PromptId == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, "prompt_id is required")
	}
	a := agent.Answer{Client: req.Client}
	switch req.Decision {
	case flitv1.PromptDecision_PROMPT_DECISION_ALLOW:
		a.Allow = true
	case flitv1.PromptDecision_PROMPT_DECISION_DENY:
		a.Allow = false
	case flitv1.PromptDecision_PROMPT_DECISION_ALLOW_SESSION:
		a.Allow = true
		a.ForSession = true
	default:
		return nil, connect.NewError(connect.CodeInvalidArgument, "decision must be ALLOW, DENY, or ALLOW_SESSION")
	}
	if err := s.M.AnswerPrompt(ctx, req.SessionId, req.PromptId, a); err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.AnswerPromptResponse{}, nil
}

// EditMessage implements flitv1connect.SessionServiceHandler.
func (s *Service) EditMessage(ctx context.Context, req *flitv1.EditMessageRequest) (*flitv1.EditMessageResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	res, err := s.M.EditMessage(ctx, req.SessionId, req.MessageId, req.Text, clientName(ctx))
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.EditMessageResponse{BranchId: res.BranchID, Seq: res.Seq}, nil
}

// Rate implements flitv1connect.SessionServiceHandler.
func (s *Service) Rate(ctx context.Context, req *flitv1.RateRequest) (*flitv1.RateResponse, error) {
	m := req
	if err := required("session_id", m.SessionId); err != nil {
		return nil, err
	}
	if m.Rating == flitv1.Rating_RATING_UNSPECIFIED {
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("rating must be GOOD or BAD").Error())
	}
	err := s.M.Rate(ctx, m.SessionId, agent.Rating{
		Target: m.Target, Good: m.Rating == flitv1.Rating_RATING_GOOD, MessageID: m.MessageId,
		Note: m.Note, Client: clientName(ctx),
	})
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.RateResponse{}, nil
}

// ListMcpServers implements flitv1connect.SessionServiceHandler.
func (s *Service) ListMcpServers(ctx context.Context, req *flitv1.ListMcpServersRequest) (*flitv1.ListMcpServersResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	list, err := s.M.MCPServers(ctx, req.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.ListMcpServersResponse{}
	for _, st := range list {
		res.Servers = append(res.Servers, &flitv1.McpServer{
			Name: st.Name, Enabled: st.Enabled, Running: st.Running, ToolCount: int32(st.ToolCount), Error: st.Err,
		})
	}
	return res, nil
}

// SetMcpServer implements flitv1connect.SessionServiceHandler.
func (s *Service) SetMcpServer(ctx context.Context, req *flitv1.SetMcpServerRequest) (*flitv1.SetMcpServerResponse, error) {
	if err := errors.Join(required("session_id", req.SessionId), required("server", req.Server)); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err.Error())
	}
	sess, err := s.M.SetMCPServer(ctx, req.SessionId, req.Server, req.Enabled)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.SetMcpServerResponse{Session: toProto(sess)}, nil
}

// Projects implements flitv1connect.ProjectServiceHandler.
type Projects struct {
	M *agent.Manager
}

var _ flitv1connect.ProjectServiceHandler = (*Projects)(nil)

func (s *Projects) projectProto(p store.Project) *flitv1.Project {
	return &flitv1.Project{
		Id: p.ID, TeamId: p.TeamID, Name: p.Name, Directory: p.Directory,
		SessionCount: int32(p.SessionCount), CreateTime: timestamppb.New(p.CreatedAt),
		ExportEnabled: p.ExportEnabled, Worktrees: p.Worktrees, WorktreesEnabled: s.M.WorktreesEnabled(p),
	}
}

// ListProjects implements flitv1connect.ProjectServiceHandler.
func (s *Projects) ListProjects(ctx context.Context, _ *flitv1.ListProjectsRequest) (*flitv1.ListProjectsResponse, error) {
	list, err := s.M.Projects(ctx)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.ListProjectsResponse{}
	for _, p := range list {
		res.Projects = append(res.Projects, s.projectProto(p))
	}
	return res, nil
}

// CreateProject implements flitv1connect.ProjectServiceHandler.
func (s *Projects) CreateProject(ctx context.Context, req *flitv1.CreateProjectRequest) (*flitv1.CreateProjectResponse, error) {
	if err := required("directory", req.Directory); err != nil {
		return nil, err
	}
	p, err := s.M.CreateProject(ctx, req.Directory, req.Name)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.CreateProjectResponse{Project: s.projectProto(p)}, nil
}

// SetProjectExport implements flitv1connect.ProjectServiceHandler.
func (s *Projects) SetProjectExport(ctx context.Context, req *flitv1.SetProjectExportRequest) (*flitv1.SetProjectExportResponse, error) {
	if err := required("project_id", req.ProjectId); err != nil {
		return nil, err
	}
	p, err := s.M.SetProjectExport(ctx, req.ProjectId, req.Enabled)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.SetProjectExportResponse{Project: s.projectProto(p)}, nil
}

// SetProjectWorktrees implements flitv1connect.ProjectServiceHandler.
func (s *Projects) SetProjectWorktrees(ctx context.Context, req *flitv1.SetProjectWorktreesRequest) (*flitv1.SetProjectWorktreesResponse, error) {
	if err := required("project_id", req.ProjectId); err != nil {
		return nil, err
	}
	p, err := s.M.SetProjectWorktrees(ctx, req.ProjectId, req.Enabled)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.SetProjectWorktreesResponse{Project: s.projectProto(p)}, nil
}

// ListSkills implements flitv1connect.SessionServiceHandler.
func (s *Service) ListSkills(ctx context.Context, req *flitv1.ListSkillsRequest) (*flitv1.ListSkillsResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	list, err := s.M.Skills(ctx, req.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.ListSkillsResponse{}
	for _, sk := range list {
		res.Skills = append(res.Skills, &flitv1.Skill{Name: sk.Name, Description: sk.Description, Source: sk.Source})
	}
	return res, nil
}

// Diff size limits for GitDiff.
const (
	defaultDiffBytes = 1 << 20
	maxDiffBytes     = 8 << 20
)

var diffBaseKinds = map[gitx.BaseKind]flitv1.GitDiffBase{
	gitx.BaseSession:     flitv1.GitDiffBase_GIT_DIFF_BASE_SESSION_START,
	gitx.BaseHeadNoBase:  flitv1.GitDiffBase_GIT_DIFF_BASE_HEAD_NO_BASE,
	gitx.BaseHeadMissing: flitv1.GitDiffBase_GIT_DIFF_BASE_HEAD_NO_BASE,
	gitx.BaseEmpty:       flitv1.GitDiffBase_GIT_DIFF_BASE_EMPTY_TREE,
}

var fileStatuses = map[gitx.FileStatus]flitv1.GitFileStatus{
	gitx.FileModified:    flitv1.GitFileStatus_GIT_FILE_STATUS_MODIFIED,
	gitx.FileAdded:       flitv1.GitFileStatus_GIT_FILE_STATUS_ADDED,
	gitx.FileDeleted:     flitv1.GitFileStatus_GIT_FILE_STATUS_DELETED,
	gitx.FileRenamed:     flitv1.GitFileStatus_GIT_FILE_STATUS_RENAMED,
	gitx.FileCopied:      flitv1.GitFileStatus_GIT_FILE_STATUS_COPIED,
	gitx.FileTypeChanged: flitv1.GitFileStatus_GIT_FILE_STATUS_TYPE_CHANGED,
	gitx.FileUnmerged:    flitv1.GitFileStatus_GIT_FILE_STATUS_UNMERGED,
}

// GitStatus implements flitv1connect.SessionServiceHandler.
func (s *Service) GitStatus(ctx context.Context, req *flitv1.GitStatusRequest) (*flitv1.GitStatusResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	st, err := s.M.GitStatus(ctx, req.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.GitStatusResponse{IsRepo: st.IsRepo}
	if st.IsRepo {
		res = &flitv1.GitStatusResponse{
			IsRepo: true, Root: st.Root, Branch: st.Branch, Head: st.Head, Detached: st.Detached,
			Upstream: st.Upstream, Ahead: int32(st.Ahead), Behind: int32(st.Behind),
			StagedCount: int32(st.Staged), UnstagedCount: int32(st.Unstaged), UntrackedCount: int32(st.Untracked),
			ConflictedCount: int32(st.Conflicted),
			BaseCommit:      st.BaseCommit, DiffBase: st.Base.Rev, DiffBaseKind: diffBaseKinds[st.Base.Kind],
			FilesTruncated: st.FilesTruncated,
		}
		for _, f := range st.Files {
			res.Files = append(res.Files, &flitv1.GitFileChange{
				Path: f.Path, OldPath: f.OldPath, Status: fileStatuses[f.Status],
				Additions: int32(f.Additions), Deletions: int32(f.Deletions), Binary: f.Binary,
				Staged: f.Staged, Unstaged: f.Unstaged, Untracked: f.Untracked,
			})
		}
	}
	return res, nil
}

// GitDiff implements flitv1connect.SessionServiceHandler.
func (s *Service) GitDiff(ctx context.Context, req *flitv1.GitDiffRequest) (*flitv1.GitDiffResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	limit := int(req.MaxBytes)
	if limit <= 0 {
		limit = defaultDiffBytes
	}
	d, err := s.M.GitDiff(ctx, req.SessionId, req.Path, min(limit, maxDiffBytes))
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.GitDiffResponse{
		IsRepo: d.IsRepo, DiffBase: d.Base.Rev, DiffBaseKind: diffBaseKinds[d.Base.Kind],
		Diff: d.Text, Truncated: d.Truncated,
	}, nil
}

// RemoveWorktree implements flitv1connect.SessionServiceHandler.
func (s *Service) RemoveWorktree(ctx context.Context, req *flitv1.RemoveWorktreeRequest) (*flitv1.RemoveWorktreeResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	r, err := s.M.RemoveWorktree(ctx, req.SessionId)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.RemoveWorktreeResponse{
		Session: toProto(r.Session), BranchKept: r.BranchKept, Commits: int32(r.Commits),
	}, nil
}
