package sessionsvc_test

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"connectrpc.com/connect"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/server"
	"github.com/iggy/flit/server/internal/store"
)

const token = "flit_test"

func start(t *testing.T, cfg config.Config) flitv1connect.SessionServiceClient {
	t.Helper()
	st, err := store.Open(context.Background(), filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	m, err := agent.NewManager(context.Background(), st, func() config.Config { return cfg }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewServer(server.NewHandler(token, m))
	t.Cleanup(func() {
		srv.CloseClientConnections()
		srv.Close()
		m.Close()
		st.Close()
	})
	return client(srv.URL, token)
}

func client(url, tok string) flitv1connect.SessionServiceClient {
	return flitv1connect.NewSessionServiceClient(http.DefaultClient, url, connect.WithInterceptors(connect.UnaryInterceptorFunc(
		func(next connect.UnaryFunc) connect.UnaryFunc {
			return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
				if tok != "" {
					req.Header().Set("Authorization", "Bearer "+tok)
				}
				return next(ctx, req)
			}
		}), streamAuth(tok)))
}

// streamAuth adds the token to streaming calls.
type streamAuth string

func (a streamAuth) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc { return next }
func (a streamAuth) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return func(ctx context.Context, spec connect.Spec) connect.StreamingClientConn {
		conn := next(ctx, spec)
		if a != "" {
			conn.RequestHeader().Set("Authorization", "Bearer "+string(a))
		}
		return conn
	}
}
func (a streamAuth) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return next
}

func fakeConfig(t *testing.T) (config.Config, *llmtest.Server) {
	fake := llmtest.New(t)
	cfg := config.Default()
	cfg.Providers = []config.Provider{{Name: "fake", BaseURL: fake.BaseURL()}}
	cfg.Agent.Model = "m"
	return cfg, fake
}

// runTurn sends text and returns the turn's events (through the end state),
// answering any prompt with answer.
func runTurn(t *testing.T, c flitv1connect.SessionServiceClient, id, text string, answer flitv1.PromptDecision, timeout time.Duration) []*flitv1.Event {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	sess, err := c.GetSession(ctx, connect.NewRequest(&flitv1.GetSessionRequest{SessionId: id}))
	if err != nil {
		t.Fatal(err)
	}
	stream, err := c.Attach(ctx, connect.NewRequest(&flitv1.AttachRequest{SessionId: id, FromSeq: sess.Msg.Session.LastSeq + 1}))
	if err != nil {
		t.Fatal(err)
	}
	defer stream.Close()
	if _, err := c.Send(ctx, connect.NewRequest(&flitv1.SendRequest{SessionId: id, Text: text})); err != nil {
		t.Fatal(err)
	}
	var evs []*flitv1.Event
	for stream.Receive() {
		ev := stream.Msg().Event
		evs = append(evs, ev)
		if p := ev.GetPromptRequested(); p != nil {
			if _, err := c.AnswerPrompt(ctx, connect.NewRequest(&flitv1.AnswerPromptRequest{
				SessionId: id, PromptId: p.PromptId, Decision: answer, Client: "sessionsvc-test",
			})); err != nil {
				t.Fatal(err)
			}
		}
		switch ev.GetTaskStateChanged().GetState() {
		case flitv1.TaskState_TASK_STATE_DONE, flitv1.TaskState_TASK_STATE_STUCK:
			return evs
		}
	}
	t.Fatalf("stream ended: %v; events so far: %v", stream.Err(), evs)
	return nil
}

