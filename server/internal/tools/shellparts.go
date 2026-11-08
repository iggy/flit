package tools

// ShellArg is one argument of a ShellPart, after quote removal. Literal is
// false when its value depends on expansion.
type ShellArg struct {
	Value   string
	Literal bool
}

// ShellAssign is a variable assignment in a command.
type ShellAssign struct {
	Name    string
	Value   string
	Literal bool
}

// ShellPart is one simple command of a command line, split the way the
// shell rules split it.
type ShellPart struct {
	Name string
	Args []ShellArg
	// Assigns are the FOO=bar prefixes of this part.
	Assigns []ShellAssign
	// Masked says this part's exit status doesn't decide the command's: the
	// left of a pipe or ||, anything before a ;, inside a loop or an if.
	Masked bool
}

// ShellParts splits cmd into its simple commands, in order, and returns the
// variables set for the whole command (export FOO=bar, FOO=bar on its own).
// ok is false when cmd can't be parsed.
func ShellParts(cmd string) (parts []ShellPart, exports []ShellAssign, ok bool) {
	p := parseShell(cmd)
	if p.failed {
		return nil, nil, false
	}
	for _, s := range p.segments {
		part := ShellPart{Name: s.name, Assigns: s.assigns, Masked: s.masked}
		for _, a := range s.args {
			part.Args = append(part.Args, ShellArg{Value: a.val, Literal: a.lit})
		}
		parts = append(parts, part)
	}
	return parts, p.exports, true
}
