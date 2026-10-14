package auth

import (
	"context"
	"crypto/subtle"
	"errors"
	"net/http"
	"strings"

	"connectrpc.com/connect"
)

var errUnauthenticated = errors.New("missing or invalid token; send \"Authorization: Bearer <token>\"")

// Interceptor rejects every RPC that doesn't carry the token as
// "Authorization: Bearer <token>". It applies to all callers, localhost
// included.
type Interceptor struct {
	token []byte
}

// NewInterceptor returns an Interceptor that accepts token.
func NewInterceptor(token string) *Interceptor {
	return &Interceptor{token: []byte(token)}
}

var _ connect.Interceptor = (*Interceptor)(nil)

func (i *Interceptor) check(h http.Header) error {
	got, ok := strings.CutPrefix(h.Get("Authorization"), "Bearer ")
	if !ok || subtle.ConstantTimeCompare([]byte(got), i.token) != 1 {
		return connect.NewError(connect.CodeUnauthenticated, errUnauthenticated)
	}
	return nil
}

// WrapUnary implements connect.Interceptor.
func (i *Interceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		if req.Spec().IsClient {
			return next(ctx, req)
		}
		if err := i.check(req.Header()); err != nil {
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
		if err := i.check(conn.RequestHeader()); err != nil {
			return err
		}
		return next(ctx, conn)
	}
}
