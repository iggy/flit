package learn

import (
	"context"
	"errors"

	"connectrpc.com/connect"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/memory"
	"github.com/iggy/flit/server/internal/store"
)

// API implements flitv1connect.LearningServiceHandler.
type API struct {
	S *Service
}

func apiErr(err error) error {
	if err == nil {
		return nil
	}
	code := connect.CodeInternal
	switch {
	case errors.Is(err, store.ErrNotFound):
		code = connect.CodeNotFound
	case errors.Is(err, ErrDecided), errors.Is(err, memory.ErrChanged), errors.Is(err, ErrNoModel):
		code = connect.CodeFailedPrecondition
	case errors.Is(err, context.Canceled):
		code = connect.CodeCanceled
	}
	return connect.NewError(code, err)
}

func required(name, v string) error {
	if v == "" {
		return connect.NewError(connect.CodeInvalidArgument, errors.New(name+" is required"))
	}
	return nil
}

// Learn implements flitv1connect.LearningServiceHandler.
func (a *API) Learn(ctx context.Context, req *connect.Request[flitv1.LearnRequest]) (*connect.Response[flitv1.LearnResponse], error) {
	if err := required("session_id", req.Msg.SessionId); err != nil {
		return nil, err
	}
	res, err := a.S.Run(ctx, req.Msg.SessionId, false)
	if err != nil {
		return nil, apiErr(err)
	}
	out := &flitv1.LearnResponse{Dropped: res.Dropped, Provider: res.Provider, Model: res.Model}
	for _, p := range res.Proposals {
		out.Proposals = append(out.Proposals, ProposalProto(p))
	}
	return connect.NewResponse(out), nil
}

// ListLearnProposals implements flitv1connect.LearningServiceHandler.
func (a *API) ListLearnProposals(ctx context.Context, req *connect.Request[flitv1.ListLearnProposalsRequest]) (*connect.Response[flitv1.ListLearnProposalsResponse], error) {
	list, err := a.S.Store.ListProposals(ctx, req.Msg.SessionId, req.Msg.IncludeDecided)
	if err != nil {
		return nil, apiErr(err)
	}
	out := &flitv1.ListLearnProposalsResponse{}
	for _, p := range list {
		out.Proposals = append(out.Proposals, ProposalProto(p))
	}
	return connect.NewResponse(out), nil
}

// AcceptLearnProposal implements flitv1connect.LearningServiceHandler.
func (a *API) AcceptLearnProposal(ctx context.Context, req *connect.Request[flitv1.AcceptLearnProposalRequest]) (*connect.Response[flitv1.AcceptLearnProposalResponse], error) {
	if err := required("id", req.Msg.Id); err != nil {
		return nil, err
	}
	p, err := a.S.Accept(ctx, req.Msg.Id, req.Msg.Text)
	if err != nil {
		return nil, apiErr(err)
	}
	return connect.NewResponse(&flitv1.AcceptLearnProposalResponse{Proposal: ProposalProto(p)}), nil
}

// RejectLearnProposal implements flitv1connect.LearningServiceHandler.
func (a *API) RejectLearnProposal(ctx context.Context, req *connect.Request[flitv1.RejectLearnProposalRequest]) (*connect.Response[flitv1.RejectLearnProposalResponse], error) {
	if err := required("id", req.Msg.Id); err != nil {
		return nil, err
	}
	p, err := a.S.Reject(ctx, req.Msg.Id)
	if err != nil {
		return nil, apiErr(err)
	}
	return connect.NewResponse(&flitv1.RejectLearnProposalResponse{Proposal: ProposalProto(p)}), nil
}
