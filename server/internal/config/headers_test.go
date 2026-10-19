package config

import (
	"strings"
	"testing"
)

func TestExpandHeaders(t *testing.T) {
	t.Setenv("FLIT_A", "x")
	t.Setenv("FLIT_EMPTY", "")
	got, err := ExpandHeaders(map[string]string{"A": "${FLIT_A}-${FLIT_A}", "B": "$FLIT_A ${", "C": "${FLIT_EMPTY}"})
	if err != nil || got["A"] != "x-x" || got["B"] != "$FLIT_A ${" || got["C"] != "" {
		t.Fatalf("got %v, %v", got, err)
	}
	if _, err := ExpandHeaders(map[string]string{"A": "${FLIT_NOPE_2}", "B": "${FLIT_NOPE_1}"}); err == nil ||
		err.Error() != "headers use unset environment variables: FLIT_NOPE_1, FLIT_NOPE_2" {
		t.Fatalf("missing: %v", err)
	}
}

func TestProviderHeader(t *testing.T) {
	t.Setenv("FLIT_TEST_TOKEN", "s3cret")
	h, err := Provider{Name: "p"}.Header()
	if err != nil || h.Get("User-Agent") != UserAgent() || !strings.HasPrefix(UserAgent(), "flit/") || len(h) != 1 {
		t.Fatalf("default = %v, %v", h, err)
	}
	h, err = Provider{Name: "p", Headers: map[string]string{"user-agent": "curl/8", "X-Token": "t ${FLIT_TEST_TOKEN}"}}.Header()
	if err != nil || h.Get("User-Agent") != "curl/8" || h.Get("X-Token") != "t s3cret" || len(h) != 2 {
		t.Fatalf("configured = %v, %v", h, err)
	}
	if _, err := (Provider{Name: "p", Headers: map[string]string{"X": "${FLIT_TEST_UNSET_HDR}"}}).Header(); err == nil ||
		!strings.Contains(err.Error(), `provider "p"`) || !strings.Contains(err.Error(), "FLIT_TEST_UNSET_HDR") {
		t.Fatalf("unset = %v", err)
	}
}

func TestProviderHeaderNames(t *testing.T) {
	for name, ok := range map[string]bool{"User-Agent": true, "X-Api_Key.1": true, "Bad Name": false, "Colon:": false, "": false} {
		_, err := Parse([]byte("providers:\n  - name: p\n    base_url: http://localhost/v1\n    headers:\n      \"" + name + "\": v\n"))
		if (err == nil) != ok {
			t.Errorf("header %q: err = %v", name, err)
		}
	}
}
