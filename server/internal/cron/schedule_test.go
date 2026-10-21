package cron

import (
	"strings"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

func mustLoc(t *testing.T, name string) *time.Location {
	t.Helper()
	loc, err := time.LoadLocation(name)
	if err != nil {
		t.Fatal(err)
	}
	return loc
}

func TestParseScheduleNext(t *testing.T) {
	utc := time.UTC
	// Wednesday 2026-10-21 10:07:30 UTC.
	now := time.Date(2026, 10, 21, 10, 7, 30, 0, utc)
	for _, tc := range []struct {
		spec  string
		words string
		next  []string // successive Next times from now
		once  bool
	}{
		{"every 30m", "every 30 minutes", []string{"2026-10-21 10:30", "2026-10-21 11:00"}, false},
		{"every 2h", "every 2 hours", []string{"2026-10-21 12:00", "2026-10-21 14:00"}, false},
		{"every minute", "every minute", []string{"2026-10-21 10:08", "2026-10-21 10:09"}, false},
		{"every hour", "every hour", []string{"2026-10-21 11:00"}, false},
		{"every 1m", "every minute", []string{"2026-10-21 10:08"}, false},
		{"every 90 minutes", "every 90 minutes", []string{"2026-10-21 10:30", "2026-10-21 12:00"}, false},
		{"Every 7h", "every 7 hours", []string{"2026-10-21 14:00", "2026-10-21 21:00", "2026-10-22 00:00"}, false},
		{"daily at 9:00", "every day at 09:00", []string{"2026-10-22 09:00", "2026-10-23 09:00"}, false},
		{"daily at 10:30", "every day at 10:30", []string{"2026-10-21 10:30"}, false},
		{"every day at 5pm", "every day at 17:00", []string{"2026-10-21 17:00"}, false},
		{"weekdays at 8:30", "weekdays at 08:30", []string{"2026-10-22 08:30", "2026-10-23 08:30", "2026-10-26 08:30"}, false},
		{"weekends at 10", "weekends at 10:00", []string{"2026-10-24 10:00", "2026-10-25 10:00", "2026-10-31 10:00"}, false},
		{"mondays at 10", "Mondays at 10:00", []string{"2026-10-26 10:00", "2026-11-02 10:00"}, false},
		{"monday at 10:15", "Mondays at 10:15", []string{"2026-10-26 10:15"}, false},
		{"mon, wed and fri at 12:00", "Mondays, Wednesdays and Fridays at 12:00", []string{"2026-10-21 12:00", "2026-10-23 12:00", "2026-10-26 12:00"}, false},
		{"in 20m", "once at 2026-10-21 10:27", []string{"2026-10-21 10:27:30", ""}, true},
		{"in 2 hours", "once at 2026-10-21 12:07", []string{"2026-10-21 12:07:30"}, true},
		{"at 2026-10-22 09:00", "once at 2026-10-22 09:00", []string{"2026-10-22 09:00", ""}, true},
		{"2026-10-22 9:05", "once at 2026-10-22 09:05", []string{"2026-10-22 09:05"}, true},
		{"at 2026-10-20 09:00", "once at 2026-10-20 09:00", []string{""}, true},
		{"0 8 * * 1-5", "weekdays at 08:00", []string{"2026-10-22 08:00", "2026-10-23 08:00", "2026-10-26 08:00"}, false},
		{"*/15 * * * *", "every 15 minutes", []string{"2026-10-21 10:15", "2026-10-21 10:30"}, false},
		{"5 * * * *", "every hour at :05", []string{"2026-10-21 11:05"}, false},
		{"0 */6 * * *", "every 6 hours at :00", []string{"2026-10-21 12:00", "2026-10-21 18:00"}, false},
		{"0 9 1 * *", "cron 0 9 1 * *", []string{"2026-11-01 09:00", "2026-12-01 09:00"}, false},
		{"0 0 * * sun", "Sundays at 00:00", []string{"2026-10-25 00:00"}, false},
		{"0 0 * * 7", "Sundays at 00:00", []string{"2026-10-25 00:00"}, false},
		{"30 4 1,15 * *", "cron 30 4 1,15 * *", []string{"2026-11-01 04:30", "2026-11-15 04:30"}, false},
		{"0 12 13 * 5", "cron 0 12 13 * 5", []string{"2026-10-23 12:00", "2026-10-30 12:00", "2026-11-06 12:00"}, false},
		{"0 0 1 jan *", "cron 0 0 1 jan *", []string{"2027-01-01 00:00"}, false},
		{"@hourly", "every hour", []string{"2026-10-21 11:00"}, false},
		{"@daily", "every day at 00:00", []string{"2026-10-22 00:00"}, false},
		{"@weekly", "Sundays at 00:00", []string{"2026-10-25 00:00"}, false},
		{"@monthly", "cron 0 0 1 * *", []string{"2026-11-01 00:00"}, false},
		{"0 0 30 2 *", "cron 0 0 30 2 *", []string{""}, false},
	} {
		t.Run(tc.spec, func(t *testing.T) {
			s, err := ParseSchedule(tc.spec, now, utc)
			if err != nil {
				t.Fatal(err)
			}
			if got := s.Words(); got != tc.words {
				t.Errorf("Words() = %q, want %q", got, tc.words)
			}
			if s.OneShot() != tc.once {
				t.Errorf("OneShot() = %v", s.OneShot())
			}
			at := now
			for i, want := range tc.next {
				got := s.Next(at)
				var gotStr string
				if !got.IsZero() {
					gotStr = got.Format("2006-01-02 15:04")
					if got.Second() != 0 {
						gotStr = got.Format("2006-01-02 15:04:05")
					}
				}
				if gotStr != want {
					t.Fatalf("Next #%d = %q, want %q", i+1, gotStr, want)
				}
				if got.IsZero() {
					break
				}
				at = got
			}
		})
	}
}

func TestParseScheduleErrors(t *testing.T) {
	now := time.Now()
	for _, spec := range []string{
		"", "sometimes", "every 0m", "every 25h", "every 30s", "in 0m", "daily at 25:00", "daily at 9:60",
		"blursdays at 9", "at 2026-13-01 10:00", "61 * * * *", "* * * * 8", "5-1 * * * *", "*/0 * * * *",
		"@reboot", "1 2 3 4", "13pm daily",
	} {
		if _, err := ParseSchedule(spec, now, time.UTC); err == nil {
			t.Errorf("ParseSchedule(%q): no error", spec)
		}
	}
}

func TestScheduleTimezoneAndDST(t *testing.T) {
	berlin := mustLoc(t, "Europe/Berlin")
	// DST ends in Berlin on 2026-10-25 at 03:00 local (back to 02:00).
	s, err := ParseSchedule("daily at 9:00", time.Now(), berlin)
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 10, 24, 12, 0, 0, 0, berlin)
	for _, want := range []string{"2026-10-25 09:00 +0100", "2026-10-26 09:00 +0100"} {
		at = s.Next(at)
		if got := at.Format("2006-01-02 15:04 -0700"); got != want {
			t.Errorf("Next = %s, want %s", got, want)
		}
	}
	// A run at 8:00 UTC is 10:00 in Berlin before the change.
	c, _ := ParseSchedule("0 10 * * *", time.Now(), berlin)
	if got := c.Next(time.Date(2026, 10, 24, 0, 0, 0, 0, time.UTC)).UTC().Format("15:04"); got != "08:00" {
		t.Errorf("cron in Berlin = %s UTC, want 08:00", got)
	}
	// Every hour across the fall-back hour still advances.
	h, _ := ParseSchedule("0 * * * *", time.Now(), berlin)
	at = time.Date(2026, 10, 25, 1, 30, 0, 0, berlin)
	seen := map[time.Time]bool{}
	for range 5 {
		next := h.Next(at)
		if !next.After(at) || seen[next] {
			t.Fatalf("Next(%v) = %v", at, next)
		}
		seen[next] = true
		at = next
	}
}

