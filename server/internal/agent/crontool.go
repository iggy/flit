package agent

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/iggy/flit/server/internal/cron"
	"github.com/iggy/flit/server/internal/tools"
)

const cronToolDescription = `Manage flit's cron jobs: prompts flit runs on a schedule, unattended, each run as a new session.
Actions: list (jobs with schedule, next run, last result), create, edit (change only the fields given), remove, run (start a run now).
Creating, editing and removing always ask the user first.
schedule must be one of these forms; translate what the user says into one:
- "every 30m", "every 2h", "every minute", "every hour" (counted from midnight)
- "daily at 9:00", "weekdays at 8:30", "weekends at 10", "mondays at 10", "mon, wed and fri at 17:30", "daily at 7pm"
- one-shot: "in 20m", "in 2h", "in 1d", "at 2026-10-22 09:00" (disabled after it runs)
- cron syntax "30 8 * * 1-5", or @hourly, @daily, @weekly
Times are the server's local time unless timezone is set (IANA name, e.g. Europe/Berlin). Pick the closest supported form and tell the user what you chose.
The prompt should say what to do and what to report; runs can't ask questions, and commands that need approval are refused (ask: deny) or wait (ask: wait).`

const cronToolSchema = `{"type":"object","properties":{
"action":{"type":"string","enum":["list","create","edit","remove","run"]},
"name":{"type":"string","description":"Job name: letters, digits, '.', '-', '_' (the file name). Required except for list."},
"schedule":{"type":"string","description":"When it runs; see the supported forms."},
"prompt":{"type":"string","description":"What each run does."},
"project":{"type":"string","description":"Project name or id; default Scratch."},
"dir":{"type":"string","description":"Absolute working directory (or ~/...); default the project's."},
"role":{"type":"string"},
"provider":{"type":"string","description":"Model provider; with model. Default the role's, agent.tasks.cron or the chat model."},
"model":{"type":"string"},
"effort":{"type":"string"},
"enabled":{"type":"boolean"},
"ask":{"type":"string","enum":["deny","wait"],"description":"Commands that need approval: refuse at once (deny, default) or wait for someone (wait)."},
"ask_timeout":{"type":"string","description":"How long ask: wait waits, e.g. 1h."},
"yolo":{"type":"boolean","description":"Run every shell command no deny rule matches."},
"timezone":{"type":"string"}
},"required":["action"]}`

type cronArgs struct {
	Action     string  `json:"action"`
	Name       string  `json:"name"`
	Schedule   *string `json:"schedule"`
	Prompt     *string `json:"prompt"`
	Project    *string `json:"project"`
	Dir        *string `json:"dir"`
	Role       *string `json:"role"`
	Provider   *string `json:"provider"`
	Model      *string `json:"model"`
	Effort     *string `json:"effort"`
	Enabled    *bool   `json:"enabled"`
	Ask        *string `json:"ask"`
	AskTimeout *string `json:"ask_timeout"`
	Yolo       *bool   `json:"yolo"`
	Timezone   *string `json:"timezone"`
}

func toolErr(format string, args ...any) tools.Result {
	return tools.Result{Text: fmt.Sprintf(format, args...), IsError: true}
}

// cronTool lets the agent manage cron jobs through c.
func (m *Manager) cronTool(c CronControl) tools.Tool {
	return tools.Tool{
		Name:        "cron",
		Description: cronToolDescription,
		Schema:      cronToolSchema,
		Run: func(ctx context.Context, env *tools.Env, raw json.RawMessage) tools.Result {
			var a cronArgs
			dec := json.NewDecoder(strings.NewReader(string(raw)))
			dec.DisallowUnknownFields()
			if err := dec.Decode(&a); err != nil {
				return toolErr("bad arguments: %v", err)
			}
			if a.Action != "list" {
				if err := cron.ValidName(a.Name); err != nil {
					return toolErr("%v", err)
				}
			}
			switch a.Action {
			case "list":
				text, err := c.Describe(ctx)
				if err != nil {
					return toolErr("%v", err)
				}
				return tools.Result{Text: text}
			case "run":
				id, err := c.RunNow(ctx, a.Name)
				if err != nil {
					return toolErr("%v", err)
				}
				return tools.Result{Text: fmt.Sprintf("Started a run of %s (session %s). It runs on its own; its result shows in the job's runs.", a.Name, id)}
			case "remove":
				path := filepath.Join(c.Dir(), a.Name+".md")
				data, err := os.ReadFile(path)
				if err != nil {
					return toolErr("no job %q: %v", a.Name, err)
				}
				if res, ok := m.approveCron(ctx, env, "Remove cron job "+a.Name, string(data)+"\n(file: "+path+")"); !ok {
					return res
				}
				if err := cron.Remove(c.Dir(), a.Name); err != nil {
					return toolErr("%v", err)
				}
				c.Rescan()
				return tools.Result{Text: "Removed cron job " + a.Name + ". Its past runs stay as sessions."}
			case "create", "edit":
				return m.writeCronJob(ctx, env, c, a)
			}
			return toolErr("unknown action %q: use list, create, edit, remove or run", a.Action)
		},
	}
}

