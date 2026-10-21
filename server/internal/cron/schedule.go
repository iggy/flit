package cron

import (
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// Schedule says when a job runs.
type Schedule interface {
	// Next is the first run time strictly after t, in t's location, or the
	// zero time if there is none (a one-shot that is past).
	Next(t time.Time) time.Time
	// Words describes the schedule in English, e.g. "weekdays at 08:30".
	Words() string
	// OneShot reports whether the job runs only once.
	OneShot() bool
}

// maxLookahead bounds how far Next searches for a cron expression's next
// match (an expression like "0 0 30 2 *" never matches).
const maxLookahead = 5 * 366 * 24 * time.Hour

// ParseSchedule reads a schedule: a 5-field cron expression, @hourly, @daily,
// @weekly (also @midnight, @monthly, @yearly), or one of the English forms:
//
//	every 30m, every 2h, every minute, every hour
//	daily at 9:00, weekdays at 8:30, weekends at 10, mondays at 10
//	in 20m, in 2h, in 1d   (one-shot, from now)
//	at 2026-10-22 09:00    (one-shot)
//
// now anchors "in ..."; times are in loc.
func ParseSchedule(spec string, now time.Time, loc *time.Location) (Schedule, error) {
	s := strings.Join(strings.Fields(strings.ToLower(spec)), " ")
	if s == "" {
		return nil, errors.New("schedule is empty")
	}
	switch s {
	case "@yearly", "@annually":
		s = "0 0 1 1 *"
	case "@monthly":
		s = "0 0 1 * *"
	case "@weekly":
		s = "0 0 * * 0"
	case "@daily", "@midnight":
		s = "0 0 * * *"
	case "@hourly":
		s = "0 * * * *"
	}
	if strings.HasPrefix(s, "@") {
		return nil, fmt.Errorf("unknown schedule %q", spec)
	}
	if looksLikeCron(s) {
		return parseCron(s, loc)
	}
	return parseEnglish(s, now, loc)
}

// looksLikeCron reports whether s is five fields of cron syntax.
func looksLikeCron(s string) bool {
	f := strings.Fields(s)
	if len(f) != 5 {
		return false
	}
	for _, x := range f {
		if strings.Trim(x, "0123456789*/,-abcdefghijklmnopqrstuvwxyz") != "" {
			return false
		}
	}
	return strings.ContainsAny(f[0], "0123456789*")
}

// --- English forms ---

var (
	everyRe   = regexp.MustCompile(`^every (?:(\d+) ?)?(m|min|mins|minute|minutes|h|hr|hrs|hour|hours)$`)
	inRe      = regexp.MustCompile(`^in (\d+) ?(m|min|mins|minute|minutes|h|hr|hrs|hour|hours|d|day|days)$`)
	atDateRe  = regexp.MustCompile(`^(?:at |on )?(\d{4}-\d{2}-\d{2})(?: at|t| )(\d{1,2}:\d{2}(?::\d{2})?)$`)
	daysAtRe  = regexp.MustCompile(`^(?:every )?([a-z, ]+?) at (.+)$`)
	clockRe   = regexp.MustCompile(`^(\d{1,2})(?::(\d{2}))? ?(am|pm)?$`)
	weekdayRe = map[string]time.Weekday{
		"sunday": time.Sunday, "sun": time.Sunday,
		"monday": time.Monday, "mon": time.Monday,
		"tuesday": time.Tuesday, "tue": time.Tuesday, "tues": time.Tuesday,
		"wednesday": time.Wednesday, "wed": time.Wednesday,
		"thursday": time.Thursday, "thu": time.Thursday, "thurs": time.Thursday,
		"friday": time.Friday, "fri": time.Friday,
		"saturday": time.Saturday, "sat": time.Saturday,
	}
)

func unit(u string) time.Duration {
	switch u[0] {
	case 'm':
		return time.Minute
	case 'h':
		return time.Hour
	}
	return 24 * time.Hour
}

func parseEnglish(s string, now time.Time, loc *time.Location) (Schedule, error) {
	if m := everyRe.FindStringSubmatch(s); m != nil {
		n := 1
		if m[1] != "" {
			n, _ = strconv.Atoi(m[1])
		}
		d := time.Duration(n) * unit(m[2])
		if d < time.Minute || d > 24*time.Hour {
			return nil, fmt.Errorf("%q: the interval must be between 1 minute and 24 hours", s)
		}
		return interval{d: d, loc: loc}, nil
	}
	if m := inRe.FindStringSubmatch(s); m != nil {
		n, _ := strconv.Atoi(m[1])
		d := time.Duration(n) * unit(m[2])
		if d <= 0 {
			return nil, fmt.Errorf("%q: the delay must be positive", s)
		}
		return once{at: now.In(loc).Add(d).Truncate(time.Second)}, nil
	}
	if m := atDateRe.FindStringSubmatch(s); m != nil {
		layout := "2006-01-02 15:04"
		if strings.Count(m[2], ":") == 2 {
			layout += ":05"
		}
		t, err := time.ParseInLocation(layout, m[1]+" "+zeroPad(m[2]), loc)
		if err != nil {
			return nil, fmt.Errorf("%q: %v", s, err)
		}
		return once{at: t}, nil
	}
	if m := daysAtRe.FindStringSubmatch(s); m != nil {
		days, err := parseDays(m[1])
		if err != nil {
			return nil, fmt.Errorf("%q: %v", s, err)
		}
		h, mi, err := parseClock(m[2])
		if err != nil {
			return nil, fmt.Errorf("%q: %v", s, err)
		}
		return daily{days: days, hour: h, min: mi, loc: loc}, nil
	}
	return nil, fmt.Errorf("can't read schedule %q; use cron syntax (\"30 8 * * 1-5\"), @hourly/@daily/@weekly, "+
		"or a form like \"every 30m\", \"daily at 9:00\", \"weekdays at 8:30\", \"mondays at 10\", \"in 20m\" or \"at 2026-10-22 09:00\"", s)
}

func zeroPad(clock string) string {
	if i := strings.IndexByte(clock, ':'); i == 1 {
		return "0" + clock
	}
	return clock
}

// parseDays reads "daily", "every day", "weekdays", "weekends" or a list of
// day names ("mondays", "mon, wed and fri").
func parseDays(s string) (uint8, error) {
	const all = 0x7f
	switch s {
	case "daily", "day", "every day", "everyday":
		return all, nil
	case "weekdays", "weekday":
		return 0x3e, nil
	case "weekends", "weekend":
		return 0x41, nil
	}
	var days uint8
	for _, w := range strings.FieldsFunc(strings.ReplaceAll(s, " and ", ","), func(r rune) bool { return r == ',' || r == ' ' }) {
		d, ok := weekdayRe[w]
		if !ok {
			d, ok = weekdayRe[strings.TrimSuffix(w, "s")]
		}
		if !ok {
			return 0, fmt.Errorf("unknown day %q", w)
		}
		days |= 1 << d
	}
	if days == 0 {
		return 0, errors.New("no days")
	}
	return days, nil
}

// parseClock reads "9", "9:30", "09:30", "9am", "5:15 pm".
func parseClock(s string) (hour, min int, err error) {
	m := clockRe.FindStringSubmatch(strings.TrimSpace(s))
	if m == nil {
		return 0, 0, fmt.Errorf("can't read time %q (want e.g. 9:00 or 17:30)", s)
	}
	hour, _ = strconv.Atoi(m[1])
	if m[2] != "" {
		min, _ = strconv.Atoi(m[2])
	}
	switch m[3] {
	case "am", "pm":
		if hour < 1 || hour > 12 {
			return 0, 0, fmt.Errorf("bad time %q", s)
		}
		hour %= 12
		if m[3] == "pm" {
			hour += 12
		}
	}
	if hour > 23 || min > 59 {
		return 0, 0, fmt.Errorf("bad time %q", s)
	}
	return hour, min, nil
}

// interval runs every d, counted from local midnight each day, so "every
// 30m" runs on the hour and half hour.
type interval struct {
	d   time.Duration
	loc *time.Location
}

func (i interval) Next(t time.Time) time.Time {
	t = t.In(i.loc)
	day := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, i.loc)
	for k := 0; k < 3; k++ {
		start := day.AddDate(0, 0, k)
		end := start.AddDate(0, 0, 1)
		// Slots are wall-clock offsets from midnight, so DST days keep their
		// times of day.
		for off := time.Duration(0); off < 24*time.Hour; off += i.d {
			h, m := int(off/time.Hour), int(off%time.Hour/time.Minute)
			slot := time.Date(start.Year(), start.Month(), start.Day(), h, m, 0, 0, i.loc)
			if !slot.Before(end) {
				break
			}
			if slot.After(t) {
				return slot
			}
		}
	}
	return time.Time{}
}

