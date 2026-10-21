# Language server diagnostics

After the `write` or `patch` tool changes a file, flit asks the file's
language server what is wrong with it and adds the answer to the tool
result, so the model sees its type errors right away instead of finding
them later with a build:

```
applied 1 edit(s) to internal/tools/todo.go

Diagnostics:
internal/tools/todo.go:61:14 error: cannot use "x" (untyped string constant) as int value in variable declaration
internal/tools/todo.go:12:2 warning: unusedparams: unused parameter
(+3 more)
```

- Only the edited file is reported, errors first, then warnings (hints and
  info are left out unless `severity` asks for them), at most `max_lines`
  lines plus a count of the rest. Messages are cut to their first line.
- A clean file adds nothing: the model gets the plain result, the same as
  with no language server. That costs no tokens on the common path.
- The edit never fails or waits long because of a language server. A
  missing command, a server that crashes or one that doesn't answer within
  `wait_timeout` (starting it included) just means no diagnostics this
  time.

## Servers

One process runs per server for the whole flit server, shared by every
session and project. When a file is checked, the nearest directory above
it holding one of the server's root markers (e.g. `go.mod`) is added to
the server as a workspace folder (or, without one, the session's working
directory). Servers start on the first edit of a file they handle, stop
after `idle_timeout` without use, restart when their config changes, and
are killed together with anything they started when flit exits.

Built in, used when their command is on `PATH`:

| name | command | files | root markers |
|---|---|---|---|
| gopls | `gopls` | .go | go.mod, go.work |
| rust-analyzer | `rust-analyzer` | .rs | Cargo.toml |
| basedpyright | `basedpyright-langserver --stdio` | .py, .pyi | pyproject.toml, pyrightconfig.json, setup.py, setup.cfg, requirements.txt |
| pyright | `pyright-langserver --stdio` | .py, .pyi | (same) |
| typescript-language-server | `typescript-language-server --stdio` | .ts, .mts, .cts, .tsx, .js, .mjs, .cjs, .jsx | tsconfig.json, jsconfig.json, package.json |
| clangd | `clangd` | .c, .h, .cc, .cpp, .cxx, .hh, .hpp, .hxx | compile_commands.json, compile_flags.txt, .clangd |

rust-analyzer reports its own diagnostics as soon as a file is opened;
`cargo check` results come later than `wait_timeout` allows and aren't
waited for.

## Config

```yaml
lsp:
  enabled: true
  idle_timeout: 10m
  wait_timeout: 3s
  debounce: 300ms      # report once diagnostics stop changing this long
  severity: warning    # error, warning, info or hint
  max_lines: 10
  servers:
    # A new server.
    - name: zls
      command: zls
      args: []
      env: {}
      languages: {zig: [.zig, .zon]}   # LSP language id -> extensions
      root_markers: [build.zig]
      init_options: {}                 # sent as initializationOptions
    # Change a built-in one by naming it: what you set wins (env and
    # init_options key by key, an explicit [] clears a list), the rest is
    # kept from the built-in.
    - name: gopls
      init_options: {staticcheck: true}
    # Turn a built-in one off.
    - name: clangd
      enabled: false
```

Each file goes to the first server, configured ones before built-in ones,
that handles its extension and whose command is found. Changes apply
live, like the rest of the config.
