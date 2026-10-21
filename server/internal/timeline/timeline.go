// Package timeline turns a session's event log into a readable timeline
// for diagnosing slow or frozen turns (flit debug session): model calls
// with their phases, tool runs, prompts and state changes, with durations,
// and at the end whatever is still open, which is where a frozen turn is
// stuck.
package timeline

import (
	"fmt"
	"io"
	"sort"
	"strings"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/store"
)

// Write prints the timeline of sess from its events (all of them, in seq
// order). now is used for how long open things have been waiting.
func Write(w io.Writer, sess store.Session, events []*flitv1.Event, now time.Time) error {
	p := &printer{w: w, now: now,
		msgs: map[string]*message{}, calls: map[string]callStart{}, tools: map[string]toolStart{}, prompts: map[string]promptStart{},
		queued: map[string]promptStart{}, waiting: map[string]*flitv1.ModelCallWaiting{}}
	p.header(sess, events)
	for _, ev := range events {
		p.event(ev)
	}
	p.open(sess)
	return p.err
}

type message struct {
	role                         flitv1.Role
	text, reasoning              int
	firstDelta, lastDelta, start time.Time
}

type callStart struct {
	msg     string
	attempt int32
	at      time.Time
}

type toolStart struct {
	name, args string
	at         time.Time
}

type promptStart struct {
	title, detail string
	at            time.Time
}

type printer struct {
	w   io.Writer
	err error
	now time.Time

	msgs    map[string]*message
	calls   map[string]callStart // by message id and attempt
	tools   map[string]toolStart
	prompts map[string]promptStart
	queued  map[string]promptStart // queued messages, by queue id
	waiting map[string]*flitv1.ModelCallWaiting
	// lastProgress is the latest prompt progress of each open call.
	lastProgress map[string]*flitv1.PromptProgress
	// compacting is the compaction in progress, if any.
	compacting *compactionStart
	last       time.Time
}

type compactionStart struct {
	c  *flitv1.CompactionStarted
	at time.Time
}

func (p *printer) printf(format string, args ...any) {
	if p.err == nil {
		_, p.err = fmt.Fprintf(p.w, format, args...)
	}
}

// line prints one timeline entry, indented by depth.
func (p *printer) line(at time.Time, depth int, format string, args ...any) {
	p.printf("%s  %s%s\n", at.Local().Format("15:04:05.000"), strings.Repeat("  ", depth), fmt.Sprintf(format, args...))
}

func (p *printer) header(sess store.Session, events []*flitv1.Event) {
	title := sess.Title
	if title == "" {
		title = "(untitled)"
	}
	p.printf("Session %s  %q\n", sess.ID, title)
	p.printf("  model %s/%s, state %s, working dir %s\n", sess.Provider, sess.Model, state(sess.State), sess.WorkingDir)
	if len(events) == 0 {
		p.printf("  no events\n\n")
		return
	}
	first, last := events[0], events[len(events)-1]
	p.printf("  %d events (seq %d-%d), %s to %s\n\n", len(events), first.Seq, last.Seq,
		first.Time.AsTime().Local().Format("2006-01-02 15:04:05"), last.Time.AsTime().Local().Format("2006-01-02 15:04:05"))
}

func callKey(msg string, attempt int32) string { return fmt.Sprintf("%s#%d", msg, attempt) }