func (i interval) Words() string {
	switch {
	case i.d == time.Minute:
		return "every minute"
	case i.d == time.Hour:
		return "every hour"
	case i.d == 24*time.Hour:
		return "every day at 00:00"
	case i.d%time.Hour == 0:
		return fmt.Sprintf("every %d hours", i.d/time.Hour)
	}
	return fmt.Sprintf("every %d minutes", i.d/time.Minute)
}

func (interval) OneShot() bool { return false }

// daily runs at hour:min on the days in the bitmask (bit 0 is Sunday).
type daily struct {
	days      uint8
	hour, min int
	loc       *time.Location
}

func (d daily) Next(t time.Time) time.Time {
	t = t.In(d.loc)
	for k := 0; k <= 8; k++ {
		day := t.AddDate(0, 0, k)
		if d.days&(1<<day.Weekday()) == 0 {
			continue
		}
		slot := time.Date(day.Year(), day.Month(), day.Day(), d.hour, d.min, 0, 0, d.loc)
		if slot.After(t) {
			return slot
		}
	}
	return time.Time{}
}

func (d daily) Words() string {
	return daysWords(d.days) + fmt.Sprintf(" at %02d:%02d", d.hour, d.min)
}

func (daily) OneShot() bool { return false }

func daysWords(days uint8) string {
	switch days {
	case 0x7f:
		return "every day"
	case 0x3e:
		return "weekdays"
	case 0x41:
		return "weekends"
	}
	var names []string
	for d := time.Sunday; d <= time.Saturday; d++ {
		if days&(1<<d) != 0 {
			names = append(names, d.String()+"s")
		}
	}
	if len(names) == 1 {
		return names[0]
	}
	return strings.Join(names[:len(names)-1], ", ") + " and " + names[len(names)-1]
}

