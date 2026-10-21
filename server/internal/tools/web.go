package tools

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"mime"
	"net/http"
	"net/url"
	"strings"
	"time"

	"golang.org/x/net/html"
)

const (
	webTimeout  = 30 * time.Second
	webMaxBytes = 4 << 20
	searchMax   = 10
)

// webClient is shared by the web tools.
var webClient = &http.Client{Timeout: webTimeout}

// WebFetchTool reads a web page as text.
func WebFetchTool() Tool { return webFetchTool }

var webFetchTool = Tool{
	Name:        "web_fetch",
	ReadOnly:    true,
	Description: "Fetch a web page (http/https) and return its text. HTML is converted to plain text; JSON and text are returned as is.",
	Schema: `{"type":"object","properties":{
"url":{"type":"string","description":"The page to fetch"}
},"required":["url"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			URL string `json:"url"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		u, err := url.Parse(a.URL)
		if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
			return errorf("url must be an http(s) URL")
		}
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
		if err != nil {
			return errorf("%v", err)
		}
		req.Header.Set("User-Agent", "flit (coding agent)")
		req.Header.Set("Accept", "text/html,application/xhtml+xml,text/plain,application/json;q=0.9,*/*;q=0.5")
		resp, err := webClient.Do(req)
		if err != nil {
			return errorf("fetch failed: %v", err)
		}
		defer resp.Body.Close()
		body, err := io.ReadAll(io.LimitReader(resp.Body, webMaxBytes))
		if err != nil {
			return errorf("read failed: %v", err)
		}
		ct, _, _ := mime.ParseMediaType(resp.Header.Get("Content-Type"))
		var text string
		switch {
		case ct == "text/html" || ct == "application/xhtml+xml":
			text = htmlText(string(body))
		case strings.HasPrefix(ct, "text/") || strings.Contains(ct, "json") || strings.Contains(ct, "xml") || ct == "":
			text = string(body)
		default:
			return errorf("%s is %s, not text", u, ct)
		}
		head := fmt.Sprintf("%s (HTTP %d, %s)\n\n", resp.Request.URL, resp.StatusCode, ct)
		return Result{Text: head + strings.TrimSpace(text), IsError: resp.StatusCode >= 400}
	},
}

// htmlText extracts readable text from HTML: drops scripts, styles and
// navigation chrome, keeps link targets, and puts block elements on their
// own lines.
func htmlText(src string) string {
	z := html.NewTokenizer(strings.NewReader(src))
	var b strings.Builder
	skip := 0
	var href string
	for {
		switch z.Next() {
		case html.ErrorToken:
			return collapseBlankLines(b.String())
		case html.StartTagToken, html.SelfClosingTagToken:
			name, hasAttr := z.TagName()
			tag := string(name)
			switch tag {
			case "script", "style", "noscript", "svg", "nav", "footer", "head":
				skip++
			case "a":
				href = ""
				for hasAttr {
					var k, v []byte
					k, v, hasAttr = z.TagAttr()
					if string(k) == "href" {
						href = string(v)
					}
				}
			case "br", "p", "div", "li", "tr", "h1", "h2", "h3", "h4", "h5", "h6", "pre", "section", "article":
				b.WriteString("\n")
				if strings.HasPrefix(tag, "h") && len(tag) == 2 {
					b.WriteString(strings.Repeat("#", int(tag[1]-'0')) + " ")
				}
				if tag == "li" {
					b.WriteString("- ")
				}
			}
		case html.EndTagToken:
			name, _ := z.TagName()
			switch string(name) {
			case "script", "style", "noscript", "svg", "nav", "footer", "head":
				if skip > 0 {
					skip--
				}
			case "a":
				if href != "" && !strings.HasPrefix(href, "#") && !strings.HasPrefix(href, "javascript:") && skip == 0 {
					b.WriteString("(" + href + ") ")
				}
				href = ""
			case "p", "div", "pre", "table", "ul", "ol":
				b.WriteString("\n")
			}
		case html.TextToken:
			if skip == 0 {
				t := strings.Join(strings.Fields(string(z.Text())), " ")
				if t != "" {
					b.WriteString(t + " ")
				}
			}
		}
	}
}

func collapseBlankLines(s string) string {
	var out []string
	blank := 0
	for _, line := range strings.Split(s, "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			blank++
			if blank > 1 {
				continue
			}
		} else {
			blank = 0
		}
		out = append(out, line)
	}
	return strings.TrimSpace(strings.Join(out, "\n"))
}

// WebSearchTool searches with a SearXNG instance at baseURL (its JSON format
// must be enabled). SearXNG is free and self-hostable; paid search APIs are
// not supported.
func WebSearchTool(baseURL string) Tool {
	return Tool{
		Name:        "web_search",
		ReadOnly:    true,
		Description: "Search the web. Returns titles, URLs and snippets; use web_fetch to read a result.",
		Schema: `{"type":"object","properties":{
"query":{"type":"string","description":"What to search for"}
},"required":["query"]}`,
		Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
			var a struct {
				Query string `json:"query"`
			}
			if err := decode(raw, &a); err != nil {
				return errorf("%v", err)
			}
			if strings.TrimSpace(a.Query) == "" {
				return errorf("query is empty")
			}
			u := strings.TrimSuffix(baseURL, "/") + "/search?" + url.Values{"q": {a.Query}, "format": {"json"}}.Encode()
			req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
			if err != nil {
				return errorf("%v", err)
			}
			resp, err := webClient.Do(req)
			if err != nil {
				return errorf("search failed: %v", err)
			}
			defer resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				return errorf("search failed: HTTP %d (is the JSON format enabled in SearXNG's settings?)", resp.StatusCode)
			}
			var res struct {
				Results []struct {
					Title   string `json:"title"`
					URL     string `json:"url"`
					Content string `json:"content"`
				} `json:"results"`
			}
			if err := json.NewDecoder(io.LimitReader(resp.Body, webMaxBytes)).Decode(&res); err != nil {
				return errorf("bad search response: %v", err)
			}
			if len(res.Results) == 0 {
				return Result{Text: "no results"}
			}
			var b strings.Builder
			for i, r := range res.Results {
				if i == searchMax {
					break
				}
				fmt.Fprintf(&b, "%d. %s\n   %s\n   %s\n", i+1, strings.TrimSpace(r.Title), r.URL, strings.TrimSpace(r.Content))
			}
			return Result{Text: b.String()}
		},
	}
}
