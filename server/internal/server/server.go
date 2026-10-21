// Package server runs flit's HTTP API server and rebinds it when the listen
// address or TLS settings change, without restarting the process.
package server

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"sync"
	"time"

	"connectrpc.com/connect"

	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/auth"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/cronsvc"
	"github.com/iggy/flit/server/internal/devices"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/modelsvc"
	"github.com/iggy/flit/server/internal/scheduler"
	"github.com/iggy/flit/server/internal/sessionsvc"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/system"
)

// drainTimeout bounds how long an old listener may finish in-flight requests
// after a rebind.
const drainTimeout = 30 * time.Second

// Deps are the services behind the API. Nil fields disable what they back.
type Deps struct {
	Sessions *agent.Manager
	Devices  *devices.Registry
	Config   func() config.Config
	Catalog  *models.Catalog
	RolesDir func() string
	// Store keeps model favorites and recents; nil leaves them out.
	Store *store.Store
	// Crons runs cron jobs; nil leaves CronService out.
	Crons *scheduler.Scheduler
}

// NewHandler returns the API handler. Every RPC requires the admin token or
// a device token, except pairing.
func NewHandler(adminToken string, d Deps) http.Handler {
	authOpts := auth.Options{Public: system.Public, AdminOnly: system.AdminOnly}
	if d.Devices != nil {
		authOpts.Devices = d.Devices
	}
	opts := connect.WithInterceptors(auth.NewInterceptor(adminToken, authOpts))
	mux := http.NewServeMux()
	mux.Handle(flitv1connect.NewSystemServiceHandler(&system.Service{Devices: d.Devices, Config: d.Config}, opts))
	if d.Sessions != nil {
		mux.Handle(flitv1connect.NewSessionServiceHandler(&sessionsvc.Service{M: d.Sessions}, opts))
		mux.Handle(flitv1connect.NewProjectServiceHandler(&sessionsvc.Projects{M: d.Sessions}, opts))
	}
	if d.Catalog != nil {
		mux.Handle(flitv1connect.NewModelServiceHandler(&modelsvc.Models{Catalog: d.Catalog, Store: d.Store}, opts))
	}
	if d.RolesDir != nil {
		mux.Handle(flitv1connect.NewRoleServiceHandler(&modelsvc.Roles{Dir: d.RolesDir}, opts))
	}
	if d.Crons != nil {
		mux.Handle(flitv1connect.NewCronServiceHandler(&cronsvc.Service{S: d.Crons}, opts))
	}
	return mux
}

// Server serves an http.Handler on the address and TLS settings of the most
// recently applied config.
type Server struct {
	handler http.Handler
	log     *slog.Logger

	mu  sync.Mutex
	cur *instance
}

type instance struct {
	listen string
	tls    config.TLS
	srv    *http.Server
	addr   net.Addr
	done   chan struct{}
}

// New returns a Server for handler. Call Apply to start it.
func New(handler http.Handler, log *slog.Logger) *Server {
	return &Server{handler: handler, log: log}
}

// Apply starts serving with cfg. If the listen address or TLS settings differ
// from what is being served, it binds the new listener first and only then
// drains the old one, so a bad address leaves the old listener running and
// returns an error.
func (s *Server) Apply(cfg config.Config) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.cur != nil && s.cur.listen == cfg.Listen && s.cur.tls == cfg.TLS {
		return nil
	}
	next, err := s.start(cfg)
	if err != nil {
		return err
	}
	if old := s.cur; old != nil {
		s.log.Info("rebinding API server", "from", old.addr, "to", next.addr)
		go s.drain(old)
	}
	s.cur = next
	return nil
}

func (s *Server) start(cfg config.Config) (*instance, error) {
	ln, err := net.Listen("tcp", cfg.Listen)
	if err != nil {
		return nil, fmt.Errorf("listen on %s: %w", cfg.Listen, err)
	}

	protocols := new(http.Protocols)
	protocols.SetHTTP1(true)
	protocols.SetHTTP2(true)
	protocols.SetUnencryptedHTTP2(true) // h2c, for gRPC clients over plain HTTP.
	srv := &http.Server{
		Handler:           s.handler,
		Protocols:         protocols,
		ReadHeaderTimeout: 10 * time.Second,
		ErrorLog:          slog.NewLogLogger(s.log.Handler(), slog.LevelWarn),
	}
	// Streams (Attach) never finish on their own; end them when this
	// listener shuts down so Shutdown doesn't wait out its timeout. Clients
	// reattach from the last seq they saw.
	base, cancelStreams := context.WithCancel(context.Background())
	srv.BaseContext = func(net.Listener) context.Context { return base }
	srv.RegisterOnShutdown(cancelStreams)
	scheme := "http"
	if cfg.TLS.Enabled() {
		certs := &certLoader{certFile: cfg.TLS.CertFile, keyFile: cfg.TLS.KeyFile}
		if _, err := certs.get(); err != nil {
			ln.Close()
			return nil, err
		}
		srv.TLSConfig = &tls.Config{
			MinVersion:     tls.VersionTLS12,
			GetCertificate: func(*tls.ClientHelloInfo) (*tls.Certificate, error) { return certs.get() },
		}
		ln = tls.NewListener(ln, srv.TLSConfig)
		scheme = "https"
	}

	inst := &instance{listen: cfg.Listen, tls: cfg.TLS, srv: srv, addr: ln.Addr(), done: make(chan struct{})}
	go func() {
		defer close(inst.done)
		if err := srv.Serve(ln); err != nil && !errors.Is(err, http.ErrServerClosed) {
			s.log.Error("API server stopped", "addr", inst.addr, "err", err)
		}
	}()
	s.log.Info("API server listening", "url", fmt.Sprintf("%s://%s", scheme, inst.addr))
	return inst, nil
}

func (s *Server) drain(inst *instance) {
	ctx, cancel := context.WithTimeout(context.Background(), drainTimeout)
	defer cancel()
	if err := inst.srv.Shutdown(ctx); err != nil {
		inst.srv.Close()
	}
	<-inst.done
}

// Addr returns the address currently being served, or nil before Apply.
func (s *Server) Addr() net.Addr {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.cur == nil {
		return nil
	}
	return s.cur.addr
}

// Shutdown gracefully stops the server.
func (s *Server) Shutdown(ctx context.Context) error {
	s.mu.Lock()
	inst := s.cur
	s.cur = nil
	s.mu.Unlock()
	if inst == nil {
		return nil
	}
	err := inst.srv.Shutdown(ctx)
	<-inst.done
	return err
}

// certLoader reloads the key pair when either file changes on disk, so
// renewed certificates are picked up without a rebind.
type certLoader struct {
	certFile, keyFile string

	mu      sync.Mutex
	cert    *tls.Certificate
	modTime [2]time.Time
}

func (c *certLoader) get() (*tls.Certificate, error) {
	var mt [2]time.Time
	for i, f := range []string{c.certFile, c.keyFile} {
		fi, err := os.Stat(f)
		if err != nil {
			return nil, fmt.Errorf("tls: %w", err)
		}
		mt[i] = fi.ModTime()
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.cert != nil && mt == c.modTime {
		return c.cert, nil
	}
	cert, err := tls.LoadX509KeyPair(c.certFile, c.keyFile)
	if err != nil {
		if c.cert != nil {
			return c.cert, nil // mid-renewal; keep serving the last good pair
		}
		return nil, fmt.Errorf("tls: %w", err)
	}
	c.cert, c.modTime = &cert, mt
	return c.cert, nil
}