// approveCron asks the user; changes to cron jobs always ask, yolo or not.
func (m *Manager) approveCron(ctx context.Context, env *tools.Env, title, detail string) (tools.Result, bool) {
	if env.Approve == nil {
		return toolErr("changing cron jobs needs the user's approval and no one can approve it"), false
	}
	ok, err := env.Approve(ctx, tools.Approval{Title: title, Detail: detail})
	switch {
	case errors.Is(err, tools.ErrNotApproved):
		return toolErr("%v", err), false
	case err != nil:
		return toolErr("approval failed: %v", err), false
	case !ok:
		return toolErr("the user declined; the job was not changed"), false
	}
	return tools.Result{}, true
}

func (m *Manager) writeCronJob(ctx context.Context, env *tools.Env, c CronControl, a cronArgs) tools.Result {
	path := filepath.Join(c.Dir(), a.Name+".md")
	_, statErr := os.Stat(path)
	exists := statErr == nil
	var spec cron.Spec
	switch {
	case a.Action == "create" && exists:
		return toolErr("a job named %q exists; use edit, or pick another name", a.Name)
	case a.Action == "edit" && !exists:
		return toolErr("no job named %q; use create", a.Name)
	case a.Action == "edit":
		spec = cron.SpecOf(cron.Load(path))
	}
	set := func(dst *string, v *string) {
		if v != nil {
			*dst = strings.TrimSpace(*v)
		}
	}
	set(&spec.Schedule, a.Schedule)
	set(&spec.Prompt, a.Prompt)
	set(&spec.Project, a.Project)
	set(&spec.Dir, a.Dir)
	set(&spec.Role, a.Role)
	set(&spec.Model.Provider, a.Provider)
	set(&spec.Model.Model, a.Model)
	set(&spec.Model.Effort, a.Effort)
	set(&spec.Ask, a.Ask)
	set(&spec.AskTimeout, a.AskTimeout)
	set(&spec.Timezone, a.Timezone)
	if a.Enabled != nil {
		spec.Enabled = a.Enabled
	}
	if a.Yolo != nil {
		spec.Yolo = *a.Yolo
	}
	if spec.Ask == cron.AskDeny {
		spec.Ask = ""
	}

	// Check it, and pin "in 20m" to a time so the file says when.
	now := time.Now()
	job, err := cron.Parse(cron.Format(spec), now)
	if err != nil {
		return toolErr("the job isn't valid: %v", err)
	}
	if job.Sched.OneShot() {
		at := cron.At(job.Sched).In(job.Loc)
		layout := "2006-01-02 15:04"
		if at.Second() != 0 {
			layout += ":05"
		}
		spec.Schedule = "at " + at.Format(layout)
		if at.Before(now) {
			return toolErr("%s is in the past", spec.Schedule)
		}
	}
	if spec.Model.Provider != "" {
		if _, ok := m.cfg().Provider(spec.Model.Provider); !ok {
			return toolErr("provider %q is not configured", spec.Model.Provider)
		}
	}
	if spec.Role != "" {
		if _, err := m.role(spec.Role); err != nil {
			return toolErr("%v", err)
		}
	}
	if spec.Project != "" {
		if _, err := m.ResolveProject(ctx, spec.Project); err != nil {
			return toolErr("%v", err)
		}
	}
	data := cron.Format(spec)
	verb := "Create"
	if exists {
		verb = "Change"
	}
	detail := fmt.Sprintf("%s\n(runs %s; file: %s)", data, job.Sched.Words(), path)
	if res, ok := m.approveCron(ctx, env, verb+" cron job "+a.Name, detail); !ok {
		return res
	}
	if _, err := cron.Write(c.Dir(), a.Name, data); err != nil {
		return toolErr("%v", err)
	}
	c.Rescan()
	return tools.Result{Text: fmt.Sprintf("%sd cron job %s: runs %s. File: %s", verb, a.Name, job.Sched.Words(), path)}
}

// ResolveProject finds a project of the default team by id or name (exact,
// then ignoring case).
func (m *Manager) ResolveProject(ctx context.Context, ref string) (ProjectRef, error) {
	list, err := m.Projects(ctx)
	if err != nil {
		return ProjectRef{}, err
	}
	for _, p := range list {
		if p.ID == ref || p.Name == ref {
			return ProjectRef{ID: p.ID, Name: p.Name, Dir: p.Directory}, nil
		}
	}
	var found []ProjectRef
	for _, p := range list {
		if strings.EqualFold(p.Name, ref) {
			found = append(found, ProjectRef{ID: p.ID, Name: p.Name, Dir: p.Directory})
		}
	}
	if len(found) == 1 {
		return found[0], nil
	}
	if len(found) > 1 {
		return ProjectRef{}, invalid("more than one project is called %q; use its id", ref)
	}
	return ProjectRef{}, invalid("no project %q", ref)
}

// ProjectRef is a resolved project: its id, name and directory.
type ProjectRef struct {
	ID, Name, Dir string
}
