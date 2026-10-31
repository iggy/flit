package webhook

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"unicode/utf8"
)

// Delivery is one webhook delivery, made sense of.
type Delivery struct {
	// ID is the sender's delivery id; empty if it sent none.
	ID string
	// Event and Action, e.g. "pull_request" and "opened"; Action is empty
	// for events without one.
	Event, Action string
	// Repo is owner/name and Sender the login that caused the event, if
	// the payload says.
	Repo, Sender string
	// About is one line on what happened; URL links to it, if anything.
	About, URL string
	// Details is what the model is shown about the event: the main facts,
	// then the payload with the noise left out.
	Details string
	// Ping is GitHub's test delivery, sent when a hook is set up.
	Ping bool
}

// Errors from ParseGitHub; the receiver answers them with 401 and 400.
var (
	ErrBadSignature = errors.New("signature missing or wrong")
	ErrBadDelivery  = errors.New("not a GitHub webhook delivery")
)

// ParseGitHub checks a GitHub delivery's signature (X-Hub-Signature-256,
// HMAC-SHA256 of the body with secret) and reads it.
func ParseGitHub(secret string, header http.Header, body []byte) (Delivery, error) {
	if !validSignature(secret, header.Get("X-Hub-Signature-256"), body) {
		return Delivery{}, ErrBadSignature
	}
	d := Delivery{ID: header.Get("X-GitHub-Delivery"), Event: header.Get("X-GitHub-Event")}
	if d.Event == "" {
		return Delivery{}, fmt.Errorf("%w: no X-GitHub-Event header", ErrBadDelivery)
	}
	// Hooks set to application/x-www-form-urlencoded send payload=<json>.
	if strings.HasPrefix(header.Get("Content-Type"), "application/x-www-form-urlencoded") && !bytes.HasPrefix(bytes.TrimSpace(body), []byte("{")) {
		form, err := url.ParseQuery(string(body))
		if err != nil {
			return Delivery{}, fmt.Errorf("%w: %v", ErrBadDelivery, err)
		}
		body = []byte(form.Get("payload"))
	}
	var p map[string]any
	dec := json.NewDecoder(bytes.NewReader(body))
	dec.UseNumber()
	if err := dec.Decode(&p); err != nil {
		return Delivery{}, fmt.Errorf("%w: payload: %v", ErrBadDelivery, err)
	}
	d.Ping = d.Event == "ping"
	d.Action = str(p, "action")
	d.Repo = str(p, "repository", "full_name")
	d.Sender = str(p, "sender", "login")
	d.About, d.URL, d.Details = describe(d, p)
	return d, nil
}

func validSignature(secret, sig string, body []byte) bool {
	got, ok := strings.CutPrefix(sig, "sha256=")
	if !ok {
		return false
	}
	gotMAC, err := hex.DecodeString(got)
	if err != nil {
		return false
	}
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	return hmac.Equal(gotMAC, mac.Sum(nil))
}

// Sign is the X-Hub-Signature-256 value for body, for tests and senders.
func Sign(secret string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	return "sha256=" + hex.EncodeToString(mac.Sum(nil))
}

// Caps on what the model is shown.
const (
	maxText    = 4000
	maxPayload = 12000
	maxCommits = 20
)

