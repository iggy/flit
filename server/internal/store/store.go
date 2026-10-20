// Package store keeps flit's state in SQLite (pure Go, no cgo): teams,
// projects, sessions and each session's append-only event log.
package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"time"

	"google.golang.org/protobuf/proto"
	_ "modernc.org/sqlite" // registers the "sqlite" driver

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
)

// FileName is the database's file name inside the data dir.
const FileName = "flit.db"

// The default team and project. Every session belongs to them until teams
// and projects can be managed.
const (
	DefaultTeamID      = "team_personal"
	DefaultTeamName    = "Personal"
	DefaultProjectID   = "proj_scratch"
	DefaultProjectName = "Scratch"
)

// ErrNotFound is returned when a session doesn't exist.
var ErrNotFound = errors.New("not found")

// Store is flit's database.
type Store struct {
	db *sql.DB
}

// Open opens (creating if needed) the database at path and migrates it to
// the current schema.
func Open(ctx context.Context, path string) (*Store, error) {
	q := url.Values{}
	for _, p := range []string{"journal_mode(WAL)", "synchronous(NORMAL)", "foreign_keys(1)", "busy_timeout(5000)"} {
		q.Add("_pragma", p)
	}
	db, err := sql.Open("sqlite", path+"?"+q.Encode())
	if err != nil {
		return nil, err
	}
	s := &Store{db: db}
	if err := s.migrate(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("migrate %s: %w", path, err)
	}
	return s, nil
}

// Close closes the database.
func (s *Store) Close() error { return s.db.Close() }