func TestParseJob(t *testing.T) {
	now := time.Date(2026, 10, 21, 10, 0, 0, 0, time.UTC)
	ok := "---\nschedule: weekdays at 8:30\nproject: flit\nrole: qa\nmodel: {provider: local, model: m, effort: off}\n" +
		"ask: wait\nask_timeout: 10m\nyolo: true\ntimezone: UTC\ncatch_up: 0\nkeep_runs: 5\n---\nCheck CI.\n"
	j, err := Parse([]byte(ok), now)
	if err != nil {
		t.Fatal(err)
	}
	if j.Prompt != "Check CI." || j.Ask != AskWait || j.AskWaitFor() != 10*time.Minute || !j.Yolo ||
		j.CatchUpWindow() != 0 || j.Keep() != 5 || j.Model.Effort != "off" || !j.IsEnabled() || j.Sched == nil {
		t.Errorf("parsed %+v", j)
	}
	j, err = Parse([]byte("---\nschedule: every 1h\n---\nHi\n"), now)
	if err != nil {
		t.Fatal(err)
	}
	if j.Ask != AskDeny || j.AskWaitFor() != time.Hour || j.CatchUpWindow() != time.Hour || j.Keep() != 50 {
		t.Errorf("defaults %+v", j)
	}

	for _, tc := range []struct{ file, err string }{
		{"no frontmatter", "starts with ---"},
		{"---\nschedule: daily at 9\n", "never ends"},
		{"---\nschedule: daily at 9\nfoo: 1\n---\nx", "field foo not found"},
		{"---\nproject: x\n---\nx", "schedule is required"},
		{"---\nschedule: whenever\n---\nx", "can't read schedule"},
		{"---\nschedule: daily at 9\n---\n", "prompt"},
		{"---\nschedule: daily at 9\nask: maybe\n---\nx", "ask"},
		{"---\nschedule: daily at 9\ntimezone: Mars/Base\n---\nx", "timezone"},
		{"---\nschedule: daily at 9\ndir: relative/path\n---\nx", "absolute"},
		{"---\nschedule: daily at 9\nmodel: {provider: x}\n---\nx", "both provider and model"},
		{"---\nschedule: daily at 9\nmodel: {provider: x, model: y, temp: 1}\n---\nx", "field temp not found"},
		{"---\nschedule: daily at 9\ncatch_up: 5\n---\nx", "missing unit"},
		{"---\nschedule: daily at 9\ncatch_up: soon\n---\nx", "invalid duration"},
	} {
		_, err := Parse([]byte(tc.file), now)
		if err == nil || !strings.Contains(err.Error(), tc.err) {
			t.Errorf("Parse(%q) = %v, want error containing %q", tc.file, err, tc.err)
		}
	}
}