// describe sums up the event for the run: one line, a link and details.
func describe(d Delivery, p map[string]any) (about, link, details string) {
	var b strings.Builder
	line := func(k, v string) {
		if v != "" {
			fmt.Fprintf(&b, "%s: %s\n", k, v)
		}
	}
	text := func(k, v string) {
		if v = strings.TrimSpace(v); v != "" {
			fmt.Fprintf(&b, "%s:\n%s\n", k, clip(v, maxText))
		}
	}
	in := ""
	if d.Repo != "" {
		in = " in " + d.Repo
	}
	act := d.Action
	if act == "" {
		act = "event"
	}
	line("Event", strings.TrimSuffix(d.Event+"."+d.Action, "."))
	line("Repository", d.Repo)
	line("Sender", d.Sender)

	switch d.Event {
	case "pull_request":
		pr := obj(p, "pull_request")
		n := str(pr, "number")
		about = fmt.Sprintf("PR #%s %s%s: %s", n, act, in, str(pr, "title"))
		link = str(pr, "html_url")
		line("Pull request", "#"+n+" "+str(pr, "title"))
		line("URL", link)
		line("Author", str(pr, "user", "login"))
		line("Branches", str(pr, "head", "label")+" into "+str(pr, "base", "ref"))
		line("Draft", boolStr(pr, "draft"))
		line("State", str(pr, "state"))
		text("Description", str(pr, "body"))
	case "issues":
		is := obj(p, "issue")
		n := str(is, "number")
		about = fmt.Sprintf("Issue #%s %s%s: %s", n, act, in, str(is, "title"))
		link = str(is, "html_url")
		line("Issue", "#"+n+" "+str(is, "title"))
		line("URL", link)
		line("Author", str(is, "user", "login"))
		line("Labels", names(is, "labels"))
		text("Description", str(is, "body"))
	case "issue_comment":
		is, c := obj(p, "issue"), obj(p, "comment")
		kind := "issue"
		if obj(is, "pull_request") != nil {
			kind = "PR"
		}
		n := str(is, "number")
		about = fmt.Sprintf("Comment %s on %s #%s%s by %s", act, kind, n, in, str(c, "user", "login"))
		link = str(c, "html_url")
		line(strings.ToUpper(kind[:1])+kind[1:], "#"+n+" "+str(is, "title"))
		line("URL", link)
		line("Comment by", str(c, "user", "login"))
		text("Comment", str(c, "body"))
	case "pull_request_review":
		pr, r := obj(p, "pull_request"), obj(p, "review")
		n := str(pr, "number")
		about = fmt.Sprintf("Review %s (%s) on PR #%s%s by %s", act, str(r, "state"), n, in, str(r, "user", "login"))
		link = str(r, "html_url")
		line("Pull request", "#"+n+" "+str(pr, "title"))
		line("URL", link)
		line("Reviewer", str(r, "user", "login"))
		line("State", str(r, "state"))
		text("Review", str(r, "body"))
	case "pull_request_review_comment":
		pr, c := obj(p, "pull_request"), obj(p, "comment")
		n := str(pr, "number")
		about = fmt.Sprintf("Review comment %s on PR #%s%s by %s", act, n, in, str(c, "user", "login"))
		link = str(c, "html_url")
		line("Pull request", "#"+n+" "+str(pr, "title"))
		line("URL", link)
		line("File", str(c, "path"))
		line("Comment by", str(c, "user", "login"))
		text("Comment", str(c, "body"))
	case "push":
		ref := strings.TrimPrefix(strings.TrimPrefix(str(p, "ref"), "refs/heads/"), "refs/tags/")
		commits, _ := p["commits"].([]any)
		about = fmt.Sprintf("Push to %s%s: %d commit(s)", ref, in, len(commits))
		link = str(p, "compare")
		line("Ref", str(p, "ref"))
		line("Compare", link)
		line("Before", str(p, "before"))
		line("After", str(p, "after"))
		for i, c := range commits {
			if i == maxCommits {
				fmt.Fprintf(&b, "... and %d more commits\n", len(commits)-i)
				break
			}
			cm, _ := c.(map[string]any)
			msg, _, _ := strings.Cut(str(cm, "message"), "\n")
			id := str(cm, "id")
			fmt.Fprintf(&b, "- %s %s (%s)\n", id[:min(len(id), 12)], msg, str(cm, "author", "name"))
		}
	case "release":
		r := obj(p, "release")
		about = fmt.Sprintf("Release %s %s%s", str(r, "tag_name"), act, in)
		link = str(r, "html_url")
		line("Release", str(r, "name"))
		line("Tag", str(r, "tag_name"))
		line("URL", link)
		text("Notes", str(r, "body"))
	case "workflow_run":
		r := obj(p, "workflow_run")
		about = fmt.Sprintf("Workflow %q %s (%s) on %s%s", str(r, "name"), act, orStr(str(r, "conclusion"), str(r, "status")), str(r, "head_branch"), in)
		link = str(r, "html_url")
		line("Workflow", str(r, "name"))
		line("URL", link)
		line("Branch", str(r, "head_branch"))
		line("Commit", str(r, "head_sha"))
		line("Status", str(r, "status"))
		line("Conclusion", str(r, "conclusion"))
	case "check_suite", "check_run":
		r := obj(p, d.Event)
		about = fmt.Sprintf("%s %s (%s) on %s%s", strings.ReplaceAll(d.Event, "_", " "), act, orStr(str(r, "conclusion"), str(r, "status")), orStr(str(r, "head_branch"), str(r, "check_suite", "head_branch")), in)
		link = str(r, "html_url")
		line("Name", str(r, "name"))
		line("URL", link)
		line("Commit", str(r, "head_sha"))
		line("Status", str(r, "status"))
		line("Conclusion", str(r, "conclusion"))
	case "ping":
		about = "Ping" + in
	default:
		about = fmt.Sprintf("%s %s%s", d.Event, act, in)
	}
	if d.Sender != "" && !strings.Contains(about, " by ") {
		about += " (by " + d.Sender + ")"
	}

	raw, _ := json.MarshalIndent(prune(p), "", " ")
	b.WriteString("\nThe payload, without API links and ids:\n")
	b.WriteString(clip(string(raw), maxPayload))
	return clip(oneLine(about), 200), link, b.String()
}

