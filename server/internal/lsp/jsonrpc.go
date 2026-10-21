package lsp

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strconv"
	"strings"
	"sync"
)

// conn is a JSON-RPC 2.0 connection with LSP's Content-Length framing.
// Requests from the server are answered by handle; notifications go to
// notify. Both run on the read loop, so they must not block.
type conn struct {
	w      io.Writer
	wmu    sync.Mutex
	handle func(method string, params json.RawMessage) any
	notify func(method string, params json.RawMessage)

	mu      sync.Mutex
	nextID  int64
	pending map[int64]chan response
	err     error         // set once the read loop ends
	done    chan struct{} // closed then
}

type message struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method,omitempty"`
	Params  json.RawMessage `json:"params,omitempty"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   *rpcError       `json:"error,omitempty"`
}

type response struct {
	result json.RawMessage
	err    error
}

type rpcError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

func (e *rpcError) Error() string { return fmt.Sprintf("%s (code %d)", e.Message, e.Code) }

func newConn(r io.Reader, w io.Writer, handle func(string, json.RawMessage) any, notify func(string, json.RawMessage)) *conn {
	c := &conn{w: w, handle: handle, notify: notify, pending: map[int64]chan response{}, done: make(chan struct{})}
	go c.readLoop(bufio.NewReader(r))
	return c
}

// call sends a request and waits for its response or ctx.
func (c *conn) call(ctx context.Context, method string, params, result any) error {
	c.mu.Lock()
	if c.err != nil {
		c.mu.Unlock()
		return c.err
	}
	c.nextID++
	id := c.nextID
	ch := make(chan response, 1)
	c.pending[id] = ch
	c.mu.Unlock()
	defer func() {
		c.mu.Lock()
		delete(c.pending, id)
		c.mu.Unlock()
	}()

	if err := c.send(map[string]any{"jsonrpc": "2.0", "id": id, "method": method, "params": params}); err != nil {
		return err
	}
	select {
	case r := <-ch:
		if r.err != nil {
			return r.err
		}
		if result != nil && len(r.result) > 0 {
			return json.Unmarshal(r.result, result)
		}
		return nil
	case <-c.done:
		return c.err
	case <-ctx.Done():
		return ctx.Err()
	}
}

// notifyServer sends a notification.
func (c *conn) notifyServer(method string, params any) error {
	return c.send(map[string]any{"jsonrpc": "2.0", "method": method, "params": params})
}

func (c *conn) send(v any) error {
	b, err := json.Marshal(v)
	if err != nil {
		return err
	}
	c.wmu.Lock()
	defer c.wmu.Unlock()
	if _, err := fmt.Fprintf(c.w, "Content-Length: %d\r\n\r\n", len(b)); err != nil {
		return err
	}
	_, err = c.w.Write(b)
	return err
}

func (c *conn) readLoop(r *bufio.Reader) {
	var err error
	for {
		var b []byte
		if b, err = readFrame(r); err != nil {
			break
		}
		var m message
		if json.Unmarshal(b, &m) != nil {
			continue // not JSON-RPC; skip it rather than drop the server
		}
		switch {
		case m.Method != "" && m.ID != nil:
			result := c.handle(m.Method, m.Params)
			_ = c.send(map[string]any{"jsonrpc": "2.0", "id": m.ID, "result": result})
		case m.Method != "":
			c.notify(m.Method, m.Params)
		case m.ID != nil:
			id, perr := strconv.ParseInt(string(m.ID), 10, 64)
			if perr != nil {
				continue
			}
			c.mu.Lock()
			ch := c.pending[id]
			c.mu.Unlock()
			if ch != nil {
				r := response{result: m.Result}
				if m.Error != nil {
					r.err = m.Error
				}
				ch <- r
			}
		}
	}
	if errors.Is(err, io.EOF) {
		err = errors.New("language server closed the connection")
	}
	c.mu.Lock()
	c.err = err
	c.mu.Unlock()
	close(c.done)
}

// readFrame reads one Content-Length framed message body.
func readFrame(r *bufio.Reader) ([]byte, error) {
	length := -1
	for {
		line, err := r.ReadString('\n')
		if err != nil {
			return nil, err
		}
		line = strings.TrimRight(line, "\r\n")
		if line == "" {
			break
		}
		name, value, ok := strings.Cut(line, ":")
		if ok && strings.EqualFold(strings.TrimSpace(name), "Content-Length") {
			if length, err = strconv.Atoi(strings.TrimSpace(value)); err != nil {
				return nil, fmt.Errorf("bad Content-Length %q", value)
			}
		}
	}
	if length < 0 {
		return nil, errors.New("message without Content-Length")
	}
	b := make([]byte, length)
	_, err := io.ReadFull(r, b)
	return b, err
}