// once runs a single time.
type once struct{ at time.Time }

func (o once) Next(t time.Time) time.Time {
	if o.at.After(t) {
		return o.at
	}
	return time.Time{}
}

func (o once) Words() string { return "once at " + o.at.Format("2006-01-02 15:04") }

func (once) OneShot() bool { return true }

// At is the time of a one-shot schedule, or zero.
func At(s Schedule) time.Time {
	if o, ok := s.(once); ok {
		return o.at
	}
	return time.Time{}
}

// --- cron expressions ---

type cronExpr struct {
	src                        string
	min, hour, dom, month, dow uint64
	domStar, dowStar           bool
	loc                        *time.Location
}

var (
	monthNames = map[string]int{"jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6, "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12}
	dowNames   = map[string]int{"sun": 0, "mon": 1, "tue": 2, "wed": 3, "thu": 4, "fri": 5, "sat": 6}
)

func parseCron(s string, loc *time.Location) (Schedule, error) {
	f := strings.Fields(s)
	c := cronExpr{src: s, loc: loc}
	var err error
	if c.min, err = cronField(f[0], 0, 59, nil); err != nil {
		return nil, fmt.Errorf("minute field %q: %v", f[0], err)
	}
	if c.hour, err = cronField(f[1], 0, 23, nil); err != nil {
		return nil, fmt.Errorf("hour field %q: %v", f[1], err)
	}
	if c.dom, err = cronField(f[2], 1, 31, nil); err != nil {
		return nil, fmt.Errorf("day-of-month field %q: %v", f[2], err)
	}
	if c.month, err = cronField(f[3], 1, 12, monthNames); err != nil {
		return nil, fmt.Errorf("month field %q: %v", f[3], err)
	}
	if c.dow, err = cronField(f[4], 0, 7, dowNames); err != nil {
		return nil, fmt.Errorf("day-of-week field %q: %v", f[4], err)
	}
	if c.dow&(1<<7) != 0 { // 7 is Sunday too
		c.dow |= 1
	}
	c.domStar, c.dowStar = f[2][0] == '*', f[4][0] == '*'
	return c, nil
}