func TestSessionAPI(t *testing.T) {
	cfg, fake := fakeConfig(t)
	c := start(t, cfg)
	ctx := context.Background()
	dir := t.TempDir()

	created, err := c.CreateSession(ctx, connect.NewRequest(&flitv1.CreateSessionRequest{WorkingDir: dir, Title: "api test"}))
	if err != nil {
		t.Fatal(err)
	}
	s := created.Msg.Session
	if s.Provider != "fake" || s.Model != "m" || s.State != flitv1.TaskState_TASK_STATE_IDLE || s.TeamId == "" || s.ProjectId == "" {
		t.Fatalf("created %v", s)
	}

	fake.Push(
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "shell", `{"command":"echo via-api"}`})},
		llmtest.Response{Chunks: llmtest.Text("ran it")},
	)
	evs := runTurn(t, c, s.Id, "run echo", flitv1.PromptDecision_PROMPT_DECISION_ALLOW, 10*time.Second)
	var resolved *flitv1.PromptResolved
	var final string
	for _, ev := range evs {
		if r := ev.GetPromptResolved(); r != nil {
			resolved = r
		}
		if d := ev.GetMessageDone(); d != nil {
			final = d.Text
		}
	}
	if resolved == nil || resolved.Client != "sessionsvc-test" || final != "ran it" {
		t.Fatalf("resolved=%v final=%q", resolved, final)
	}

	// Errors map to the right codes.
	for _, tc := range []struct {
		err  error
		code connect.Code
	}{
		{err: second(c.GetSession(ctx, connect.NewRequest(&flitv1.GetSessionRequest{SessionId: "ses_nope"}))), code: connect.CodeNotFound},
		{err: second(c.CreateSession(ctx, connect.NewRequest(&flitv1.CreateSessionRequest{WorkingDir: "relative"}))), code: connect.CodeInvalidArgument},
		{err: second(c.AnswerPrompt(ctx, connect.NewRequest(&flitv1.AnswerPromptRequest{SessionId: s.Id, PromptId: "p"}))), code: connect.CodeInvalidArgument},
		{err: second(c.AnswerPrompt(ctx, connect.NewRequest(&flitv1.AnswerPromptRequest{SessionId: s.Id, PromptId: "p", Decision: flitv1.PromptDecision_PROMPT_DECISION_ALLOW}))), code: connect.CodeFailedPrecondition},
		{err: second(c.SetModel(ctx, connect.NewRequest(&flitv1.SetModelRequest{SessionId: s.Id, Provider: "nope", Model: "x"}))), code: connect.CodeInvalidArgument},
	} {
		if connect.CodeOf(tc.err) != tc.code {
			t.Errorf("got %v, want %v", tc.err, tc.code)
		}
	}

	// Pagination.
	for range 2 {
		if _, err := c.CreateSession(ctx, connect.NewRequest(&flitv1.CreateSessionRequest{WorkingDir: dir})); err != nil {
			t.Fatal(err)
		}
	}
	page1, err := c.ListSessions(ctx, connect.NewRequest(&flitv1.ListSessionsRequest{PageSize: 2}))
	if err != nil || len(page1.Msg.Sessions) != 2 || page1.Msg.NextPageToken == "" {
		t.Fatalf("page 1: %v, %v", page1, err)
	}
	page2, err := c.ListSessions(ctx, connect.NewRequest(&flitv1.ListSessionsRequest{PageSize: 2, PageToken: page1.Msg.NextPageToken}))
	if err != nil || len(page2.Msg.Sessions) != 1 || page2.Msg.NextPageToken != "" {
		t.Fatalf("page 2: %v, %v", page2, err)
	}
}

func second[T any](_ T, err error) error { return err }

