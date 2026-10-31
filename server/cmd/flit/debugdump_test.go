package main

import (
	"strings"
	"testing"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
)

func TestWriteDump(t *testing.T) {
	now := time.Date(2026, 10, 26, 12, 0, 0, 0, time.UTC)
	at := func(d time.Duration) *timestamppb.Timestamp { return timestamppb.New(now.Add(-d)) }
	res := &flitv1.DebugDumpResponse{
		SessionsLockFree: true,
		Limits:           []*flitv1.ModelLimitDebug{{Provider: "local", Model: "qwen", Limit: 1, InUse: 1, Waiting: 1}},
		Sessions: []*flitv1.SessionDebug{
			{SessionId: "s1", LockFree: true, Title: "Build", State: flitv1.TaskState_TASK_STATE_WORKING, TurnRunning: true,
				LastSeq: 40, LastEventTime: at(90 * time.Second),
				Call: &flitv1.ModelCallDebug{MessageId: "m1", Provider: "local", Model: "qwen", Phase: "streaming", SentTime: at(3 * time.Minute),
					IdleMs: 90000, WatchdogMs: 120000, Bytes: 9000, StreamedTokens: 312, PromptProcessed: 48000, PromptTotal: 48000}},
			{SessionId: "s2", LockFree: true, Title: "Other", State: flitv1.TaskState_TASK_STATE_WORKING, TurnRunning: true,
				Call: &flitv1.ModelCallDebug{MessageId: "m2", Provider: "local", Model: "qwen", Queued: true}},
			{SessionId: "s3"},
			{SessionId: "s4", LockFree: true, State: flitv1.TaskState_TASK_STATE_DONE},
		},
	}
	var b strings.Builder
	if !writeDump(&b, res, now) {
		t.Fatal("a held lock not reported")
	}
	out := b.String()
	for _, want := range []string{
		"local/qwen: 1 in flight, 1 waiting (limit 1)",
		`Session s1 "Build": working, turn running, last event #40 1m30s ago`,
		"model call: local/qwen (m1): streaming, sent 3m0s ago, prompt 48000/48000, 312 output chunks, 9000 bytes; quiet for 1m30s (watchdog gives up at 2m0s)",
		"(m2): waiting for its turn under the concurrency limit",
		"Session s3: its lock is held",
	} {
		if !strings.Contains(out, want) {
			t.Errorf("missing %q in:\n%s", want, out)
		}
	}
	if strings.Contains(out, "s4") {
		t.Errorf("idle session listed:\n%s", out)
	}
}
