package store

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

// ModelCall is one call to a model, with everything needed to reproduce
// it. The request's messages and tool list are stored as content-addressed
// blobs: a conversation re-sends the same messages on every call, so each
// distinct message is stored once.
type ModelCall struct {
	// ID is the id of the assistant message the call produced.
	ID        string
	SessionID string
	TeamID    string
	ProjectID string
	// TurnID is the id of the user message that started the turn. A retry
	// runs the same user message again on a new branch, so a turn is
	// TurnID on BranchID.
	TurnID    string
	BranchID  string
	CreatedAt time.Time
	// Task is the kind of work: "chat" (the agent's own calls),
	// "permission" (a shell command safety check), "compaction",
	// "learning" (see package learn) or "explore"/"build" (a subagent's
	// calls). Empty means chat.
	Task string

	Provider    string
	Model       string
	Effort      string
	FlitVersion string
	Role        string
	Skills      []string

	// Params is the request apart from messages and tools (model,
	// reasoning_effort, ...), as JSON.
	Params json.RawMessage
	// Response is the assistant message produced, as JSON.
	Response     json.RawMessage
	FinishReason string
	Usage        json.RawMessage
	Metrics      json.RawMessage
	// Error is set when the call failed or was interrupted.
	Error string
}

// Rating is a good/bad mark, stored for export alongside the Feedback
// event.
type Rating struct {
	ID          string
	SessionID   string
	TeamID      string
	ProjectID   string
	TurnID      string
	ModelCallID string
	// BranchID is the branch of the rated call (the active branch for a
	// model rating without one).
	BranchID string
	// Target is "turn" or "model".
	Target    string
	Good      bool
	Note      string
	Client    string
	Provider  string
	Model     string
	CreatedAt time.Time
}

func hashOf(data []byte) string {
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}

// RecordModelCall stores a call. messages are the JSON-encoded request
// messages in order; tools is the JSON-encoded tool list (or nil).
func (s *Store) RecordModelCall(ctx context.Context, c *ModelCall, messages [][]byte, tools []byte) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	putBlob := func(data []byte) (string, error) {
		h := hashOf(data)
		_, err := tx.ExecContext(ctx, `INSERT OR IGNORE INTO blobs (hash, data) VALUES (?, ?)`, h, data)
		return h, err
	}
	hashes := make([]string, 0, len(messages))
	for _, m := range messages {
		h, err := putBlob(m)
		if err != nil {
			return err
		}
		hashes = append(hashes, h)
	}
	toolsHash := ""
	if len(tools) > 0 {
		if toolsHash, err = putBlob(tools); err != nil {
			return err
		}
	}
	msgs, _ := json.Marshal(hashes)
	skills, _ := json.Marshal(c.Skills)
	if c.CreatedAt.IsZero() {
		c.CreatedAt = time.Now()
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO model_calls (id, session_id, team_id, project_id, turn_id, created_at,
		provider, model, effort, flit_version, role, skills, request_messages, request_tools, request_params,
		response, finish_reason, usage, metrics, error, task, branch_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		c.ID, c.SessionID, c.TeamID, c.ProjectID, c.TurnID, c.CreatedAt.UnixNano(),
		c.Provider, c.Model, c.Effort, c.FlitVersion, c.Role, string(skills), string(msgs), toolsHash, nullJSON(c.Params),
		nullJSON(c.Response), c.FinishReason, nullJSON(c.Usage), nullJSON(c.Metrics), c.Error, taskOrChat(c.Task), c.BranchID)
	if err != nil {
		return err
	}
	return tx.Commit()
}

func taskOrChat(t string) string {
	if t == "" {
		return "chat"
	}
	return t
}

func nullJSON(b json.RawMessage) string {
	if len(b) == 0 {
		return "null"
	}
	return string(b)
}

// ModelCallRequest returns a stored call's request messages and tools,
// re-assembled from blobs.
func (s *Store) ModelCallRequest(ctx context.Context, id string) (messages []json.RawMessage, tools json.RawMessage, err error) {
	var msgs, toolsHash string
	err = s.db.QueryRowContext(ctx, `SELECT request_messages, request_tools FROM model_calls WHERE id = ?`, id).Scan(&msgs, &toolsHash)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil, ErrNotFound
	}
	if err != nil {
		return nil, nil, err
	}
	var hashes []string
	if err := json.Unmarshal([]byte(msgs), &hashes); err != nil {
		return nil, nil, err
	}
	for _, h := range hashes {
		b, err := s.blob(ctx, h)
		if err != nil {
			return nil, nil, err
		}
		messages = append(messages, b)
	}
	if toolsHash != "" {
		if tools, err = s.blob(ctx, toolsHash); err != nil {
			return nil, nil, err
		}
	}
	return messages, tools, nil
}

func (s *Store) blob(ctx context.Context, hash string) (json.RawMessage, error) {
	var data []byte
	if err := s.db.QueryRowContext(ctx, `SELECT data FROM blobs WHERE hash = ?`, hash).Scan(&data); err != nil {
		return nil, fmt.Errorf("blob %s: %w", hash, err)
	}
	return data, nil
}

