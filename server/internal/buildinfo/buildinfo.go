// Package buildinfo describes the running flit binary.
package buildinfo

import (
	"runtime"
	"runtime/debug"
)

// Set at link time, e.g.
//
//	go build -ldflags "-X github.com/iggy/flit/server/internal/buildinfo.version=0.1.0"
//
// Empty values fall back to what the Go toolchain embedded in the binary.
var (
	version   = ""
	commit    = ""
	buildTime = ""
)

// APIVersion is the highest flit API package version this server speaks.
const APIVersion = "v1"

// Info is the build information for this binary.
type Info struct {
	Version   string
	Commit    string
	BuildTime string
	GoVersion string
	OS        string
	Arch      string
}

// Get returns the build information for this binary.
func Get() Info {
	info := Info{
		Version:   version,
		Commit:    commit,
		BuildTime: buildTime,
		GoVersion: runtime.Version(),
		OS:        runtime.GOOS,
		Arch:      runtime.GOARCH,
	}
	if bi, ok := debug.ReadBuildInfo(); ok {
		for _, s := range bi.Settings {
			switch s.Key {
			case "vcs.revision":
				if info.Commit == "" {
					info.Commit = s.Value
				}
			case "vcs.time":
				if info.BuildTime == "" {
					info.BuildTime = s.Value
				}
			}
		}
	}
	if info.Version == "" {
		info.Version = "dev"
	}
	return info
}