// prune leaves the noise out of a payload: API links (*_url but html_url),
// node ids, avatars and the like.
func prune(v any) any {
	switch t := v.(type) {
	case map[string]any:
		out := map[string]any{}
		for k, val := range t {
			if (strings.HasSuffix(k, "_url") && k != "html_url") || k == "url" || k == "node_id" || k == "gravatar_id" ||
				k == "_links" || k == "site_admin" || k == "user_view_type" || k == "performed_via_github_app" || k == "reactions" {
				continue
			}
			if val == nil {
				continue
			}
			out[k] = prune(val)
		}
		return out
	case []any:
		out := make([]any, len(t))
		for i := range t {
			out[i] = prune(t[i])
		}
		return out
	default:
		return v
	}
}

func obj(m map[string]any, path ...string) map[string]any {
	for _, k := range path {
		next, ok := m[k].(map[string]any)
		if !ok {
			return nil
		}
		m = next
	}
	return m
}

func str(m map[string]any, path ...string) string {
	v := obj(m, path[:len(path)-1]...)
	if v == nil {
		return ""
	}
	switch t := v[path[len(path)-1]].(type) {
	case string:
		return t
	case json.Number:
		return t.String()
	}
	return ""
}

func boolStr(m map[string]any, k string) string {
	if b, ok := m[k].(bool); ok {
		return fmt.Sprint(b)
	}
	return ""
}

// names joins the name fields of a list of objects (labels).
func names(m map[string]any, k string) string {
	list, _ := m[k].([]any)
	var out []string
	for _, v := range list {
		if o, ok := v.(map[string]any); ok && str(o, "name") != "" {
			out = append(out, str(o, "name"))
		}
	}
	sort.Strings(out)
	return strings.Join(out, ", ")
}

func orStr(a, b string) string {
	if a != "" {
		return a
	}
	return b
}

func oneLine(s string) string { return strings.Join(strings.Fields(s), " ") }

func clip(s string, n int) string {
	if utf8.RuneCountInString(s) <= n {
		return s
	}
	return string([]rune(s)[:n-1]) + "…"
}
