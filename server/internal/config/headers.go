package config

import (
	"errors"
	"fmt"
	"net/http"
	"os"
	"regexp"
	"slices"
	"strings"

	"github.com/iggy/flit/server/internal/buildinfo"
)

// UserAgent is sent to providers unless their headers set one. Some
// (Nous Portal, behind Cloudflare) refuse Go's default Go-http-client.
func UserAgent() string { return "flit/" + buildinfo.Get().Version }

// envRef is a ${VAR} reference in a header value.
var envRef = regexp.MustCompile(`\$\{([A-Za-z_][A-Za-z0-9_]*)\}`)

// headerName is an HTTP header field name (an RFC 9110 token).
var headerName = regexp.MustCompile("^[!#$%&'*+.^_`|~0-9A-Za-z-]+$")

// ExpandHeaders replaces ${VAR} in header values with the environment
// variable, so secrets needn't sit in the config. A variable that isn't
// set is an error. Nothing else (a bare $ included) is touched.
func ExpandHeaders(in map[string]string) (map[string]string, error) {
	out := make(map[string]string, len(in))
	var missing []string
	for k, v := range in {
		out[k] = envRef.ReplaceAllStringFunc(v, func(ref string) string {
			name := envRef.FindStringSubmatch(ref)[1]
			val, ok := os.LookupEnv(name)
			if !ok {
				missing = append(missing, name)
			}
			return val
		})
	}
	if len(missing) > 0 {
		slices.Sort(missing)
		return nil, fmt.Errorf("headers use unset environment variables: %s", strings.Join(slices.Compact(missing), ", "))
	}
	return out, nil
}

// ExpandEnv replaces ${VAR} in s like ExpandHeaders does.
func ExpandEnv(s string) (string, error) {
	out, err := ExpandHeaders(map[string]string{"": s})
	if err != nil {
		return "", errors.New(strings.Replace(err.Error(), "headers use", "uses", 1))
	}
	return out[""], nil
}

// Header returns the headers to send with every request to the provider:
// flit's User-Agent, then the configured headers (expanded), which win.
// Authorization from the API key is added by the clients and is also
// overridden by a configured one.
func (p Provider) Header() (http.Header, error) {
	expanded, err := ExpandHeaders(p.Headers)
	if err != nil {
		return nil, fmt.Errorf("provider %q: %w", p.Name, err)
	}
	h := http.Header{"User-Agent": {UserAgent()}}
	for k, v := range expanded {
		h.Set(k, v)
	}
	return h, nil
}