// ModelCallTurn returns the turn a model call (assistant message) belongs
// to, or ErrNotFound if no call was recorded for it.
func (s *Store) ModelCallTurn(ctx context.Context, id string) (string, error) {
	var turn string
	err := s.db.QueryRowContext(ctx, `SELECT turn_id FROM model_calls WHERE id = ?`, id).Scan(&turn)
	if errors.Is(err, sql.ErrNoRows) {
		return "", ErrNotFound
	}
	return turn, err
}

// AddRating stores a rating.
func (s *Store) AddRating(ctx context.Context, r *Rating) error {
	if r.CreatedAt.IsZero() {
		r.CreatedAt = time.Now()
	}
	_, err := s.db.ExecContext(ctx, `INSERT INTO ratings (id, session_id, team_id, project_id, turn_id, model_call_id,
		target, good, note, client, provider, model, created_at, branch_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		r.ID, r.SessionID, r.TeamID, r.ProjectID, r.TurnID, r.ModelCallID, r.Target, r.Good, r.Note, r.Client,
		r.Provider, r.Model, r.CreatedAt.UnixNano(), r.BranchID)
	return err
}

// SetProjectExport includes or excludes a project from export.
func (s *Store) SetProjectExport(ctx context.Context, id string, enabled bool) error {
	res, err := s.db.ExecContext(ctx, `UPDATE projects SET export_enabled = ? WHERE id = ?`, enabled, id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// ExportFilter narrows ExportModelCalls.
type ExportFilter struct {
	Since, Until time.Time
	// Project matches a project id or name.
	Project string
	// Model matches "provider/model" or the model id.
	Model string
}

// ExportCall is a model call with what export needs to know about it.
type ExportCall struct {
	ModelCall
	ProjectName string
	WorkingDir  string
}

// ExportModelCalls calls fn for each recorded model call matching f in
// projects that allow export, oldest first.
func (s *Store) ExportModelCalls(ctx context.Context, f ExportFilter, fn func(ExportCall) error) error {
	q := `SELECT c.id, c.session_id, c.team_id, c.project_id, c.turn_id, c.created_at, c.provider, c.model, c.effort,
		c.flit_version, c.role, c.skills, c.request_params, c.response, c.finish_reason, c.usage, c.metrics, c.error,
		c.task, c.branch_id, p.name, s.working_dir
		FROM model_calls c JOIN projects p ON p.id = c.project_id JOIN sessions s ON s.id = c.session_id
		WHERE p.export_enabled = 1`
	var args []any
	if !f.Since.IsZero() {
		q += ` AND c.created_at >= ?`
		args = append(args, f.Since.UnixNano())
	}
	if !f.Until.IsZero() {
		q += ` AND c.created_at < ?`
		args = append(args, f.Until.UnixNano())
	}
	if f.Project != "" {
		q += ` AND (p.id = ? OR p.name = ?)`
		args = append(args, f.Project, f.Project)
	}
	if f.Model != "" {
		q += ` AND (c.model = ? OR c.provider || '/' || c.model = ?)`
		args = append(args, f.Model, f.Model)
	}
	q += ` ORDER BY c.created_at, c.id`
	rows, err := s.db.QueryContext(ctx, q, args...)
	if err != nil {
		return err
	}
	var calls []ExportCall
	for rows.Next() {
		var c ExportCall
		var created int64
		var skills, params, response, usage, metrics string
		if err := rows.Scan(&c.ID, &c.SessionID, &c.TeamID, &c.ProjectID, &c.TurnID, &created, &c.Provider, &c.Model,
			&c.Effort, &c.FlitVersion, &c.Role, &skills, &params, &response, &c.FinishReason, &usage, &metrics, &c.Error,
			&c.Task, &c.BranchID, &c.ProjectName, &c.WorkingDir); err != nil {
			rows.Close()
			return err
		}
		c.CreatedAt = time.Unix(0, created)
		_ = json.Unmarshal([]byte(skills), &c.Skills)
		c.Params, c.Response, c.Usage, c.Metrics = json.RawMessage(params), json.RawMessage(response), json.RawMessage(usage), json.RawMessage(metrics)
		calls = append(calls, c)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return err
	}
	for _, c := range calls {
		if err := fn(c); err != nil {
			return err
		}
	}
	return nil
}

// RatingsFor returns the ratings of the given sessions, oldest first.
func (s *Store) RatingsFor(ctx context.Context, sessionIDs []string) ([]Rating, error) {
	if len(sessionIDs) == 0 {
		return nil, nil
	}
	q := `SELECT id, session_id, team_id, project_id, turn_id, model_call_id, target, good, note, client, provider, model, created_at, branch_id
		FROM ratings WHERE session_id IN (?` + strings.Repeat(",?", len(sessionIDs)-1) + `) ORDER BY created_at, id`
	args := make([]any, len(sessionIDs))
	for i, id := range sessionIDs {
		args[i] = id
	}
	rows, err := s.db.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Rating
	for rows.Next() {
		var r Rating
		var created int64
		if err := rows.Scan(&r.ID, &r.SessionID, &r.TeamID, &r.ProjectID, &r.TurnID, &r.ModelCallID, &r.Target, &r.Good,
			&r.Note, &r.Client, &r.Provider, &r.Model, &created, &r.BranchID); err != nil {
			return nil, err
		}
		r.CreatedAt = time.Unix(0, created)
		out = append(out, r)
	}
	return out, rows.Err()
}
