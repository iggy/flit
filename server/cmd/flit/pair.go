package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"

	"connectrpc.com/connect"
	qrcode "github.com/skip2/go-qrcode"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/auth"
	"github.com/iggy/flit/server/internal/config"
)

// adminClient returns a SystemService client for the server described by
// the config on this machine, authenticated with its admin token.
func adminClient(configPath, dataDirFlag string) (flitv1connect.SystemServiceClient, error) {
	cfg, err := loadConfig(configPath)
	if err != nil {
		return nil, err
	}
	dataDir, err := resolveDataDir(dataDirFlag, cfg)
	if err != nil {
		return nil, err
	}
	token, err := auth.ReadToken(dataDir)
	if err != nil {
		return nil, fmt.Errorf("read admin token from %s: %w (is this the machine running \"flit serve\"?)", dataDir, err)
	}
	base, hc := localURL(cfg)
	return flitv1connect.NewSystemServiceClient(hc, base, connect.WithInterceptors(bearerInterceptor(token))), nil
}

// localURL is how this machine reaches its own server: the listen address,
// with wildcard hosts replaced by loopback. Over TLS the certificate is for
// the public name, not loopback, so verification is skipped for this local
// connection only.
func localURL(cfg config.Config) (string, *http.Client) {
	host, port, _ := net.SplitHostPort(cfg.Listen)
	if ip := net.ParseIP(host); host == "" || (ip != nil && ip.IsUnspecified()) {
		host = "127.0.0.1"
	}
	u := url.URL{Scheme: "http", Host: net.JoinHostPort(host, port)}
	hc := &http.Client{Timeout: 10 * time.Second}
	if cfg.TLS.Enabled() {
		u.Scheme = "https"
		hc.Transport = &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}} //nolint:gosec // loopback to our own server
	}
	return u.String(), hc
}

type bearerInterceptor string

func (b bearerInterceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		req.Header().Set("Authorization", "Bearer "+string(b))
		return next(ctx, req)
	}
}

func (b bearerInterceptor) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return next
}

func (b bearerInterceptor) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return next
}

// PairingURI is what the QR code holds. The app parses it.
func PairingURI(serverURL, code string) string {
	q := url.Values{"server": {serverURL}, "code": {code}}
	return "flit://pair?" + q.Encode()
}

func pair(ctx context.Context, stdout io.Writer, configPath, dataDirFlag, urlOverride string) error {
	c, err := adminClient(configPath, dataDirFlag)
	if err != nil {
		return err
	}
	res, err := c.CreatePairingCode(ctx, connect.NewRequest(&flitv1.CreatePairingCodeRequest{}))
	if err != nil {
		return fmt.Errorf("ask the server for a pairing code (is \"flit serve\" running?): %w", err)
	}
	server := res.Msg.ServerUrl
	if urlOverride != "" {
		server = strings.TrimSuffix(urlOverride, "/")
	}
	qr, err := qrcode.New(PairingURI(server, res.Msg.Code), qrcode.Medium)
	if err != nil {
		return err
	}
	mins := int(time.Until(res.Msg.ExpireTime.AsTime()).Round(time.Minute).Minutes())
	fmt.Fprintf(stdout, "Scan this with the flit app on your phone:\n\n%s\n", qr.ToSmallString(false))
	fmt.Fprintf(stdout, "Or enter these in the app by hand:\n\n    Server: %s\n    Code:   %s\n\n", server, res.Msg.Code)
	fmt.Fprintf(stdout, "The code works once and expires in %d minutes.\n", mins)
	if u, err := url.Parse(server); err == nil {
		if ip := net.ParseIP(u.Hostname()); (ip != nil && ip.IsLoopback()) || u.Hostname() == "localhost" {
			fmt.Fprintln(stdout, "\nNote: this URL only works on this machine. To pair a phone, set public_url in the config\n(and listen on an address the phone can reach), or pass --url.")
		}
	}
	return nil
}

func listDevices(ctx context.Context, stdout io.Writer, configPath, dataDirFlag string, all bool) error {
	c, err := adminClient(configPath, dataDirFlag)
	if err != nil {
		return err
	}
	res, err := c.ListDevices(ctx, connect.NewRequest(&flitv1.ListDevicesRequest{IncludeRevoked: all}))
	if err != nil {
		return err
	}
	if len(res.Msg.Devices) == 0 {
		fmt.Fprintln(stdout, "No paired devices. Pair one with \"flit pair\".")
		return nil
	}
	for _, d := range res.Msg.Devices {
		seen := "never"
		if d.LastSeenTime != nil {
			seen = d.LastSeenTime.AsTime().Local().Format(time.DateTime)
		}
		status := ""
		if d.RevokeTime != nil {
			status = "  (revoked)"
		}
		fmt.Fprintf(stdout, "%s  %-24s  paired %s  last seen %s%s\n", d.Id, d.Name,
			d.CreateTime.AsTime().Local().Format(time.DateOnly), seen, status)
	}
	return nil
}

func revokeDevice(ctx context.Context, stdout io.Writer, configPath, dataDirFlag, id string) error {
	c, err := adminClient(configPath, dataDirFlag)
	if err != nil {
		return err
	}
	if _, err := c.RevokeDevice(ctx, connect.NewRequest(&flitv1.RevokeDeviceRequest{DeviceId: id})); err != nil {
		return err
	}
	fmt.Fprintf(stdout, "Revoked %s.\n", id)
	return nil
}