func (p *printer) event(ev *flitv1.Event) {
	at := ev.Time.AsTime()
	p.last = at
	switch {
	case ev.GetMessageStarted() != nil:
		m := ev.GetMessageStarted()
		p.msgs[m.MessageId] = &message{role: m.Role, start: at}
		if m.Role == flitv1.Role_ROLE_ASSISTANT {
			p.line(at, 0, "assistant message %s (%s/%s)", m.MessageId, m.Provider, m.Model)
		}
	case ev.GetTextDelta() != nil:
		p.delta(ev.GetTextDelta().MessageId, at, len(ev.GetTextDelta().Text), false)
	case ev.GetReasoningDelta() != nil:
		p.delta(ev.GetReasoningDelta().MessageId, at, len(ev.GetReasoningDelta().Text), true)
	case ev.GetMessageDone() != nil:
		d := ev.GetMessageDone()
		m := p.msgs[d.MessageId]
		delete(p.msgs, d.MessageId)
		if m != nil && m.role == flitv1.Role_ROLE_USER {
			p.line(at, 0, "user message: %s", snippet(d.Text, 80))
			return
		}
		out := fmt.Sprintf("message done (%s): %d chars of text, %d of reasoning", orDash(d.FinishReason), len(d.Text), len(d.Reasoning))
		if m != nil && !m.firstDelta.IsZero() {
			out += fmt.Sprintf(", streamed over %s", dur(m.lastDelta.Sub(m.firstDelta)))
		}
		p.line(at, 1, "%s", out)
	case ev.GetModelCallStarted() != nil:
		c := ev.GetModelCallStarted()
		p.calls[callKey(c.MessageId, c.Attempt)] = callStart{msg: c.MessageId, attempt: c.Attempt, at: at}
		p.line(at, 1, "model call attempt %d sent (watchdog: first token %s, stall %s)", c.Attempt,
			limit(c.FirstByteTimeoutMs), limit(c.StallTimeoutMs))
	case ev.GetPromptProgress() != nil:
		pp := ev.GetPromptProgress()
		if p.lastProgress == nil {
			p.lastProgress = map[string]*flitv1.PromptProgress{}
		}
		p.lastProgress[callKey(pp.MessageId, pp.Attempt)] = pp
		p.line(at, 2, "prompt %d/%d tokens (%d cached) after %s", pp.Processed, pp.Total, pp.Cached, dur(ms(pp.ElapsedMs)))
	case ev.GetModelCallEnded() != nil:
		p.callEnded(at, ev.GetModelCallEnded())
	case ev.GetUsage() != nil:
		u := ev.GetUsage()
		p.line(at, 1, "usage: %d in, %d out of %s context; %.1f tok/s prompt, %.1f tok/s generation (%s)",
			u.InputTokens, u.OutputTokens, orDash(count(u.ContextLength)), u.PromptTokensPerSecond, u.GenerationTokensPerSecond, orDash(u.TimingSource))
	case ev.GetToolCallStarted() != nil:
		t := ev.GetToolCallStarted()
		p.tools[t.ToolCallId] = toolStart{name: t.Name, args: t.Arguments, at: at}
		p.line(at, 1, "tool %s (%s) started: %s", t.Name, t.ToolCallId, snippet(t.Arguments, 100))
	case ev.GetToolCallDone() != nil:
		t := ev.GetToolCallDone()
		start, ok := p.tools[t.ToolCallId]
		delete(p.tools, t.ToolCallId)
		took := "?"
		if ok {
			took = dur(at.Sub(start.at))
		}
		status := "ok"
		if t.IsError {
			status = "error"
		}
		extra := ""
		if t.Truncated {
			extra = fmt.Sprintf(", truncated (%d bytes cut)", t.OmittedBytes)
		}
		p.line(at, 1, "tool %s (%s) done after %s: %s, %d bytes%s", start.name, t.ToolCallId, took, status, len(t.Result), extra)
	case ev.GetPromptRequested() != nil:
		pr := ev.GetPromptRequested()
		p.prompts[pr.PromptId] = promptStart{title: pr.Title, detail: pr.Detail, at: at}
		p.line(at, 1, "asked the user: %s: %s", pr.Title, snippet(pr.Detail, 80))
	case ev.GetPromptResolved() != nil:
		pr := ev.GetPromptResolved()
		start, ok := p.prompts[pr.PromptId]
		delete(p.prompts, pr.PromptId)
		took := "?"
		if ok {
			took = dur(at.Sub(start.at))
		}
		p.line(at, 1, "answered after %s: %s%s", took, decision(pr.Decision), paren(pr.Reason))
	case ev.GetTaskStateChanged() != nil:
		t := ev.GetTaskStateChanged()
		p.line(at, 0, "state: %s%s", state(t.State), paren(t.Reason))
	case ev.GetError() != nil:
		e := ev.GetError()
		p.line(at, 1, "ERROR: %s (can continue: %v)", e.Message, e.TurnCanContinue)
	case ev.GetModelChanged() != nil:
		m := ev.GetModelChanged()
		p.line(at, 0, "model set to %s/%s%s", m.Provider, m.Model, paren(m.Effort))
	case ev.GetModelCallWaiting() != nil:
		w := ev.GetModelCallWaiting()
		switch w.Reason {
		case flitv1.ModelWaitReason_MODEL_WAIT_REASON_SLOTS_BUSY:
			p.line(at, 2, "waiting for a free llama.cpp slot (all %d busy)", w.TotalSlots)
		case flitv1.ModelWaitReason_MODEL_WAIT_REASON_SLEEPING:
			p.line(at, 2, "waiting: the model is asleep and waking up")
		case flitv1.ModelWaitReason_MODEL_WAIT_REASON_LOADING:
			p.line(at, 2, "waiting: llama.cpp is loading the model")
		}
		p.waiting[callKey(w.MessageId, w.Attempt)] = w
	case ev.GetPromptCache() != nil:
		c := ev.GetPromptCache()
		what := "saved to"
		switch c.Action {
		case flitv1.PromptCacheAction_PROMPT_CACHE_ACTION_RESTORED:
			what = "restored from"
		case flitv1.PromptCacheAction_PROMPT_CACHE_ACTION_DISCARDED:
			p.line(at, 1, "prompt cache %s dropped: it holds the prompt from before compaction", c.File)
			return
		}
		if c.Error != "" {
			p.line(at, 1, "prompt cache (slot %d) not %s %s: %s", c.Slot, what, c.File, c.Error)
		} else {
			p.line(at, 1, "prompt cache (slot %d) %s %s: %d tokens in %s", c.Slot, what, c.File, c.Tokens, dur(ms(c.ElapsedMs)))
		}
	case ev.GetReasoningEndRequested() != nil:
		p.line(at, 2, "asked the model to stop thinking%s", paren(ev.GetReasoningEndRequested().Client))
	case ev.GetReasoningEndIgnored() != nil:
		p.line(at, 2, "the model kept thinking: it can't be cut short")
	case ev.GetCompactionStarted() != nil:
		c := ev.GetCompactionStarted()
		p.compacting = &compactionStart{c: c, at: at}
		p.line(at, 0, "compacting (%s) with %s/%s: context %s", how(c.Auto, c.Client), c.Provider, c.Model, used(c.Tokens, c.ContextLength))
	case ev.GetCompactionDone() != nil:
		c := ev.GetCompactionDone()
		took := ""
		if p.compacting != nil {
			took = " after " + dur(at.Sub(p.compacting.at))
		}
		p.compacting = nil
		if c.Error != "" {
			p.line(at, 0, "compaction FAILED%s: %s", took, c.Error)
			return
		}
		exact := "estimated"
		if c.TokensExact {
			exact = "counted"
		}
		p.line(at, 0, "compacted%s: events up to seq %d summarized, %d turn(s) kept; context %d -> %d tokens (%s)",
			took, c.CoveredSeq, c.KeptTurns, c.TokensBefore, c.TokensAfter, exact)
		p.line(at, 1, "summary (%d chars): %s", len(c.Summary), snippet(c.Summary, 200))
	case ev.GetMessageQueued() != nil:
		q := ev.GetMessageQueued()
		p.queued[q.QueueId] = promptStart{title: q.Text, at: at}
		p.line(at, 1, "message queued%s: %s", paren(q.Client), snippet(q.Text, 80))
	case ev.GetQueuedMessageUpdated() != nil:
		u := ev.GetQueuedMessageUpdated()
		if u.Cancelled {
			delete(p.queued, u.QueueId)
			p.line(at, 1, "queued message cancelled")
		} else {
			q := p.queued[u.QueueId]
			q.title = u.Text
			p.queued[u.QueueId] = q
			p.line(at, 1, "queued message edited: %s", snippet(u.Text, 80))
		}
	case ev.GetQueuedMessageDelivered() != nil:
		d := ev.GetQueuedMessageDelivered()
		if q, ok := p.queued[d.QueueId]; ok {
			p.line(at, 1, "queued message delivered after %s", dur(at.Sub(q.at)))
		}
		delete(p.queued, d.QueueId)
	case ev.GetBranchCreated() != nil:
		b := ev.GetBranchCreated()
		kind := "retry of"
		if b.Kind == flitv1.BranchKind_BRANCH_KIND_EDIT {
			kind = "edit of"
		}
		p.line(at, 0, "branch %s: %s %s, forked from %s after seq %d%s", b.BranchId, kind, b.MessageId,
			branchName(b.ParentBranchId), b.ForkSeq, paren(b.Client))
	case ev.GetBranchSwitched() != nil:
		b := ev.GetBranchSwitched()
		p.line(at, 0, "switched to branch %s%s", branchName(b.BranchId), paren(b.Client))
	case ev.GetCronRun() != nil:
		c := ev.GetCronRun()
		p.line(at, 0, "cron run of %s (%s), %s", c.Job, c.ScheduleText,
			strings.ToLower(strings.TrimPrefix(c.Trigger.String(), "CRON_TRIGGER_")))
	case ev.GetToolOutput() != nil, ev.GetTodoUpdated() != nil, ev.GetFeedback() != nil, ev.GetPermissionCheck() != nil:
		// Not timeline material.
	}
}

