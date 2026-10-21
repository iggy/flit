package config

import (
	"bytes"
	"errors"
	"fmt"
	"slices"
	"strings"

	"go.yaml.in/yaml/v3"
)

// DefaultFile returns the commented default config written on first run.
func DefaultFile() string { return strings.TrimLeft(defaultFile, "\n") }

// Update adds the settings the default config has and cur lacks, each with
// its comments from the default file, and returns the new file and the
// dotted paths of what it added. Everything already in cur is kept as it
// is, byte for byte: new text is only inserted, next to where it sits in
// the default file. Flow mappings ({...}) are left alone, so a setting
// missing from one isn't added.
func Update(cur []byte) (out []byte, added []string, err error) {
	if _, err := Parse(cur); err != nil {
		return nil, nil, err
	}
	def := DefaultFile()
	defRoot, err := mappingRoot([]byte(def))
	if err != nil || defRoot == nil {
		panic(fmt.Sprintf("default config: %v", err)) // tested
	}
	userRoot, err := mappingRoot(cur)
	if err != nil {
		return nil, nil, err
	}
	if userRoot == nil {
		// Nothing but comments: append the whole default.
		for i := 0; i < len(defRoot.Content); i += 2 {
			added = append(added, defRoot.Content[i].Value)
		}
		out = slices.Clone(cur)
		if len(out) > 0 && !bytes.HasSuffix(out, []byte("\n")) {
			out = append(out, '\n')
		}
		if len(out) > 0 {
			out = append(out, '\n')
		}
		return append(out, def...), added, nil
	}

	u := &updater{def: lines(def), user: lines(string(cur)), inserts: map[int][]string{}}
	u.merge(defRoot, userRoot, "", len(u.def), len(u.user))
	if len(u.added) == 0 {
		return cur, nil, nil
	}
	var b strings.Builder
	for i := 0; i <= len(u.user); i++ {
		for _, text := range u.inserts[i] {
			b.WriteString(text)
		}
		if i < len(u.user) {
			b.WriteString(u.user[i])
			b.WriteString("\n")
		}
	}
	out = []byte(b.String())
	if _, err := Parse(out); err != nil {
		return nil, nil, fmt.Errorf("updated config doesn't parse (please report this): %w", err)
	}
	return out, u.added, nil
}

// updater inserts default blocks into the user's lines.
type updater struct {
	def, user []string
	// inserts maps a user line index to the text to put before it
	// (len(user) means the end), in default-file order.
	inserts map[int][]string
	added   []string
}

// merge adds what def has and user lacks. defEnd and userEnd are the
// (0-based, exclusive) line where each mapping's text ends.
func (u *updater) merge(def, user *yaml.Node, prefix string, defEnd, userEnd int) {
	userKeys := map[string]int{} // key -> index in user.Content
	for i := 0; i < len(user.Content); i += 2 {
		userKeys[user.Content[i].Value] = i
	}
	indent := user.Content[0].Column - def.Content[0].Column
	for i := 0; i < len(def.Content); i += 2 {
		key, val := def.Content[i], def.Content[i+1]
		path := prefix + key.Value
		if j, ok := userKeys[key.Value]; ok {
			uval := user.Content[j+1]
			if isBlockMapping(val) && isBlockMapping(uval) {
				u.merge(val, uval, path+".", u.defNext(def, i, defEnd), u.userNext(user, j, userEnd))
			}
			continue
		}
		start := blockStart(u.def, key.Line-1)
		block := u.def[start:u.defNext(def, i, defEnd)]
		for len(block) > 0 && blank(block[len(block)-1]) {
			block = block[:len(block)-1]
		}
		text := reindent(block, indent) + "\n"
		// Insert before the next default sibling the user has, with the
		// blank line the default has after it; else after the end of the
		// user's mapping, with the blank line the default has before it.
		at := -1
		for k := i + 2; k < len(def.Content); k += 2 {
			if j, ok := userKeys[def.Content[k].Value]; ok {
				at = blockStart(u.user, user.Content[j].Line-1)
				break
			}
		}
		if at >= 0 {
			if next := u.defNext(def, i, defEnd); next > 0 && blank(u.def[next-1]) {
				text += "\n"
			}
		} else {
			at = userEnd
			for at > 0 && blank(u.user[at-1]) {
				at--
			}
			if start > 0 && blank(u.def[start-1]) {
				text = "\n" + text
			}
		}
		u.inserts[at] = append(u.inserts[at], text)
		u.added = append(u.added, path)
	}
}

// defNext is where the text of def's i'th key ends: where the next key's
// block starts, or end.
func (u *updater) defNext(def *yaml.Node, i, end int) int {
	if i+2 < len(def.Content) {
		return blockStart(u.def, def.Content[i+2].Line-1)
	}
	return end
}

// userNext is defNext for the user's file. Keys there may be in any order,
// so it's the nearest key that starts after this one.
func (u *updater) userNext(user *yaml.Node, j, end int) int {
	next := end
	for k := 0; k < len(user.Content); k += 2 {
		if l := user.Content[k].Line - 1; l > user.Content[j].Line-1 && l < next {
			next = blockStart(u.user, l)
		}
	}
	return next
}

// blockStart is the first line of the block for the key on line i: the key
// line plus the prose comment lines right above it. Commented-out examples
// ("#  - name: x", two or more spaces after #) belong to the key above.
func blockStart(lines []string, i int) int {
	for i > 0 {
		t := strings.TrimSpace(lines[i-1])
		rest, ok := strings.CutPrefix(t, "#")
		if !ok || strings.HasPrefix(rest, "  ") || (rest != "" && rest[0] != ' ') {
			break
		}
		i--
	}
	return i
}

// reindent shifts lines right (n > 0) or left by n spaces.
func reindent(lines []string, n int) string {
	out := make([]string, len(lines))
	for i, l := range lines {
		switch {
		case blank(l):
			out[i] = ""
		case n > 0:
			out[i] = strings.Repeat(" ", n) + l
		default:
			out[i] = l[min(-n, len(l)-len(strings.TrimLeft(l, " "))):]
		}
	}
	return strings.Join(out, "\n")
}

func blank(s string) bool { return strings.TrimSpace(s) == "" }

func isBlockMapping(n *yaml.Node) bool {
	return n.Kind == yaml.MappingNode && n.Style&yaml.FlowStyle == 0 && len(n.Content) > 0
}

// mappingRoot parses data and returns its top-level mapping, or nil when
// the document is empty.
func mappingRoot(data []byte) (*yaml.Node, error) {
	var doc yaml.Node
	if err := yaml.Unmarshal(data, &doc); err != nil {
		return nil, err
	}
	if doc.Kind == 0 || len(doc.Content) == 0 {
		return nil, nil
	}
	root := doc.Content[0]
	if root.Kind == yaml.ScalarNode && root.Tag == "!!null" {
		return nil, nil
	}
	if root.Kind != yaml.MappingNode {
		return nil, errors.New("config must be a YAML mapping")
	}
	if root.Style&yaml.FlowStyle != 0 {
		return nil, errors.New("can't update a config written as a flow mapping ({...})")
	}
	if len(root.Content) == 0 {
		return nil, nil
	}
	return root, nil
}

// lines splits s into lines without their newlines.
func lines(s string) []string {
	s = strings.ReplaceAll(s, "\r\n", "\n")
	s = strings.TrimSuffix(s, "\n")
	if s == "" {
		return nil
	}
	return strings.Split(s, "\n")
}
