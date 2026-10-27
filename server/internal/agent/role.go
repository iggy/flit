package agent

import (
	"context"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/roles"
	"github.com/iggy/flit/server/internal/store"
)

// SetRole switches the session's role (empty: none), effective from its
// next model call: the system prompt is built from the role each call.
// The model and effort follow the new role's defaults where the session
// still has the old role's (see roleDefaults); ones changed since (by
// SetModel, SetEffort or at creation) stay. client names who changed it,
// for the log.
func (m *Manager) SetRole(ctx context.Context, id, role, client string) (store.Session, error) {
	r, err := m.role(role)
	if err != nil {
		return store.Session{}, err
	}
	s, err := m.session(ctx, id)
	if err != nil {
		return store.Session{}, err
	}
	return s.setRole(ctx, r, client)
}

// roleDefaults is the model and effort Create gives a session with role
// r (nil: none) that names neither: the role's, else the config's chat
// model.
func (m *Manager) roleDefaults(r *roles.Role) (provider, model, effort string, err error) {
	if r != nil {
		if r.Provider != "" {
			provider, model = r.Provider, r.Model
		}
		effort = r.Effort
	}
	if provider == "" {
		chat := m.cfg().ChatModel()
		if chat.Provider != "" {
			provider, model = chat.Provider, chat.Model
			if effort == "" {
				effort = chat.Effort
			}
		}
	}
	provider, model, err = m.resolveModel(provider, model)
	return provider, model, effort, err
}

func (s *session) setRole(ctx context.Context, r *roles.Role, client string) (store.Session, error) {
	name := ""
	if r != nil {
		name = r.Name
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if name == s.info.Role {
		return s.info, nil
	}
	provider, model, effort := s.info.Provider, s.info.Model, s.info.Effort
	// What the old role gave the session. If it can't be worked out (the
	// role file is gone or broken, a provider was removed), treat the
	// session's model and effort as chosen and keep them.
	old, err := s.m.role(s.info.Role)
	if err == nil {
		var op, om, oe string
		op, om, oe, err = s.m.roleDefaults(old)
		if err == nil {
			followModel := provider == op && model == om
			followEffort := effort == oe
			if followModel || followEffort {
				np, nm, ne, err := s.m.roleDefaults(r)
				if err != nil {
					return store.Session{}, err
				}
				if followModel && np != "" && nm != "" {
					provider, model = np, nm
				}
				if followEffort {
					effort = ne
				}
			}
		}
	}

	if _, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_RoleChanged{RoleChanged: &flitv1.RoleChanged{
		Role: name, PreviousRole: s.info.Role, Client: client,
	}}}); err != nil {
		return store.Session{}, err
	}
	if provider == s.info.Provider && model == s.info.Model && effort == s.info.Effort {
		return s.info, nil
	}
	if provider != s.info.Provider || model != s.info.Model {
		if err := s.m.store.SetModel(ctx, s.info.ID, provider, model); err != nil {
			return store.Session{}, err
		}
		s.info.Provider, s.info.Model = provider, model
	}
	if effort != s.info.Effort {
		if err := s.m.store.SetEffort(ctx, s.info.ID, effort); err != nil {
			return store.Session{}, err
		}
		s.info.Effort = effort
	}
	if _, err := s.appendLocked(s.modelChangedLocked()); err != nil {
		return store.Session{}, err
	}
	s.m.touchModel(s.info)
	return s.info, nil
}