// migrations are applied in order; PRAGMA user_version records how many ran.
// Only ever append to this list.
var migrations = []string{
	`
CREATE TABLE teams (
	id         TEXT PRIMARY KEY,
	name       TEXT NOT NULL,
	created_at INTEGER NOT NULL
);
CREATE TABLE projects (
	id         TEXT PRIMARY KEY,
	team_id    TEXT NOT NULL REFERENCES teams(id),
	name       TEXT NOT NULL,
	created_at INTEGER NOT NULL
);
CREATE TABLE sessions (
	id          TEXT PRIMARY KEY,
	team_id     TEXT NOT NULL REFERENCES teams(id),
	project_id  TEXT NOT NULL REFERENCES projects(id),
	title       TEXT NOT NULL,
	working_dir TEXT NOT NULL,
	provider    TEXT NOT NULL,
	model       TEXT NOT NULL,
	state       INTEGER NOT NULL,
	last_seq    INTEGER NOT NULL DEFAULT 0,
	created_at  INTEGER NOT NULL,
	updated_at  INTEGER NOT NULL
);
CREATE INDEX sessions_by_project ON sessions (team_id, project_id, updated_at);
CREATE INDEX sessions_by_updated ON sessions (updated_at);
CREATE INDEX sessions_by_state ON sessions (state);
CREATE TABLE events (
	session_id TEXT NOT NULL REFERENCES sessions(id),
	seq        INTEGER NOT NULL,
	team_id    TEXT NOT NULL,
	project_id TEXT NOT NULL,
	kind       TEXT NOT NULL,
	created_at INTEGER NOT NULL,
	payload    BLOB NOT NULL,
	PRIMARY KEY (session_id, seq)
) WITHOUT ROWID;
CREATE INDEX events_by_kind ON events (session_id, kind, seq);
`,
	`
CREATE TABLE devices (
	id           TEXT PRIMARY KEY,
	name         TEXT NOT NULL,
	token_hash   BLOB NOT NULL UNIQUE,
	created_at   INTEGER NOT NULL,
	last_seen_at INTEGER,
	revoked_at   INTEGER
);
`,
	`
ALTER TABLE sessions ADD COLUMN effort TEXT NOT NULL DEFAULT '';
ALTER TABLE sessions ADD COLUMN role TEXT NOT NULL DEFAULT '';
ALTER TABLE sessions ADD COLUMN context_tokens INTEGER NOT NULL DEFAULT 0;
ALTER TABLE sessions ADD COLUMN context_length INTEGER NOT NULL DEFAULT 0;
`,
	`
ALTER TABLE projects ADD COLUMN directory TEXT NOT NULL DEFAULT '';
ALTER TABLE sessions ADD COLUMN mcp_servers TEXT NOT NULL DEFAULT '';
CREATE UNIQUE INDEX projects_by_directory ON projects (team_id, directory) WHERE directory != '';
`,
	`
ALTER TABLE projects ADD COLUMN export_enabled INTEGER NOT NULL DEFAULT 1;
CREATE TABLE blobs (
	hash TEXT PRIMARY KEY,
	data BLOB NOT NULL
) WITHOUT ROWID;
CREATE TABLE model_calls (
	id               TEXT PRIMARY KEY,
	session_id       TEXT NOT NULL REFERENCES sessions(id),
	team_id          TEXT NOT NULL,
	project_id       TEXT NOT NULL,
	turn_id          TEXT NOT NULL,
	created_at       INTEGER NOT NULL,
	provider         TEXT NOT NULL,
	model            TEXT NOT NULL,
	effort           TEXT NOT NULL,
	flit_version     TEXT NOT NULL,
	role             TEXT NOT NULL,
	skills           TEXT NOT NULL,
	request_messages TEXT NOT NULL,
	request_tools    TEXT NOT NULL,
	request_params   TEXT NOT NULL,
	response         TEXT NOT NULL,
	finish_reason    TEXT NOT NULL,
	usage            TEXT NOT NULL,
	metrics          TEXT NOT NULL,
	error            TEXT NOT NULL
);
CREATE INDEX model_calls_by_session ON model_calls (session_id, created_at);
CREATE INDEX model_calls_by_time ON model_calls (created_at);
CREATE TABLE ratings (
	id            TEXT PRIMARY KEY,
	session_id    TEXT NOT NULL REFERENCES sessions(id),
	team_id       TEXT NOT NULL,
	project_id    TEXT NOT NULL,
	turn_id       TEXT NOT NULL,
	model_call_id TEXT NOT NULL,
	target        TEXT NOT NULL,
	good          INTEGER NOT NULL,
	note          TEXT NOT NULL,
	client        TEXT NOT NULL,
	provider      TEXT NOT NULL,
	model         TEXT NOT NULL,
	created_at    INTEGER NOT NULL
);
CREATE INDEX ratings_by_session ON ratings (session_id, created_at);
`,
	`
ALTER TABLE sessions ADD COLUMN yolo INTEGER NOT NULL DEFAULT 0;
ALTER TABLE model_calls ADD COLUMN task TEXT NOT NULL DEFAULT 'chat';
`,
	`
CREATE TABLE model_prefs (
	team_id   TEXT NOT NULL,
	provider  TEXT NOT NULL,
	model     TEXT NOT NULL,
	favorite  INTEGER NOT NULL DEFAULT 0,
	last_used INTEGER,
	PRIMARY KEY (team_id, provider, model)
) WITHOUT ROWID;
`,
	`
ALTER TABLE model_prefs ADD COLUMN no_reasoning_end INTEGER NOT NULL DEFAULT 0;
`,
	`
ALTER TABLE sessions ADD COLUMN branch_id TEXT NOT NULL DEFAULT '';
ALTER TABLE model_calls ADD COLUMN branch_id TEXT NOT NULL DEFAULT '';
ALTER TABLE ratings ADD COLUMN branch_id TEXT NOT NULL DEFAULT '';
`,
}