func TestSessionAPIRequiresToken(t *testing.T) {
	cfg, _ := fakeConfig(t)
	st, err := store.Open(context.Background(), filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	defer st.Close()
	m, err := agent.NewManager(context.Background(), st, func() config.Config { return cfg }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatal(err)
	}
	defer m.Close()
	srv := httptest.NewServer(server.NewHandler(token, m))
	defer srv.Close()

	for _, tok := range []string{"", "flit_wrong"} {
		c := client(srv.URL, tok)
		ctx := context.Background()
		_, err := c.ListSessions(ctx, connect.NewRequest(&flitv1.ListSessionsRequest{}))
		if connect.CodeOf(err) != connect.CodeUnauthenticated {
			t.Errorf("token %q: ListSessions err = %v", tok, err)
		}
		stream, err := c.Attach(ctx, connect.NewRequest(&flitv1.AttachRequest{SessionId: "x"}))
		if err == nil {
			for stream.Receive() {
			}
			err = stream.Err()
		}
		if connect.CodeOf(err) != connect.CodeUnauthenticated {
			t.Errorf("token %q: Attach err = %v", tok, err)
		}
	}
}

// TestLlamaCppCodingTask runs a small real coding task against an
// OpenAI-compatible endpoint, typically llama.cpp's llama-server started
// with --jinja (needed for tool calls). Skipped unless FLIT_TEST_LLAMA_URL
// is set, e.g. FLIT_TEST_LLAMA_URL=http://localhost:8080/v1.
// FLIT_TEST_LLAMA_MODEL (default "default") and FLIT_TEST_LLAMA_KEY are
// optional.
func TestLlamaCppCodingTask(t *testing.T) {
	baseURL := os.Getenv("FLIT_TEST_LLAMA_URL")
	if baseURL == "" {
		t.Skip("set FLIT_TEST_LLAMA_URL to run against a real model endpoint")
	}
	model := os.Getenv("FLIT_TEST_LLAMA_MODEL")
	if model == "" {
		model = "default"
	}
	cfg := config.Default()
	cfg.Providers = []config.Provider{{Name: "llama", BaseURL: baseURL, APIKey: os.Getenv("FLIT_TEST_LLAMA_KEY")}}
	cfg.Agent.Model = model
	cfg.Agent.MaxSteps = 25
	cfg.Shell.Default = "deny" // file tools only; never run model-chosen commands here
	cfg.Shell.Allow = nil
	c := start(t, cfg)

	dir := t.TempDir()
	must(t, os.WriteFile(filepath.Join(dir, "VERSION"), []byte("1.4.2\n"), 0o644))
	must(t, os.WriteFile(filepath.Join(dir, "greet.go"), []byte(
		"package greet\n\n// Hello returns a greeting.\nfunc Hello(name string) string {\n\treturn \"Helo, \" + name\n}\n"), 0o644))
	must(t, os.WriteFile(filepath.Join(dir, "AGENTS.md"), []byte("Keep edits minimal. Do not create new files.\n"), 0o644))

	ctx := context.Background()
	created, err := c.CreateSession(ctx, connect.NewRequest(&flitv1.CreateSessionRequest{WorkingDir: dir}))
	if err != nil {
		t.Fatal(err)
	}
	evs := runTurn(t, c, created.Msg.Session.Id,
		"Two small fixes in this directory: (1) bump the patch number in VERSION by one; "+
			"(2) fix the typo \"Helo\" in greet.go so it says \"Hello\". Use your tools to read and edit the files.",
		flitv1.PromptDecision_PROMPT_DECISION_DENY, 10*time.Minute)

	var toolCalls []string
	for _, ev := range evs {
		if tc := ev.GetToolCallStarted(); tc != nil {
			toolCalls = append(toolCalls, tc.Name)
		}
		if e := ev.GetError(); e != nil {
			t.Errorf("turn error: %s", e.Message)
		}
	}
	t.Logf("tool calls: %v", toolCalls)
	if last := evs[len(evs)-1].GetTaskStateChanged(); last.State != flitv1.TaskState_TASK_STATE_DONE {
		t.Fatalf("turn ended %v", last)
	}

	version, _ := os.ReadFile(filepath.Join(dir, "VERSION"))
	greet, _ := os.ReadFile(filepath.Join(dir, "greet.go"))
	if strings.TrimSpace(string(version)) != "1.4.3" {
		t.Errorf("VERSION = %q, want 1.4.3", version)
	}
	if !strings.Contains(string(greet), `"Hello, " + name`) || strings.Contains(string(greet), "Helo") {
		t.Errorf("greet.go not fixed:\n%s", greet)
	}
}

func must(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
}
