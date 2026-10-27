package timeline

import (
	"fmt"
	"strings"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
)

// Outcome names a call's outcome for people: "ok", "stalled", ...
func Outcome(o flitv1.ModelCallOutcome) string {
	switch o {
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_OK:
		return "ok"
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED:
		return "stalled"
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_RETRIED:
		return "retried by request"
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_CANCELLED:
		return "cancelled"
	}
	return "failed"
}

// Diagnose says which layer a llama.cpp call that stalled, failed or was
// retried was stuck in, from the server state sampled right after
// (ModelCallEnded.server): the model or llama.cpp itself, the way between
// llama.cpp and flit (router, proxy, network), or neither. "" when there
// is no server state to go on.
func Diagnose(e *flitv1.ModelCallEnded) string {
	st := e.GetServer()
	if st == nil {
		return ""
	}
	where := phase(e.Phase)
	retried := e.Outcome == flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_RETRIED
	// What flit heard meanwhile: for a stall, nothing; for a retry it may
	// have been hearing progress all along.
	heard := "while flit heard nothing"
	if retried {
		heard = "when it was retried"
	}
	switch st.ModelState {
	case "loading":
		return "llama.cpp was loading the model again: its instance probably restarted (crashed?) during the call"
	case "unloaded":
		return "the model was no longer loaded: its llama.cpp instance exited or was unloaded during the call"
	case "sleeping":
		return "the model had gone to sleep: llama.cpp unloaded it during the call"
	}
	if st.SlotsError != "" {
		if st.Error != "" {
			return fmt.Sprintf("llama.cpp didn't answer at all (%s): the server or router is down or unreachable", st.Error)
		}
		if strings.HasPrefix(st.SlotsError, "no answer") || strings.Contains(st.SlotsError, "second sample: no answer") {
			return fmt.Sprintf("llama.cpp's slot status didn't answer (%s) though the server is up: its main loop is stuck in a batch (model or GPU hang, or a very slow batch)", st.SlotsError)
		}
		return fmt.Sprintf("couldn't read llama.cpp's slots (%s)", st.SlotsError)
	}
	var busy []*flitv1.LlamaSlot
	for _, sl := range st.Slots {
		if sl.IsProcessing {
			busy = append(busy, sl)
		}
	}
	if len(busy) == 0 {
		switch e.Phase {
		case "connecting", "waiting_for_first_byte":
			return fmt.Sprintf("llama.cpp had nothing running while flit was %s: the request never got to it, or it dropped it (router, proxy or network)", where)
		}
		return fmt.Sprintf("llama.cpp had nothing running while flit was %s: it finished or dropped the request but the rest of the reply never reached flit (router, proxy or network, or a llama.cpp bug)", where)
	}
	var sl *flitv1.LlamaSlot
	if st.PinnedSlot != nil {
		for _, b := range busy {
			if b.Id == st.GetPinnedSlot() {
				sl = b
			}
		}
		if sl == nil {
			return fmt.Sprintf("llama.cpp's slot %d (this call's) wasn't running anything while flit was %s: the request was lost or dropped (router, proxy or network); other slots were busy", st.GetPinnedSlot(), where)
		}
	} else if len(busy) == 1 {
		sl = busy[0]
	}
	if st.SampleMs == 0 {
		if sl != nil {
			return fmt.Sprintf("llama.cpp's slot %d was still processing (%s)", sl.Id, slotText(sl))
		}
		return fmt.Sprintf("llama.cpp had %d of %d slots busy", len(busy), len(st.Slots))
	}
	gap := dur(ms(st.SampleMs))
	if sl == nil {
		moving := 0
		for _, b := range busy {
			if b.DecodedDelta > 0 || b.PromptProcessedDelta > 0 {
				moving++
			}
		}
		if moving == 0 {
			return fmt.Sprintf("llama.cpp had %d slots busy and none got anywhere in %s: llama.cpp or the model itself is stuck", len(busy), gap)
		}
		return fmt.Sprintf("llama.cpp had %d slots busy, %d of them making progress; flit can't tell which was this call (not pinned to a slot)", len(busy), moving)
	}
	switch {
	case sl.DecodedDelta > 0 && retried:
		return fmt.Sprintf("llama.cpp was still generating when the call was retried (slot %d: %d tokens, %d more in %s; flit had %d output chunks): slow rather than stuck, unless flit had stopped receiving them (check the last byte time)",
			sl.Id, sl.Decoded, sl.DecodedDelta, gap, e.StreamedTokens)
	case sl.DecodedDelta > 0:
		return fmt.Sprintf("llama.cpp was still generating (slot %d: %d tokens, %d more in %s) %s (%d output chunks so far): the output isn't reaching flit (router or proxy buffering, network)",
			sl.Id, sl.Decoded, sl.DecodedDelta, gap, heard, e.StreamedTokens)
	case sl.PromptProcessedDelta > 0 && retried:
		return fmt.Sprintf("llama.cpp was still reading the prompt when the call was retried (slot %d: %d/%d, %d more in %s): slow rather than stuck; a retry starts the prompt over unless it is cached",
			sl.Id, sl.PromptProcessed, sl.PromptTokens, sl.PromptProcessedDelta, gap)
	case sl.PromptProcessedDelta > 0:
		return fmt.Sprintf("llama.cpp was still reading the prompt (slot %d: %d/%d, %d more in %s) %s: its progress reports aren't reaching flit (router or proxy buffering, network), or the stall limit is too short for this prompt",
			sl.Id, sl.PromptProcessed, sl.PromptTokens, sl.PromptProcessedDelta, gap, heard)
	case sl.Decoded == 0 && sl.PromptProcessed+sl.PromptCached < sl.PromptTokens:
		return fmt.Sprintf("llama.cpp's slot %d was reading the prompt (%d/%d) but got no further in %s: it may be in one very long batch, or llama.cpp or the GPU is stuck",
			sl.Id, sl.PromptProcessed, sl.PromptTokens, gap)
	}
	return fmt.Sprintf("llama.cpp's slot %d was busy but generated nothing in %s (%s): llama.cpp or the model itself is stuck",
		sl.Id, gap, slotText(sl))
}

func slotText(sl *flitv1.LlamaSlot) string {
	return fmt.Sprintf("prompt %d/%d, %d cached, %d generated", sl.PromptProcessed, sl.PromptTokens, sl.PromptCached, sl.Decoded)
}
