package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"github.com/iggy/flit/server/internal/mcpclient"
)

const mcpUsage = `Usage:
  flit mcp list                 list configured MCP servers and their sign-ins
  flit mcp login NAME [flags]   sign in to a url server that needs OAuth
  flit mcp logout NAME          forget a server's sign-in

login opens the server's sign-in page in a browser and waits for it to
redirect to http://127.0.0.1:PORT/callback. When the browser is on another
machine, paste the address it lands on (even if the page fails to load).
The sign-in is saved in the data dir (mcp-oauth.yaml) and a running flit
server uses it on its next try, without a restart.

Flags:
`

func mcpCmd(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, args []string, defaultConfig string) error {
	if len(args) == 0 {
		fmt.Fprint(stderr, mcpUsage)
		return errors.New("usage: flit mcp list|login|logout")
	}
	sub, args := args[0], args[1:]
	fs := flag.NewFlagSet("mcp "+sub, flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprint(stderr, mcpUsage)
		fs.PrintDefaults()
	}
	configPath := fs.String("config", defaultConfig, "config file")
	dataDirFlag := fs.String("data-dir", "", "data directory")
	port := fs.Int("port", mcpclient.DefaultLoginPort, "loopback port for the sign-in redirect (login only)")
	noBrowser := fs.Bool("no-browser", false, "print the sign-in URL without opening a browser (login only)")
	// Flags may come before or after NAME.
	var name string
	if len(args) > 0 && len(args[0]) > 0 && args[0][0] != '-' {
		name, args = args[0], args[1:]
	}
	if err := fs.Parse(args); err != nil {
		return err
	}
	if name == "" && fs.NArg() > 0 {
		name = fs.Arg(0)
	}

	cfg, err := loadConfig(*configPath)
	if err != nil {
		return err
	}
	dataDir, err := resolveDataDir(*dataDirFlag, cfg)
	if err != nil {
		return err
	}
	tokens := mcpclient.NewTokenStore(filepath.Join(dataDir, mcpclient.TokenFileName))

	switch sub {
	case "list":
		if len(cfg.MCPServers) == 0 {
			fmt.Fprintf(stdout, "No MCP servers in %s.\n", *configPath)
		}
		for _, s := range cfg.MCPServers {
			switch {
			case s.URL == "":
				fmt.Fprintf(stdout, "%s\tcommand: %s\n", s.Name, s.Command)
			case tokens.SignedIn(s.Name, s.URL):
				fmt.Fprintf(stdout, "%s\t%s\tsigned in\n", s.Name, s.URL)
			default:
				fmt.Fprintf(stdout, "%s\t%s\n", s.Name, s.URL)
			}
		}
		return nil
	case "login", "logout":
		if name == "" {
			return fmt.Errorf("usage: flit mcp %s NAME", sub)
		}
		srv, ok := cfg.MCPServer(name)
		if !ok {
			return fmt.Errorf("no MCP server named %q in %s", name, *configPath)
		}
		if sub == "logout" {
			had, err := tokens.Delete(name)
			if err != nil {
				return err
			}
			if !had {
				fmt.Fprintf(stdout, "%s had no sign-in.\n", name)
			} else {
				fmt.Fprintf(stdout, "Signed out of %s. A running flit server keeps its current connection until it restarts.\n", name)
			}
			return nil
		}
		opts := mcpclient.LoginOptions{Port: *port, Out: stdout, In: stdin}
		if !*noBrowser {
			opts.Open = openBrowser
		}
		n, err := mcpclient.Login(ctx, srv, tokens, opts)
		if err != nil {
			return err
		}
		fmt.Fprintf(stdout, "\nSigned in to %s (%d tools).\n", name, n)
		return nil
	default:
		fmt.Fprint(stderr, mcpUsage)
		return fmt.Errorf("unknown mcp command %q", sub)
	}
}

// openBrowser opens url in the desktop's browser, if there is one.
func openBrowser(url string) error {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "darwin":
		cmd = exec.Command("open", url)
	case "windows":
		cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", url)
	default:
		if os.Getenv("DISPLAY") == "" && os.Getenv("WAYLAND_DISPLAY") == "" {
			return errors.New("no display")
		}
		cmd = exec.Command("xdg-open", url)
	}
	cmd.Stdout, cmd.Stderr = nil, nil
	return cmd.Start()
}
