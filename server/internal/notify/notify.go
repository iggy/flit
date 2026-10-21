// Package notify sends flit's own notifications: cron run results posted
// to an ntfy topic (config notify.ntfy), for when no app is connected.
package notify

import (
	"context"
	"encoding/base64"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

// timeout bounds one post.
const timeout = 15 * time.Second

// Message is one notification.
type Message struct {
	Title string
	Body  string
	// Tags are ntfy tags (emoji shortcodes or words).
	Tags []string
	// High asks for a more insistent notification.
	High bool
}

// Ntfy posts messages to the configured ntfy topic, if any.
type Ntfy struct {
	Config func() config.Config
	HTTP   *http.Client
	Log    *slog.Logger
}

// Send posts m, or does nothing when no topic is configured. Failures are
// logged and returned.
func (n *Ntfy) Send(ctx context.Context, m Message) error {
	cfg := n.Config().Notify
	if cfg.Ntfy == "" {
		return nil
	}
	err := n.post(ctx, cfg, m)
	if err != nil {
		n.Log.Warn("ntfy notification failed", "err", err)
	}
	return err
}

func (n *Ntfy) post(ctx context.Context, cfg config.Notify, m Message) error {
	headers, err := config.ExpandHeaders(cfg.NtfyHeaders)
	if err != nil {
		return fmt.Errorf("notify.ntfy_headers: %w", err)
	}
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, cfg.Ntfy, strings.NewReader(m.Body))
	if err != nil {
		return err
	}
	req.Header.Set("User-Agent", config.UserAgent())
	req.Header.Set("Content-Type", "text/plain; charset=utf-8")
	// ntfy reads headers as ISO-8859-1 unless they are RFC 2047 encoded.
	req.Header.Set("Title", "=?UTF-8?B?"+base64.StdEncoding.EncodeToString([]byte(m.Title))+"?=")
	if len(m.Tags) > 0 {
		req.Header.Set("Tags", strings.Join(m.Tags, ","))
	}
	if m.High {
		req.Header.Set("Priority", "high")
	}
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	client := n.HTTP
	if client == nil {
		client = http.DefaultClient
	}
	res, err := client.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	if res.StatusCode/100 != 2 {
		body, _ := io.ReadAll(io.LimitReader(res.Body, 512))
		return fmt.Errorf("ntfy answered %s: %s", res.Status, strings.TrimSpace(string(body)))
	}
	return nil
}