func (p *printer) delta(msg string, at time.Time, n int, reasoning bool) {
	m := p.msgs[msg]
	if m == nil {
		return
	}
	if m.firstDelta.IsZero() {
		m.firstDelta = at
	}
	m.lastDelta = at
	if reasoning {
		m.reasoning += n
	} else {
		m.text += n
	}
}

func (p *printer) callEnded(at time.Time, e *flitv1.ModelCallEnded) {
	key := callKey(e.MessageId, e.Attempt)
	delete(p.calls, key)
	delete(p.lastProgress, key)
	var b strings.Builder
	switch e.Outcome {
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_OK:
		b.WriteString("ok")
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED:
		fmt.Fprintf(&b, "STALLED while %s", phase(e.Phase))
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_RETRIED:
		fmt.Fprintf(&b, "given up and resent by request while %s", phase(e.Phase))
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_CANCELLED:
		fmt.Fprintf(&b, "cancelled while %s", phase(e.Phase))
	default:
		fmt.Fprintf(&b, "ERROR while %s", phase(e.Phase))
	}
	var marks []string
	for _, m := range []struct {
		name string
		ms   int64
	}{{"headers", e.ResponseHeadersMs}, {"first byte", e.FirstByteMs}, {"first token", e.FirstTokenMs}, {"last byte", e.LastByteMs}} {
		if m.ms > 0 {
			marks = append(marks, fmt.Sprintf("%s %s", m.name, dur(ms(m.ms))))
		}
	}
	fmt.Fprintf(&b, " after %s", dur(ms(e.TotalMs)))
	if len(marks) > 0 {
		fmt.Fprintf(&b, " (%s)", strings.Join(marks, ", "))
	}
	fmt.Fprintf(&b, ", %d bytes", e.Bytes)
	if e.InputTokens > 0 || e.OutputTokens > 0 {
		fmt.Fprintf(&b, ", %d in / %d out", e.InputTokens, e.OutputTokens)
	}
	if e.CachedTokens > 0 {
		fmt.Fprintf(&b, " (%d cached)", e.CachedTokens)
	}
	if e.PromptMs > 0 || e.PredictedMs > 0 {
		fmt.Fprintf(&b, "; llama.cpp: prompt %d tok in %s, generated %d tok in %s",
			e.PromptTokens, dur(ms(e.PromptMs)), e.PredictedTokens, dur(ms(e.PredictedMs)))
	}
	if e.WillRetry {
		b.WriteString("; retrying")
	}
	p.line(at, 1, "model call attempt %d %s", e.Attempt, b.String())
	if e.Error != "" && e.Outcome != flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_RETRIED {
		p.line(at, 2, "%s", e.Error)
	}
}

