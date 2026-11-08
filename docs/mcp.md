# MCP servers

flit can use tools from [Model Context Protocol](https://modelcontextprotocol.io)
servers. They are configured in the YAML config, never an `mcp.json`. For
the short version, see the [README](../README.md#mcp-servers).

Each server has either a `command` (a subprocess, over stdio) or a `url` (a
remote server, over streamable HTTP, falling back to legacy SSE), with
optional `headers` for things like auth (`${VAR}` in a header value is
read from the environment, so tokens needn't sit in the config):

```yaml
mcp_servers:
  - name: fetch
    command: uvx
    args: [mcp-server-fetch]
    enabled: true    # on for new sessions
  - name: docs
    url: https://example.com/mcp
    headers:
      Authorization: Bearer ${DOCS_MCP_TOKEN}
```

Each session turns servers on or off at runtime (from the app); only
enabled servers' tools are sent to the model.

## Servers that need a browser sign-in (OAuth)

Remote servers that need a browser sign-in work too: run
`flit mcp login NAME` on the machine flit runs on. It registers flit with
the server's authorization server, opens the sign-in page, and saves the
token (refreshed automatically) in `mcp-oauth.yaml` in the data dir. When
the browser is on another machine, paste the address it lands on into
the terminal. Servers that don't support dynamic client registration take
a client you registered by hand, with redirect URL
`http://127.0.0.1:7434/callback` (change the port with `--port`):

```yaml
mcp_servers:
  - name: tracker
    url: https://mcp.example.com/mcp
    oauth:
      client_id: my-client-id
      client_secret: ${TRACKER_SECRET}   # optional; ${VAR} from the environment
      scopes: [read]                     # optional; replaces what the server asks for
```

```sh
flit mcp list            # which servers are signed in
flit mcp logout NAME     # forget a sign-in
```

## Reliability

flit resumes dropped event streams, reconnects when a server restarts or
forgets the session, picks up a server's new tools when it says they
changed, and logs what servers log.
