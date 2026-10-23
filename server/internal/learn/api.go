package learn

import (
	"context"
	"errors"

	"connectrpc.com/connect/v2"

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
	return connect.NewError(code, err.Error())
}

func required(name, v string) error {
	if v == "" {
		return connect.NewError(connect.CodeInvalidArgument, errors.New(name+" is required").Error())
	}
	return nil
}

// Learn implements flitv1connect.LearningServiceHandler.
func (a *API) Learn(ctx context.Context, req *flitv1.LearnRequest) (*flitv1.LearnResponse, error) {
	if err := required("session_id", req.SessionId); err != nil {
		return nil, err
	}
	res, err := a.S.Run(ctx, req.SessionId, false)
	if err != nil {
		return nil, apiErr(err)
	}
	out := &flitv1.LearnResponse{Dropped: res.Dropped, Provider: res.Provider, Model: res.Model}
	for _, p := range res.Proposals {
		out.Proposals = append(out.Proposals, ProposalProto(p))
	}
	return out, nil
}

// ListLearnProposals implements flitv1connect.LearningServiceHandler.
func (a *API) ListLearnProposals(ctx context.Context, req *flitv1.ListLearnProposalsRequest) (*flitv1.ListLearnProposalsResponse, error) {
	list, err := a.S.Store.ListProposals(ctx, req.SessionId, req.IncludeDecided)
	if err != nil {
		return nil, apiErr(err)
	}
	out := &flitv1.ListLearnProposalsResponse{}
	for _, p := range list {
		out.Proposals = append(out.Proposals, ProposalProto(p))
	}
	return out, nil
}

// AcceptLearnProposal implements flitv1connect.LearningServiceHandler.
func (a *API) AcceptLearnProposal(ctx context.Context, req *flitv1.AcceptLearnProposalRequest) (*flitv1.AcceptLearnProposalResponse, error) {
	if err := required("id", req.Id); err != nil {
		return nil, err
	}
	p, err := a.S.Accept(ctx, req.Id, req.Text)
	if err != nil {
		return nil, apiErr(err)
	}
	return &flitv1.AcceptLearnProposalResponse{Proposal: ProposalProto(p)}, nil
}

// RejectLearnProposal implements flitv1connect.LearningServiceHandler.
func (a *API) RejectLearnProposal(ctx context.Context, req *flitv1.RejectLearnProposalRequest) (*flitv1.RejectLearnProposalResponse, error) {
	if err := required("id", req.Id); err != nil {
		return nil, err
	}
	p, err := a.S.Reject(ctx, req.Id)
	if err != nil {
		return nil, apiErr(err)
	}
	return &flitv1.RejectLearnProposalResponse{Proposal: ProposalProto(p)}, nil
}
