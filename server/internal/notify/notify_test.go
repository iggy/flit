package notify

import (
	"context"
	"io"
	"log/slog"
	"mime"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/iggy/flit/server/internal/config"
)

func TestNtfy(t *testing.T) {
	var got *http.Request
	var body string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b, _ := io.ReadAll(r.Body)
		got, body = r, string(b)
	}))
	defer srv.Close()
	t.Setenv("NTFY_TEST_TOKEN", "sekrit")
	cfg := config.Default()
	n := &Ntfy{Config: func() config.Config { return cfg }, Log: slog.New(slog.NewTextHandler(io.Discard, nil))}

	// Off: nothing is sent.
	if err := n.Send(context.Background(), Message{Title: "x"}); err != nil || got != nil {
		t.Fatalf("sent while off: %v", err)
	}

	cfg.Notify = config.Notify{Ntfy: srv.URL + "/topic", NtfyHeaders: map[string]string{"Authorization": "Bearer ${NTFY_TEST_TOKEN}"}}
	if err := n.Send(context.Background(), Message{Title: "morning · needs attention", Body: "CI is red", Tags: []string{"warning"}, High: true}); err != nil {
		t.Fatal(err)
	}
	title, err := new(mime.WordDecoder).DecodeHeader(got.Header.Get("Title"))
	if err != nil || title != "morning · needs attention" {
		t.Errorf("title %q (%v)", title, err)
	}
	if got.URL.Path != "/topic" || body != "CI is red" || got.Header.Get("Authorization") != "Bearer sekrit" ||
		got.Header.Get("Tags") != "warning" || got.Header.Get("Priority") != "high" {
		t.Errorf("request %s %v body %q", got.URL, got.Header, body)
	}

	cfg.Notify.NtfyHeaders = map[string]string{"Authorization": "Bearer ${NTFY_UNSET_VAR_X}"}
	if err := n.Send(context.Background(), Message{Title: "x"}); err == nil {
		t.Error("no error for an unset variable")
	}
}
