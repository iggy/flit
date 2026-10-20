package branches

import (
	"testing"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
)

func msg(seq int64, branch, id string) *flitv1.Event {
	return &flitv1.Event{Seq: seq, BranchId: branch, Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{MessageId: id}}}
}

func created(seq int64, id, parent string, fork int64) *flitv1.Event {
	return &flitv1.Event{Seq: seq, Payload: &flitv1.Event_BranchCreated{BranchCreated: &flitv1.BranchCreated{
		BranchId: id, ParentBranchId: parent, ForkSeq: fork,
	}}}
}

func ids(evs []*flitv1.Event) []string {
	var out []string
	for _, ev := range evs {
		if d := ev.GetMessageDone(); d != nil {
			out = append(out, d.MessageId)
		}
	}
	return out
}

func TestPath(t *testing.T) {
	// root: u1 a1 u2 a2; b1 forks after u2 (a retry): a2'; b2 forks from
	// b1 after a2' and before u3 (an edit of u3): u3' a3'.
	log := []*flitv1.Event{
		msg(1, "", "u1"), msg(2, "", "a1"), msg(3, "", "u2"), msg(4, "", "a2"),
		created(5, "b1", "", 3),
		msg(6, "b1", "a2'"), msg(7, "b1", "u3"), msg(8, "b1", "a3"),
		created(9, "b2", "b1", 6),
		msg(10, "b2", "u3'"), msg(11, "b2", "a3'"),
		{Seq: 12, BranchId: "b2", Payload: &flitv1.Event_TaskStateChanged{TaskStateChanged: &flitv1.TaskStateChanged{}}},
		msg(13, "", "late"), // never happens in practice; still only on root
	}
	tree := New(log)
	cases := map[string][]string{
		"":     {"u1", "a1", "u2", "a2", "late"},
		"b1":   {"u1", "a1", "u2", "a2'", "u3", "a3"},
		"b2":   {"u1", "a1", "u2", "a2'", "u3'", "a3'"},
		"nope": {"u1", "a1", "u2", "a2", "late"}, // unknown: the root
	}
	for b, want := range cases {
		got := ids(tree.Path(b).Filter(log))
		if len(got) != len(want) {
			t.Errorf("path %q = %v, want %v", b, got, want)
			continue
		}
		for i := range got {
			if got[i] != want[i] {
				t.Errorf("path %q = %v, want %v", b, got, want)
				break
			}
		}
	}
	// Session-wide events are on every path.
	for _, b := range []string{"", "b1", "b2"} {
		if !tree.Path(b).Contains(log[11]) {
			t.Errorf("task state change not on path %q", b)
		}
	}
	if a := tree.Ancestry("b2"); len(a) != 3 || a[0] != "b2" || a[1] != "b1" || a[2] != "" {
		t.Errorf("ancestry = %v", a)
	}
	if !tree.Forked() || New(nil).Forked() {
		t.Error("Forked wrong")
	}
}
