package modelsvc

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"
	"time"

	"connectrpc.com/connect"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/store"
)

func TestFavoritesRecentsAndLoad(t *testing.T) {
	provider := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{"data":[{"id":"a","owned_by":"x"},{"id":"b","owned_by":"x"}]}`))
	}))
	defer provider.Close()
	cfg := config.Default()
	cfg.Providers = []config.Provider{{Name: "p", BaseURL: provider.URL + "/v1"}}
	cat := models.NewCatalog(func() config.Config { return cfg }, func() string { return "" }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	ctx := context.Background()
	if err := cat.Refresh(ctx, ""); err != nil {
		t.Fatal(err)
	}
	st, err := store.Open(ctx, filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	defer st.Close()
	svc := &Models{Catalog: cat, Store: st}

	if _, err := svc.SetFavorite(ctx, connect.NewRequest(&flitv1.SetFavoriteRequest{Provider: "p", Model: "b", Favorite: true})); err != nil {
		t.Fatal(err)
	}
	used := time.Unix(2000, 0)
	if err := st.TouchModel(ctx, store.DefaultTeamID, store.ModelKey{Provider: "p", Model: "a"}, used); err != nil {
		t.Fatal(err)
	}
	res, err := svc.ListModels(ctx, connect.NewRequest(&flitv1.ListModelsRequest{}))
	if err != nil {
		t.Fatal(err)
	}
	got := map[string]*flitv1.Model{}
	for _, m := range res.Msg.Models {
		got[m.Id] = m
	}
	if a := got["a"]; a.Favorite || !a.LastUsed.AsTime().Equal(used) || a.State != flitv1.ModelState_MODEL_STATE_UNSPECIFIED {
		t.Fatalf("a = %v", a)
	}
	if b := got["b"]; !b.Favorite || b.LastUsed != nil {
		t.Fatalf("b = %v", b)
	}

	if _, err := svc.SetFavorite(ctx, connect.NewRequest(&flitv1.SetFavoriteRequest{Provider: "p"})); connect.CodeOf(err) != connect.CodeInvalidArgument {
		t.Fatalf("no model: %v", err)
	}
	if _, err := svc.LoadModel(ctx, connect.NewRequest(&flitv1.LoadModelRequest{Provider: "p", Model: "a"})); connect.CodeOf(err) != connect.CodeFailedPrecondition {
		t.Fatalf("load on a non-router: %v", err)
	}
}
