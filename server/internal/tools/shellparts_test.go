package tools

import "testing"

func TestShellParts(t *testing.T) {
	type want struct {
		name   string
		masked bool
	}
	cases := []struct {
		cmd  string
		want []want
	}{
		{"a && b", []want{{"a", false}, {"b", false}}},
		{"a | b", []want{{"a", true}, {"b", false}}},
		{"a || b", []want{{"a", true}, {"b", true}}},
		{"a; b", []want{{"a", true}, {"b", false}}},
		{"(a && b) | c", []want{{"a", true}, {"b", true}, {"c", false}}},
		{"for i in 1; do a; done", []want{{"a", true}}},
	}
	for _, c := range cases {
		parts, _, ok := ShellParts(c.cmd)
		if !ok || len(parts) != len(c.want) {
			t.Fatalf("%q: %+v %v", c.cmd, parts, ok)
		}
		for i, w := range c.want {
			if parts[i].Name != w.name || parts[i].Masked != w.masked {
				t.Errorf("%q part %d: %+v, want %+v", c.cmd, i, parts[i], w)
			}
		}
	}

	parts, exports, ok := ShellParts(`export A=1; B=2; C="x y" D=$E run --flag`)
	if !ok || len(parts) != 1 || len(parts[0].Assigns) != 2 || len(exports) != 2 {
		t.Fatalf("%+v %+v %v", parts, exports, ok)
	}
	if a := parts[0].Assigns; a[0].Value != "x y" || !a[0].Literal || a[1].Literal {
		t.Errorf("%+v", a)
	}
	if exports[0].Name != "A" || exports[1].Name != "B" {
		t.Errorf("%+v", exports)
	}
	if _, _, ok := ShellParts("if ("); ok {
		t.Error("parsed garbage")
	}
}