// open reports what never finished: where a frozen turn is.
func (p *printer) open(sess store.Session) {
	type item struct {
		at   time.Time
		text string
	}
	var items []item
	for key, c := range p.calls {
		text := fmt.Sprintf("model call for %s (attempt %d) sent %s ago and never ended", c.msg, c.attempt, dur(p.now.Sub(c.at)))
		if m := p.msgs[c.msg]; m != nil && !m.lastDelta.IsZero() {
			text += fmt.Sprintf("; last output %s ago (%d chars of text, %d of reasoning so far)", dur(p.now.Sub(m.lastDelta)), m.text, m.reasoning)
		} else if w := p.waiting[key]; w != nil && w.Reason == flitv1.ModelWaitReason_MODEL_WAIT_REASON_SLOTS_BUSY {
			text += fmt.Sprintf("; waiting for a free llama.cpp slot (all %d busy)", w.TotalSlots)
		} else if pp := p.lastProgress[key]; pp != nil {
			text += fmt.Sprintf("; no output yet, last prompt progress %d/%d", pp.Processed, pp.Total)
		} else {
			text += "; no output or progress yet"
		}
		items = append(items, item{c.at, text})
	}
	for id, t := range p.tools {
		items = append(items, item{t.at, fmt.Sprintf("tool %s (%s) started %s ago and never finished: %s", t.name, id, dur(p.now.Sub(t.at)), snippet(t.args, 100))})
	}
	for id, pr := range p.prompts {
		items = append(items, item{pr.at, fmt.Sprintf("prompt %s waiting for the user for %s: %s", id, dur(p.now.Sub(pr.at)), pr.title)})
	}
	if c := p.compacting; c != nil {
		items = append(items, item{c.at, fmt.Sprintf("compaction started %s ago and never finished (summary call on %s/%s)", dur(p.now.Sub(c.at)), c.c.Provider, c.c.Model)})
	}
	for _, q := range p.queued {
		items = append(items, item{q.at, fmt.Sprintf("message queued %s ago, not delivered yet: %s", dur(p.now.Sub(q.at)), snippet(q.title, 80))})
	}
	sort.Slice(items, func(i, j int) bool { return items[i].at.Before(items[j].at) })
	p.printf("\n")
	if len(items) == 0 {
		p.printf("Nothing open.")
		if sess.State == flitv1.TaskState_TASK_STATE_WORKING && !p.last.IsZero() {
			p.printf(" The session says it's working but the last event was %s ago: the harness itself may be stuck.", dur(p.now.Sub(p.last)))
		}
		p.printf("\n")
		return
	}
	p.printf("Still open:\n")
	for _, it := range items {
		p.printf("  %s  %s\n", it.at.Local().Format("15:04:05.000"), it.text)
	}
}