func TestListWriteSetEnabled(t *testing.T) {
	dir := t.TempDir()
	spec := Spec{Schedule: "daily at 9:00", Project: "flit", Model: config.TaskModel{Provider: "local", Model: "m: x"}, Prompt: "Look at # things.\n\n---\nmore"}
	if _, err := Write(dir, "morning", Format(spec)); err != nil {
		t.Fatal(err)
	}
	if _, err := Write(dir, "bad", []byte("---\nschedule: never ever\n---\nx")); err != nil {
		t.Fatal(err)
	}
	if _, err := Write(dir, "../evil", []byte("x")); err == nil {
		t.Error("wrote a job with a path in its name")
	}
	jobs, err := List(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(jobs) != 2 || jobs[0].Name != "bad" || jobs[0].Err == nil || jobs[1].Name != "morning" || jobs[1].Err != nil {
		t.Fatalf("List = %+v", jobs)
	}
	m := jobs[1]
	if m.Prompt != "Look at # things.\n\n---\nmore" || m.Model.Model != "m: x" || m.Project != "flit" {
		t.Errorf("round trip: %+v", m)
	}

	// SetEnabled keeps comments and adds or replaces the line.
	path := m.Path
	if err := SetEnabled(path, false); err != nil {
		t.Fatal(err)
	}
	if j := Load(path); j.Err != nil || j.IsEnabled() || j.Prompt != m.Prompt {
		t.Fatalf("after disable: %+v", j)
	}
	if err := SetEnabled(path, true); err != nil {
		t.Fatal(err)
	}
	if j := Load(path); !j.IsEnabled() {
		t.Error("still disabled")
	}
	commented := "---\n# my job\nschedule: every 2h # often\nenabled: true\n---\nbody\n"
	if _, err := Write(dir, "c", []byte(commented)); err != nil {
		t.Fatal(err)
	}
	if err := SetEnabled(dir+"/c.md", false); err != nil {
		t.Fatal(err)
	}
	if j := Load(dir + "/c.md"); j.IsEnabled() || j.Err != nil {
		t.Errorf("c: %+v", j)
	}
	if err := Remove(dir, "c"); err != nil {
		t.Fatal(err)
	}
	if jobs, _ := List(dir); len(jobs) != 2 {
		t.Errorf("after remove: %d jobs", len(jobs))
	}
	if jobs, err := List(dir + "/missing"); err != nil || jobs != nil {
		t.Errorf("missing dir: %v %v", jobs, err)
	}
}

func TestFinishOneShotPinsIn(t *testing.T) {
	dir := t.TempDir()
	path, err := Write(dir, "soon", []byte("---\n# remind me\nschedule: in 20m\n---\nPing.\n"))
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 10, 21, 10, 20, 30, 0, time.Local)
	if err := FinishOneShot(path, at); err != nil {
		t.Fatal(err)
	}
	j := Load(path)
	if j.Err != nil || j.IsEnabled() || j.Schedule != "at 2026-10-21 10:20:30" || j.Prompt != "Ping." {
		t.Fatalf("after: %+v", j)
	}
	// "at" schedules are left as written.
	path, _ = Write(dir, "later", []byte("---\nschedule: at 2026-10-22 09:00\n---\nPing.\n"))
	if err := FinishOneShot(path, at); err != nil {
		t.Fatal(err)
	}
	if j := Load(path); j.Schedule != "at 2026-10-22 09:00" || j.IsEnabled() {
		t.Fatalf("at: %+v", j)
	}
}
