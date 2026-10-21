package store

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"
)

// Proposal statuses.
const (
	ProposalPending  = "pending"
	ProposalAccepted = "accepted"
	ProposalRejected = "rejected"
)

// Proposal is a change the learning pass suggests to a memory file or a
// skill. Nothing is written until it is accepted (see package learn).
type Proposal struct {
	ID        string
	SessionID string
	TeamID    string
	ProjectID string
	CreatedAt time.Time
	// Action is "add", "update" or "remove"; Target is "user", "project",
	// "role" or "skill" (Skill names it).
	Action   string
	Target   string
	Skill    string
	Cue      string
	Lesson   string
	Evidence string
	// OldText is the memory entry or SKILL.md being changed or removed;
	// NewText is what will be written in its place (or added).
	OldText string
	NewText string
	// Path is the file the change goes to.
	Path     string
	Provider string
	Model    string
	Status   string
	// DecidedAt is zero while pending.
	DecidedAt time.Time
}

const proposalCols = `id, session_id, team_id, project_id, created_at, action, target, skill, cue, lesson, evidence,
	old_text, new_text, path, provider, model, status, decided_at`

func scanProposal(row interface{ Scan(...any) error }) (Proposal, error) {
	var p Proposal
	var created int64
	var decided sql.NullInt64
	err := row.Scan(&p.ID, &p.SessionID, &p.TeamID, &p.ProjectID, &created, &p.Action, &p.Target, &p.Skill,
		&p.Cue, &p.Lesson, &p.Evidence, &p.OldText, &p.NewText, &p.Path, &p.Provider, &p.Model, &p.Status, &decided)
	if errors.Is(err, sql.ErrNoRows) {
		return Proposal{}, ErrNotFound
	}
	p.CreatedAt = time.Unix(0, created)
	p.DecidedAt = nullableTime(decided)
	return p, err
}

// ReplacePendingProposals stores list as the session's pending proposals,
// dropping any it had that were never decided.
func (s *Store) ReplacePendingProposals(ctx context.Context, sessionID string, list []Proposal) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.ExecContext(ctx, `DELETE FROM learn_proposals WHERE session_id = ? AND status = ?`, sessionID, ProposalPending); err != nil {
		return err
	}
	for i := range list {
		p := &list[i]
		if p.CreatedAt.IsZero() {
			p.CreatedAt = time.Now()
		}
		p.Status = ProposalPending
		if _, err := tx.ExecContext(ctx, `INSERT INTO learn_proposals (`+proposalCols+`)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)`,
			p.ID, p.SessionID, p.TeamID, p.ProjectID, p.CreatedAt.UnixNano(), p.Action, p.Target, p.Skill,
			p.Cue, p.Lesson, p.Evidence, p.OldText, p.NewText, p.Path, p.Provider, p.Model, p.Status); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// GetProposal returns one proposal.
func (s *Store) GetProposal(ctx context.Context, id string) (Proposal, error) {
	return scanProposal(s.db.QueryRowContext(ctx, `SELECT `+proposalCols+` FROM learn_proposals WHERE id = ?`, id))
}

// ListProposals returns proposals oldest first: the session's (all
// sessions' when sessionID is empty), only pending ones unless all.
func (s *Store) ListProposals(ctx context.Context, sessionID string, all bool) ([]Proposal, error) {
	var where []string
	var args []any
	if sessionID != "" {
		where = append(where, "session_id = ?")
		args = append(args, sessionID)
	}
	if !all {
		where = append(where, "status = ?")
		args = append(args, ProposalPending)
	}
	q := `SELECT ` + proposalCols + ` FROM learn_proposals`
	if len(where) > 0 {
		q += ` WHERE ` + strings.Join(where, " AND ")
	}
	rows, err := s.db.QueryContext(ctx, q+` ORDER BY created_at, id`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Proposal
	for rows.Next() {
		p, err := scanProposal(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

// DecideProposal records a pending proposal's outcome, with the text that
// was written when it was accepted. It returns ErrNotFound if there is no
// pending proposal id.
func (s *Store) DecideProposal(ctx context.Context, id, status, newText string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE learn_proposals SET status = ?, new_text = ?, decided_at = ?
		WHERE id = ? AND status = ?`, status, newText, time.Now().UnixNano(), id, ProposalPending)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}
