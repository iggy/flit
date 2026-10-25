package llm

import (
	"encoding/json"
	"testing"
)

func TestRepairArguments(t *testing.T) {
	for _, tc := range []struct {
		name, in, want string
		ok             bool
	}{
		{"valid unchanged", `{"a": "x\ty", "b": [1, 2]}`, `{"a": "x\ty", "b": [1, 2]}`, true},
		{"valid whitespace outside strings kept", "{\n\t\"a\": 1\n}", "{\n\t\"a\": 1\n}", true},
		{"raw tab", "{\"content\":\"a\tb\"}", `{"content":"a\tb"}`, true},
		{"raw newlines", "{\"content\":\"line1\nline2\r\n\"}", `{"content":"line1\nline2\r\n"}`, true},
		{"other control chars", "{\"s\":\"\x00\x01\b\f\x1f\"}", `{"s":"\u0000\u0001\b\f\u001f"}`, true},
		{"whitespace outside strings untouched", "{\n\t\"s\": \"a\tb\"\n}", "{\n\t\"s\": \"a\\tb\"\n}", true},
		{"escaped quote before raw tab", "{\"s\":\"say \\\"hi\\\"\tnow\"}", `{"s":"say \"hi\"\tnow"}`, true},
		{"escaped backslash ends string", "{\"s\":\"c:\\\\\",\"t\":\"\t\"}", `{"s":"c:\\","t":"\t"}`, true},
		{"raw tab in key", "{\"a\tb\":1}", `{"a\tb":1}`, true},
		{"hopeless", `{"path": "a.txt"`, `{"path": "a.txt"`, false},
		{"hopeless with tab", "{\"s\":\"a\tb\"", `{"s":"a\tb"`, false},
		{"not json", `path=a.txt`, `path=a.txt`, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got, ok := RepairArguments(tc.in)
			if got != tc.want || ok != tc.ok {
				t.Fatalf("RepairArguments(%q) = %q, %v; want %q, %v", tc.in, got, ok, tc.want, tc.ok)
			}
		})
	}
}

func TestRepairArgumentsKeepsValue(t *testing.T) {
	got, ok := RepairArguments("{\"content\":\"func f() {\n\treturn\n}\n\"}")
	if !ok {
		t.Fatal("not repaired")
	}
	var v struct{ Content string }
	if err := json.Unmarshal([]byte(got), &v); err != nil || v.Content != "func f() {\n\treturn\n}\n" {
		t.Fatalf("decoded %q, %v", v.Content, err)
	}
}

func TestSafeArguments(t *testing.T) {
	for in, want := range map[string]string{
		"":                 `{}`,
		"  ":               `{}`,
		`{"a":1}`:          `{"a":1}`,
		"{\"a\":\"x\ty\"}": `{"a":"x\ty"}`,
		`{"path": "a.txt"`: `{"invalid_json_arguments":"{\"path\": \"a.txt\""}`,
		"{\"s\":\"a\tb\"":  `{"invalid_json_arguments":"{\"s\":\"a\tb\""}`,
	} {
		got := SafeArguments(in)
		if got != want {
			t.Errorf("SafeArguments(%q) = %q, want %q", in, got, want)
		}
		if !json.Valid([]byte(got)) {
			t.Errorf("SafeArguments(%q) = %q is not valid JSON", in, got)
		}
	}
}
