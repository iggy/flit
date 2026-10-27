package llamacpp

import (
	"encoding/json"
	"testing"
)

// next_token is an object on older servers and a list on newer ones.
func TestSlotNextTokenShapes(t *testing.T) {
	for name, body := range map[string]string{
		"list":   `{"id":2,"n_ctx":4096,"is_processing":true,"id_task":7,"n_prompt_tokens":48000,"n_prompt_tokens_processed":41000,"n_prompt_tokens_cache":1000,"next_token":[{"has_next_token":true,"n_decoded":312}]}`,
		"object": `{"id":2,"n_ctx":4096,"is_processing":true,"id_task":7,"n_prompt_tokens":48000,"n_prompt_tokens_processed":41000,"n_prompt_tokens_cache":1000,"next_token":{"has_next_token":true,"n_decoded":312}}`,
	} {
		var s Slot
		if err := json.Unmarshal([]byte(body), &s); err != nil {
			t.Fatal(name, err)
		}
		want := Slot{ID: 2, NCtx: 4096, IsProcessing: true, IDTask: 7, NPromptTokens: 48000, NPromptTokensProcessed: 41000, NPromptTokensCache: 1000, NDecoded: 312}
		if s != want {
			t.Fatalf("%s: %+v", name, s)
		}
	}
	var s Slot
	if err := json.Unmarshal([]byte(`{"id":0,"is_processing":false}`), &s); err != nil || s.NDecoded != 0 {
		t.Fatalf("no next_token: %+v %v", s, err)
	}
}
