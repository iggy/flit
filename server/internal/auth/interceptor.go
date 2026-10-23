package auth

import (
	"context"
	"crypto/subtle"
	"errors"
	"strings"

	"connectrpc.com/connect/v2"
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

// Options configures NewInterceptor.
type Options struct {
	Devices   DeviceTokens
	Public    []string // full procedure names, e.g. "/flit.v1.SystemService/Pair"
	AdminOnly []string
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

func (i *Interceptor) authenticate(ctx context.Context, procedure string, h connect.Header) (context.Context, error) {
	if i.public[procedure] {
		return ctx, nil
	}
	token, ok := strings.CutPrefix(h.Get("Authorization"), "Bearer ")
	if !ok || token == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, errUnauthenticated.Error())
	}
	var p Principal
	switch {
	case subtle.ConstantTimeCompare([]byte(token), i.admin) == 1:
		p = Principal{Admin: true, Name: "admin"}
	case i.devices != nil:
		if p, ok = i.devices.Lookup(ctx, token); !ok {
			return nil, connect.NewError(connect.CodeUnauthenticated, errUnauthenticated.Error())
		}
	default:
		return nil, connect.NewError(connect.CodeUnauthenticated, errUnauthenticated.Error())
	}
	if i.adminOnly[procedure] && !p.Admin {
		return nil, connect.NewError(connect.CodePermissionDenied, errAdminOnly.Error())
	}
	return context.WithValue(ctx, principalKey{}, p), nil
}

// Intercept implements connect.ServerInterceptor. Every RPC requires a valid
// token, except procedures in Options.Public; localhost included. It runs
// before any message is read or written, so a missing credential rejects the
// call from its headers alone.
func (i *Interceptor) Intercept(next connect.ServerFunc) connect.ServerFunc {
	return func(ctx context.Context, spec connect.Spec, stream connect.ServerStream) error {
		var info *connect.CallInfo
		var ok bool
		if info, ok = connect.CallInfoForServerContext(ctx); !ok {
			// Not routed through a *connect.Server (e.g. an in-process or
			// raw invocation); nothing to authenticate against.
			return next(ctx, spec, stream)
		}
		ctx, err := i.authenticate(ctx, spec.Procedure, *info.RequestHeader())
		if err != nil {
			return err
		}
		return next(ctx, spec, stream)
	}
}