// cronField parses one field: *, n, a-b, lists and /step, with names.
func cronField(s string, lo, hi int, names map[string]int) (uint64, error) {
	var bits uint64
	num := func(x string) (int, error) {
		if n, ok := names[x]; ok {
			return n, nil
		}
		n, err := strconv.Atoi(x)
		if err != nil {
			return 0, fmt.Errorf("%q is not a number", x)
		}
		if n < lo || n > hi {
			return 0, fmt.Errorf("%d is out of range %d-%d", n, lo, hi)
		}
		return n, nil
	}
	for _, part := range strings.Split(s, ",") {
		rng, stepStr, hasStep := strings.Cut(part, "/")
		step := 1
		if hasStep {
			var err error
			if step, err = strconv.Atoi(stepStr); err != nil || step < 1 {
				return 0, fmt.Errorf("bad step %q", stepStr)
			}
		}
		a, b := lo, hi
		switch {
		case rng == "*":
		case strings.Contains(rng, "-"):
			x, y, _ := strings.Cut(rng, "-")
			var err error
			if a, err = num(x); err != nil {
				return 0, err
			}
			if b, err = num(y); err != nil {
				return 0, err
			}
			if a > b {
				return 0, fmt.Errorf("range %q goes backwards", rng)
			}
		default:
			n, err := num(rng)
			if err != nil {
				return 0, err
			}
			a = n
			if !hasStep {
				b = n
			}
		}
		for i := a; i <= b; i += step {
			bits |= 1 << i
		}
	}
	return bits, nil
}

func (c cronExpr) dayMatches(t time.Time) bool {
	dom := c.dom&(1<<t.Day()) != 0
	dow := c.dow&(1<<t.Weekday()) != 0
	switch {
	case c.domStar && c.dowStar:
		return true
	case c.domStar:
		return dow
	case c.dowStar:
		return dom
	}
	return dom || dow // both restricted: either matches (standard cron)
}

func (c cronExpr) Next(t time.Time) time.Time {
	t = t.In(c.loc).Truncate(time.Minute).Add(time.Minute)
	limit := t.Add(maxLookahead)
	for t.Before(limit) {
		switch {
		case c.month&(1<<t.Month()) == 0:
			t = time.Date(t.Year(), t.Month()+1, 1, 0, 0, 0, 0, c.loc)
		case !c.dayMatches(t):
			t = time.Date(t.Year(), t.Month(), t.Day()+1, 0, 0, 0, 0, c.loc)
		case c.hour&(1<<t.Hour()) == 0:
			next := time.Date(t.Year(), t.Month(), t.Day(), t.Hour()+1, 0, 0, 0, c.loc)
			if !next.After(t) { // a DST fall-back repeats the hour
				next = t.Add(time.Hour).Truncate(time.Hour)
			}
			t = next
		case c.min&(1<<t.Minute()) == 0:
			t = t.Add(time.Minute)
		default:
			return t
		}
	}
	return time.Time{}
}

func (c cronExpr) OneShot() bool { return false }

// Words describes the common shapes of cron expressions in English and
// falls back to the expression itself.
func (c cronExpr) Words() string {
	f := strings.Fields(c.src)
	single := func(bits uint64, lo, hi int) (int, bool) {
		n := -1
		for i := lo; i <= hi; i++ {
			if bits&(1<<i) != 0 {
				if n >= 0 {
					return 0, false
				}
				n = i
			}
		}
		return n, n >= 0
	}
	m, oneMin := single(c.min, 0, 59)
	h, oneHour := single(c.hour, 0, 23)
	everyDay := f[2] == "*" && f[3] == "*"
	switch {
	case !everyDay:
	case f[0] == "*" && f[1] == "*" && f[4] == "*":
		return "every minute"
	case strings.HasPrefix(f[0], "*/") && f[1] == "*" && f[4] == "*":
		return "every " + f[0][2:] + " minutes"
	case oneMin && f[1] == "*" && f[4] == "*":
		if m == 0 {
			return "every hour"
		}
		return fmt.Sprintf("every hour at :%02d", m)
	case oneMin && strings.HasPrefix(f[1], "*/") && f[4] == "*":
		return fmt.Sprintf("every %s hours at :%02d", f[1][2:], m)
	case oneMin && oneHour:
		return daysWords(uint8(c.dow&0x7f)) + fmt.Sprintf(" at %02d:%02d", h, m)
	}
	return "cron " + c.src
}