// how says who started a compaction.
func how(auto bool, client string) string {
	if auto {
		return "automatic, near the context limit"
	}
	if client != "" {
		return "asked for by " + client
	}
	return "asked for"
}

// used is context use, e.g. "3000/4096 tokens (73%)".
func used(tokens, length int64) string {
	if length <= 0 {
		return fmt.Sprintf("%d tokens", tokens)
	}
	return fmt.Sprintf("%d/%d tokens (%d%%)", tokens, length, tokens*100/length)
}

func branchName(id string) string {
	if id == "" {
		return "root"
	}
	return id
}

func ms(n int64) time.Duration { return time.Duration(n) * time.Millisecond }

// dur prints a duration compactly: 850ms, 12.3s, 4m05s, 2h10m.
func dur(d time.Duration) string {
	switch {
	case d < time.Second:
		return fmt.Sprintf("%dms", d.Milliseconds())
	case d < time.Minute:
		return fmt.Sprintf("%.1fs", d.Seconds())
	case d < time.Hour:
		return fmt.Sprintf("%dm%02ds", int(d.Minutes()), int(d.Seconds())%60)
	}
	return fmt.Sprintf("%dh%02dm", int(d.Hours()), int(d.Minutes())%60)
}

func limit(msv int64) string {
	if msv <= 0 {
		return "off"
	}
	return dur(ms(msv))
}

func count(n int64) string {
	if n <= 0 {
		return ""
	}
	return fmt.Sprint(n)
}

func phase(p string) string {
	if p == "" {
		return "unknown phase"
	}
	return strings.ReplaceAll(p, "_", " ")
}

func state(s flitv1.TaskState) string {
	return strings.ToLower(strings.TrimPrefix(s.String(), "TASK_STATE_"))
}

func decision(d flitv1.PromptDecision) string {
	return strings.ToLower(strings.TrimPrefix(d.String(), "PROMPT_DECISION_"))
}

func paren(s string) string {
	if s == "" {
		return ""
	}
	return " (" + s + ")"
}

func orDash(s string) string {
	if s == "" {
		return "-"
	}
	return s
}

func snippet(s string, n int) string {
	s = strings.Join(strings.Fields(s), " ")
	if len(s) > n {
		return s[:n] + "…"
	}
	return s
}
