package auth

import (
	"context"
	"crypto/subtle"
	"errors"
	"net/http"
	"strings"

	"connectrpc.com/connect"
)

var (
	errUnauthenticated = errors.New("missing or invalid token; send \"Authorization: Bearer <token>\"")
	errAdminOnly       = errors.New("this call needs the admin token (see \"flit token\"), not a device token")
)

// Principal is who a request is from.
type Principal struct {
	// Admin is true for the server's admin token.
	Admin bool
	// DeviceID and Name identify a paired device; Name is "admin" for the
	// admin token.
	DeviceID string
	Name     string
}

// DeviceTokens resolves device tokens. Nil means only the admin token works.
type DeviceTokens interface {
	Lookup(ctx context.Context, token string) (Principal, bool)
}

type principalKey struct{}

// FromContext returns the caller of the current RPC.
func FromContext(ctx context.Context) (Principal, bool) {
	p, ok := ctx.Value(principalKey{}).(Principal)
	return p, ok
}

// Interceptor rejects every RPC that doesn't carry a valid token as
// "Authorization: Bearer <token>", localhost included. Procedures in public
// need no token; procedures in adminOnly need the admin token.
type Interceptor struct {
	admin     []byte
	devices   DeviceTokens
	public    map[string]bool
	adminOnly map[string]bool
}

// Options configures NewInterceptor.
type Options struct {
	Devices   DeviceTokens
	Public    []string // full procedure names, e.g. "/flit.v1.SystemService/Pair"
	AdminOnly []string
}

// NewInterceptor returns an Interceptor that accepts adminToken and, if
// o.Devices is set, device tokens.
func NewInterceptor(adminToken string, o Options) *Interceptor {
	set := func(names []string) map[string]bool {
		m := map[string]bool{}
		for _, n := range names {
			m[n] = true
		}
		return m
	}
	return &Interceptor{admin: []byte(adminToken), devices: o.Devices, public: set(o.Public), adminOnly: set(o.AdminOnly)}
}

var _ connect.Interceptor = (*Interceptor)(nil)

func (i *Interceptor) authenticate(ctx context.Context, procedure string, h http.Header) (context.Context, error) {
	if i.public[procedure] {
		return ctx, nil
	}
	token, ok := strings.CutPrefix(h.Get("Authorization"), "Bearer ")
	if !ok || token == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, errUnauthenticated)
	}
	var p Principal
	switch {
	case subtle.ConstantTimeCompare([]byte(token), i.admin) == 1:
		p = Principal{Admin: true, Name: "admin"}
	case i.devices != nil:
		if p, ok = i.devices.Lookup(ctx, token); !ok {
			return nil, connect.NewError(connect.CodeUnauthenticated, errUnauthenticated)
		}
	default:
		return nil, connect.NewError(connect.CodeUnauthenticated, errUnauthenticated)
	}
	if i.adminOnly[procedure] && !p.Admin {
		return nil, connect.NewError(connect.CodePermissionDenied, errAdminOnly)
	}
	return context.WithValue(ctx, principalKey{}, p), nil
}

// WrapUnary implements connect.Interceptor.
func (i *Interceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		if req.Spec().IsClient {
			return next(ctx, req)
		}
		ctx, err := i.authenticate(ctx, req.Spec().Procedure, req.Header())
		if err != nil {
			return nil, err
		}
		return next(ctx, req)
	}
}

// WrapStreamingClient implements connect.Interceptor. Client streams are not
// checked; this interceptor guards handlers.
func (i *Interceptor) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return next
}

// WrapStreamingHandler implements connect.Interceptor.
func (i *Interceptor) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return func(ctx context.Context, conn connect.StreamingHandlerConn) error {
		ctx, err := i.authenticate(ctx, conn.Spec().Procedure, conn.RequestHeader())
		if err != nil {
			return err
		}
		return next(ctx, conn)
	}
}
