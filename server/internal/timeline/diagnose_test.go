package timeline

import (
	"strings"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/store"
)

func pinned(n int32) *int32 { return &n }

func TestDiagnose(t *testing.T) {
	stalled := flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED
	retried := flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_RETRIED
	busy := func(decoded, decodedDelta, prompt, promptDelta int64) *flitv1.LlamaSlot {
		return &flitv1.LlamaSlot{Id: 0, IsProcessing: true, PromptTokens: 48000, PromptProcessed: prompt, Decoded: decoded,
			DecodedDelta: decodedDelta, PromptProcessedDelta: promptDelta}
	}
	for _, c := range []struct {
		name    string
		outcome flitv1.ModelCallOutcome
		phase   string
		st      *flitv1.ModelServerState
		want    string
	}{
		{"not llama.cpp", stalled, "streaming", nil, ""},
		{"unreachable", stalled, "connecting", &flitv1.ModelServerState{Error: "connection refused", SlotsError: "connection refused"}, "down or unreachable"},
		{"reloading", stalled, "streaming", &flitv1.ModelServerState{ModelState: "loading"}, "restarted"},
		{"unloaded", stalled, "streaming", &flitv1.ModelServerState{ModelState: "unloaded"}, "exited or was unloaded"},
		{"main loop stuck", stalled, "processing_prompt", &flitv1.ModelServerState{ModelState: "loaded", SlotsError: "no answer within 4s"}, "main loop is stuck"},
		{"never arrived", stalled, "connecting", &flitv1.ModelServerState{ModelState: "loaded", Slots: []*flitv1.LlamaSlot{{Id: 0}}}, "never got to it"},
		{"reply lost", stalled, "streaming", &flitv1.ModelServerState{ModelState: "loaded", Slots: []*flitv1.LlamaSlot{{Id: 0}}}, "never reached flit"},
		{"pinned slot idle", stalled, "streaming", &flitv1.ModelServerState{PinnedSlot: pinned(1), Slots: []*flitv1.LlamaSlot{busy(5, 0, 48000, 0), {Id: 1}}}, "slot 1 (this call's) wasn't running"},
		{"output not arriving", stalled, "streaming", &flitv1.ModelServerState{SampleMs: 2000, Slots: []*flitv1.LlamaSlot{busy(400, 30, 48000, 0)}}, "isn't reaching flit"},
		{"progress not arriving", stalled, "processing_prompt", &flitv1.ModelServerState{SampleMs: 2000, Slots: []*flitv1.LlamaSlot{busy(0, 0, 30000, 900)}}, "progress reports aren't reaching flit"},
		{"long batch", stalled, "processing_prompt", &flitv1.ModelServerState{SampleMs: 2000, Slots: []*flitv1.LlamaSlot{busy(0, 0, 30000, 0)}}, "one very long batch"},
		{"generation stuck", stalled, "streaming", &flitv1.ModelServerState{SampleMs: 2000, Slots: []*flitv1.LlamaSlot{busy(312, 0, 48000, 0)}}, "llama.cpp or the model itself is stuck"},
		{"retried while slow", retried, "processing_prompt", &flitv1.ModelServerState{SampleMs: 2000, Slots: []*flitv1.LlamaSlot{busy(0, 0, 30000, 900)}}, "slow rather than stuck"},
		{"unknown slot", stalled, "streaming", &flitv1.ModelServerState{SampleMs: 2000, Slots: []*flitv1.LlamaSlot{busy(1, 0, 1, 0), {Id: 1, IsProcessing: true}}}, "none got anywhere"},
	} {
		got := Diagnose(&flitv1.ModelCallEnded{Outcome: c.outcome, Phase: c.phase, Server: c.st})
		if c.want == "" && got != "" || !strings.Contains(got, c.want) {
			t.Errorf("%s: %q, want %q", c.name, got, c.want)
		}
	}
}

// The timeline shows the server state of a stalled llama.cpp call and the
// diagnosis.
func TestTimelineServerState(t *testing.T) {
	l := &log{t0: time.Date(2026, 10, 18, 17, 0, 0, 0, time.Local)}
	l.add(0, &flitv1.Event{Payload: &flitv1.Event_ModelCallStarted{ModelCallStarted: &flitv1.ModelCallStarted{MessageId: "m1", Attempt: 1}}})
	l.add(130*time.Second, &flitv1.Event{Payload: &flitv1.Event_ModelCallEnded{ModelCallEnded: &flitv1.ModelCallEnded{
		MessageId: "m1", Attempt: 1, Outcome: flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED, Phase: "streaming",
		TotalMs: 130000, FirstTokenMs: 41000, LastByteMs: 40000, Bytes: 9000, StreamedTokens: 312, PromptProcessed: 48000, PromptTotal: 48000,
		Server: &flitv1.ModelServerState{ModelState: "loaded", PinnedSlot: pinned(0), SampleMs: 2000, Slots: []*flitv1.LlamaSlot{
			{Id: 0, IsProcessing: true, IdTask: 9, PromptTokens: 48000, PromptProcessed: 48000, Decoded: 700, DecodedDelta: 40},
		}},
	}}})
	var b strings.Builder
	if err := Write(&b, store.Session{ID: "s1"}, l.evs, l.t0.Add(3*time.Minute)); err != nil {
		t.Fatal(err)
	}
	out := b.String()
	for _, want := range []string{
		"312 output chunks, prompt progress 48000/48000",
		"llama.cpp then: model loaded, call pinned to slot 0, slot 0 busy (task 9: prompt 48000/48000, 0 cached, 700 generated; +0 prompt, +40 generated in 2.0s)",
		"=> llama.cpp was still generating (slot 0: 700 tokens, 40 more in 2.0s) while flit heard nothing (312 output chunks so far)",
	} {
		if !strings.Contains(out, want) {
			t.Errorf("missing %q in:\n%s", want, out)
		}
	}
}