func (s *Store) migrate(ctx context.Context) error {
	var version int
	if err := s.db.QueryRowContext(ctx, `PRAGMA user_version`).Scan(&version); err != nil {
		return err
	}
	for i := version; i < len(migrations); i++ {
		tx, err := s.db.BeginTx(ctx, nil)
		if err != nil {
			return err
		}
		if _, err := tx.ExecContext(ctx, migrations[i]); err != nil {
			tx.Rollback()
			return fmt.Errorf("migration %d: %w", i+1, err)
		}
		if _, err := tx.ExecContext(ctx, fmt.Sprintf(`PRAGMA user_version = %d`, i+1)); err != nil {
			tx.Rollback()
			return err
		}
		if err := tx.Commit(); err != nil {
			return err
		}
	}
	now := time.Now().UnixNano()
	if _, err := s.db.ExecContext(ctx, `INSERT OR IGNORE INTO teams (id, name, created_at) VALUES (?, ?, ?)`,
		DefaultTeamID, DefaultTeamName, now); err != nil {
		return err
	}
	_, err := s.db.ExecContext(ctx, `INSERT OR IGNORE INTO projects (id, team_id, name, created_at) VALUES (?, ?, ?, ?)`,
		DefaultProjectID, DefaultTeamID, DefaultProjectName, now)
	return err
}

// Session is a stored session.
type Session struct {
	ID         string
	TeamID     string
	ProjectID  string
	Title      string
	WorkingDir string
	Provider   string
	Model      string
	State      flitv1.TaskState
	LastSeq    int64
	CreatedAt  time.Time
	UpdatedAt  time.Time
	Effort     string
	Role       string
	// Context use after the last model call, and the model's window.
	ContextTokens int64
	ContextLength int64
	// MCPServers are the MCP servers enabled for the session.
	MCPServers []string
	// Yolo runs every shell command no deny rule matches.
	Yolo bool
	// BranchID is the active branch (see package branches); empty is the
	// root.
	BranchID string
}

const sessionCols = `id, team_id, project_id, title, working_dir, provider, model, state, last_seq, created_at, updated_at, effort, role, context_tokens, context_length, mcp_servers, yolo, branch_id`

func joinNames(names []string) string { return strings.Join(names, "\n") }

func splitNames(s string) []string {
	if s == "" {
		return nil
	}
	return strings.Split(s, "\n")
}

func scanSession(row interface{ Scan(...any) error }) (Session, error) {
	var s Session
	var created, updated int64
	var mcp string
	err := row.Scan(&s.ID, &s.TeamID, &s.ProjectID, &s.Title, &s.WorkingDir, &s.Provider, &s.Model,
		&s.State, &s.LastSeq, &created, &updated, &s.Effort, &s.Role, &s.ContextTokens, &s.ContextLength, &mcp, &s.Yolo, &s.BranchID)
	s.MCPServers = splitNames(mcp)
	if errors.Is(err, sql.ErrNoRows) {
		return Session{}, ErrNotFound
	}
	s.CreatedAt, s.UpdatedAt = time.Unix(0, created), time.Unix(0, updated)
	return s, err
}

// CreateSession stores a new session. CreatedAt and UpdatedAt are set to now.
func (s *Store) CreateSession(ctx context.Context, sess *Session) error {
	now := time.Now()
	sess.CreatedAt, sess.UpdatedAt = now, now
	_, err := s.db.ExecContext(ctx, `INSERT INTO sessions (`+sessionCols+`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		sess.ID, sess.TeamID, sess.ProjectID, sess.Title, sess.WorkingDir, sess.Provider, sess.Model,
		sess.State, sess.LastSeq, now.UnixNano(), now.UnixNano(), sess.Effort, sess.Role, sess.ContextTokens, sess.ContextLength,
		joinNames(sess.MCPServers), sess.Yolo, sess.BranchID)
	return err
}

// GetSession returns the session with the given id, or ErrNotFound.
func (s *Store) GetSession(ctx context.Context, id string) (Session, error) {
	return scanSession(s.db.QueryRowContext(ctx, `SELECT `+sessionCols+` FROM sessions WHERE id = ?`, id))
}

// ListSessions returns up to limit sessions, most recently updated first,
// skipping the first offset; only those in projectID unless it is empty.
func (s *Store) ListSessions(ctx context.Context, projectID string, limit, offset int) ([]Session, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT `+sessionCols+` FROM sessions WHERE ? = '' OR project_id = ? ORDER BY updated_at DESC, id LIMIT ? OFFSET ?`,
		projectID, projectID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Session
	for rows.Next() {
		sess, err := scanSession(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, sess)
	}
	return out, rows.Err()
}

// SetModel changes a session's provider and model.
func (s *Store) SetModel(ctx context.Context, id, provider, model string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE sessions SET provider = ?, model = ?, updated_at = ? WHERE id = ?`,
		provider, model, time.Now().UnixNano(), id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// MoveSession moves a session to another project.
func (s *Store) MoveSession(ctx context.Context, id, projectID string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE sessions SET project_id = ? WHERE id = ?`, projectID, id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// SetMCPServers changes which MCP servers are enabled for a session.
func (s *Store) SetMCPServers(ctx context.Context, id string, names []string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE sessions SET mcp_servers = ? WHERE id = ?`, joinNames(names), id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// Project is a group of sessions, usually for one directory.
type Project struct {
	ID            string
	TeamID        string
	Name          string
	Directory     string
	CreatedAt     time.Time
	SessionCount  int
	ExportEnabled bool
}

// ErrExists is returned when creating something that already exists.
var ErrExists = errors.New("already exists")

// CreateProject stores a new project. A team can't have two projects for
// the same directory.
func (s *Store) CreateProject(ctx context.Context, p *Project) error {
	p.CreatedAt = time.Now()
	_, err := s.db.ExecContext(ctx, `INSERT INTO projects (id, team_id, name, directory, created_at) VALUES (?, ?, ?, ?, ?)`,
		p.ID, p.TeamID, p.Name, p.Directory, p.CreatedAt.UnixNano())
	if err != nil && strings.Contains(err.Error(), "UNIQUE") {
		return fmt.Errorf("%w: a project for %s", ErrExists, p.Directory)
	}
	return err
}

const projectQuery = `SELECT p.id, p.team_id, p.name, p.directory, p.created_at,
	(SELECT count(*) FROM sessions s WHERE s.project_id = p.id), p.export_enabled FROM projects p`

func scanProject(row interface{ Scan(...any) error }) (Project, error) {
	var p Project
	var created int64
	err := row.Scan(&p.ID, &p.TeamID, &p.Name, &p.Directory, &created, &p.SessionCount, &p.ExportEnabled)
	if errors.Is(err, sql.ErrNoRows) {
		return Project{}, ErrNotFound
	}
	p.CreatedAt = time.Unix(0, created)
	return p, err
}

// GetProject returns one project.
func (s *Store) GetProject(ctx context.Context, id string) (Project, error) {
	return scanProject(s.db.QueryRowContext(ctx, projectQuery+` WHERE p.id = ?`, id))
}

// ListProjects returns a team's projects: Scratch first, then by name.
func (s *Store) ListProjects(ctx context.Context, teamID string) ([]Project, error) {
	rows, err := s.db.QueryContext(ctx, projectQuery+` WHERE p.team_id = ? ORDER BY p.id != ?, lower(p.name), p.id`,
		teamID, DefaultProjectID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Project
	for rows.Next() {
		p, err := scanProject(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

// SetEffort changes a session's reasoning effort.
func (s *Store) SetEffort(ctx context.Context, id, effort string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE sessions SET effort = ?, updated_at = ? WHERE id = ?`,
		effort, time.Now().UnixNano(), id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// SetYolo turns a session's yolo mode on or off.
func (s *Store) SetYolo(ctx context.Context, id string, yolo bool) error {
	res, err := s.db.ExecContext(ctx, `UPDATE sessions SET yolo = ?, updated_at = ? WHERE id = ?`,
		yolo, time.Now().UnixNano(), id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// SetTitle changes a session's title.
func (s *Store) SetTitle(ctx context.Context, id, title string) error {
	_, err := s.db.ExecContext(ctx, `UPDATE sessions SET title = ? WHERE id = ?`, title, id)
	return err
}

// SessionIDsInStates returns the ids of sessions in any of the given states.
func (s *Store) SessionIDsInStates(ctx context.Context, states ...flitv1.TaskState) ([]string, error) {
	var ids []string
	for _, st := range states {
		rows, err := s.db.QueryContext(ctx, `SELECT id FROM sessions WHERE state = ?`, st)
		if err != nil {
			return nil, err
		}
		for rows.Next() {
			var id string
			if err := rows.Scan(&id); err != nil {
				rows.Close()
				return nil, err
			}
			ids = append(ids, id)
		}
		rows.Close()
		if err := rows.Err(); err != nil {
			return nil, err
		}
	}
	return ids, nil
}

// AppendEvent stores ev, which must carry the session's next sequence
// number, and advances the session's last_seq in the same transaction,
// along with what the event changes: state (TaskStateChanged), context use
// (Usage), context window (ModelChanged) or active branch (BranchSwitched).
func (s *Store) AppendEvent(ctx context.Context, sess Session, ev *flitv1.Event) error {
	payload, err := proto.Marshal(ev)
	if err != nil {
		return err
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	at := ev.GetTime().AsTime().UnixNano()
	if _, err := tx.ExecContext(ctx, `INSERT INTO events (session_id, seq, team_id, project_id, kind, created_at, payload) VALUES (?, ?, ?, ?, ?, ?, ?)`,
		ev.SessionId, ev.Seq, sess.TeamID, sess.ProjectID, Kind(ev), at, payload); err != nil {
		return err
	}
	q := `UPDATE sessions SET last_seq = ?, updated_at = ? WHERE id = ? AND last_seq = ?`
	args := []any{ev.Seq, at, ev.SessionId, ev.Seq - 1}
	switch {
	case ev.GetTaskStateChanged() != nil:
		q = `UPDATE sessions SET last_seq = ?, updated_at = ?, state = ? WHERE id = ? AND last_seq = ?`
		args = []any{ev.Seq, at, ev.GetTaskStateChanged().State, ev.SessionId, ev.Seq - 1}
	case ev.GetUsage() != nil:
		u := ev.GetUsage()
		q = `UPDATE sessions SET last_seq = ?, updated_at = ?, context_tokens = ?, context_length = ? WHERE id = ? AND last_seq = ?`
		args = []any{ev.Seq, at, u.InputTokens + u.OutputTokens, u.ContextLength, ev.SessionId, ev.Seq - 1}
	case ev.GetModelChanged() != nil:
		q = `UPDATE sessions SET last_seq = ?, updated_at = ?, context_length = ? WHERE id = ? AND last_seq = ?`
		args = []any{ev.Seq, at, ev.GetModelChanged().ContextLength, ev.SessionId, ev.Seq - 1}
	case ev.GetCompactionDone() != nil && ev.GetCompactionDone().Error == "":
		q = `UPDATE sessions SET last_seq = ?, updated_at = ?, context_tokens = ? WHERE id = ? AND last_seq = ?`
		args = []any{ev.Seq, at, ev.GetCompactionDone().TokensAfter, ev.SessionId, ev.Seq - 1}
	case ev.GetBranchSwitched() != nil:
		q = `UPDATE sessions SET last_seq = ?, updated_at = ?, branch_id = ? WHERE id = ? AND last_seq = ?`
		args = []any{ev.Seq, at, ev.GetBranchSwitched().BranchId, ev.SessionId, ev.Seq - 1}
	}
	res, err := tx.ExecContext(ctx, q, args...)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n != 1 {
		return fmt.Errorf("append event %d to session %s: sequence out of order", ev.Seq, ev.SessionId)
	}
	return tx.Commit()
}

// Events returns a session's events with fromSeq <= seq <= toSeq, in order.
func (s *Store) Events(ctx context.Context, sessionID string, fromSeq, toSeq int64) ([]*flitv1.Event, error) {
	return s.queryEvents(ctx, `SELECT payload FROM events WHERE session_id = ? AND seq >= ? AND seq <= ? ORDER BY seq`,
		sessionID, fromSeq, toSeq)
}

// EventsOfKinds returns all of a session's events of the given kinds (see
// Kind), in order.
func (s *Store) EventsOfKinds(ctx context.Context, sessionID string, kinds ...string) ([]*flitv1.Event, error) {
	q := `SELECT payload FROM events WHERE session_id = ? AND kind IN (?` + strings.Repeat(",?", len(kinds)-1) + `) ORDER BY seq`
	args := []any{sessionID}
	for _, k := range kinds {
		args = append(args, k)
	}
	return s.queryEvents(ctx, q, args...)
}

func (s *Store) queryEvents(ctx context.Context, q string, args ...any) ([]*flitv1.Event, error) {
	rows, err := s.db.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*flitv1.Event
	for rows.Next() {
		var payload []byte
		if err := rows.Scan(&payload); err != nil {
			return nil, err
		}
		ev := new(flitv1.Event)
		if err := proto.Unmarshal(payload, ev); err != nil {
			return nil, err
		}
		out = append(out, ev)
	}
	return out, rows.Err()
}

// Kind names an event's payload type, e.g. "text_delta".
func Kind(ev *flitv1.Event) string {
	if f := ev.ProtoReflect().WhichOneof(ev.ProtoReflect().Descriptor().Oneofs().ByName("payload")); f != nil {
		return string(f.Name())
	}
	return "unknown"
}

// Device is a paired client. Its token is stored only as a hash.
type Device struct {
	ID         string
	Name       string
	TokenHash  []byte
	CreatedAt  time.Time
	LastSeenAt time.Time // zero if never
	RevokedAt  time.Time // zero if not revoked
}

func nullableTime(ns sql.NullInt64) time.Time {
	if !ns.Valid {
		return time.Time{}
	}
	return time.Unix(0, ns.Int64)
}

const deviceCols = `id, name, token_hash, created_at, last_seen_at, revoked_at`

func scanDevice(row interface{ Scan(...any) error }) (Device, error) {
	var d Device
	var created int64
	var seen, revoked sql.NullInt64
	err := row.Scan(&d.ID, &d.Name, &d.TokenHash, &created, &seen, &revoked)
	if errors.Is(err, sql.ErrNoRows) {
		return Device{}, ErrNotFound
	}
	d.CreatedAt, d.LastSeenAt, d.RevokedAt = time.Unix(0, created), nullableTime(seen), nullableTime(revoked)
	return d, err
}

// CreateDevice stores a new device. CreatedAt is set to now.
func (s *Store) CreateDevice(ctx context.Context, d *Device) error {
	d.CreatedAt = time.Now()
	_, err := s.db.ExecContext(ctx, `INSERT INTO devices (id, name, token_hash, created_at) VALUES (?, ?, ?, ?)`,
		d.ID, d.Name, d.TokenHash, d.CreatedAt.UnixNano())
	return err
}

// DeviceByTokenHash returns the non-revoked device with the given token
// hash, or ErrNotFound.
func (s *Store) DeviceByTokenHash(ctx context.Context, hash []byte) (Device, error) {
	return scanDevice(s.db.QueryRowContext(ctx, `SELECT `+deviceCols+` FROM devices WHERE token_hash = ? AND revoked_at IS NULL`, hash))
}

// ListDevices returns devices, oldest first.
func (s *Store) ListDevices(ctx context.Context, includeRevoked bool) ([]Device, error) {
	q := `SELECT ` + deviceCols + ` FROM devices`
	if !includeRevoked {
		q += ` WHERE revoked_at IS NULL`
	}
	rows, err := s.db.QueryContext(ctx, q+` ORDER BY created_at`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Device
	for rows.Next() {
		d, err := scanDevice(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, d)
	}
	return out, rows.Err()
}

// RevokeDevice revokes a device. Revoking twice is not an error;
// an unknown id is ErrNotFound.
func (s *Store) RevokeDevice(ctx context.Context, id string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE devices SET revoked_at = coalesce(revoked_at, ?) WHERE id = ?`, time.Now().UnixNano(), id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// TouchDevice records that a device was just seen.
func (s *Store) TouchDevice(ctx context.Context, id string, at time.Time) error {
	_, err := s.db.ExecContext(ctx, `UPDATE devices SET last_seen_at = ? WHERE id = ?`, at.UnixNano(), id)
	return err
}
