// P3-04 acceptance: fold `subagent.*` event sequences into a spawn tree
// keyed by `subagent_id` / `parent_id`.

import 'package:flit/application/subagents/spawn_tree_fold.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/subagent_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foldSubagentEvent', () {
    test('event with null subagent_id is a no-op', () {
      const state = SpawnTreeState();
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.spawn_requested',
                goal: 'Scout',
                taskCount: 1,
                taskIndex: 0,
                subagentId: null, // Thin event.
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      expect(next, state);
      expect(next.nodes, isEmpty);
      expect(next.order, isEmpty);
    });

    test('subagent.start creates a new node with running status', () {
      const state = SpawnTreeState();
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.start',
                goal: 'Analyze logs',
                taskCount: 5,
                taskIndex: 1,
                subagentId: 'agent-123',
                parentId: 'root',
                depth: 1,
                model: 'sonnet',
                text: 'Starting analysis',
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      expect(next.nodes, hasLength(1));
      expect(next.order, ['agent-123']);
      final node = next.nodes['agent-123']!;
      expect(node.id, 'agent-123');
      expect(node.parentId, 'root');
      expect(node.depth, 1);
      expect(node.goal, 'Analyze logs');
      expect(node.model, 'sonnet');
      expect(node.status, SubagentStatus.running);
      expect(node.lastActivity, 'Starting analysis');
    });

    test('nested start with parent_id links child to parent', () {
      const parent = SubagentNode(id: 'parent-1', goal: 'Root task');
      final state = SpawnTreeState(
        nodes: {'parent-1': parent},
        order: ['parent-1'],
      );
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.start',
                goal: 'Subtask',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'child-1',
                parentId: 'parent-1',
                depth: 1,
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      expect(next.nodes, hasLength(2));
      expect(next.order, ['parent-1', 'child-1']);
      final child = next.nodes['child-1']!;
      expect(child.parentId, 'parent-1');
      expect(child.depth, 1);
    });

    test('subagent.thinking updates lastActivity and status', () {
      const node = SubagentNode(
        id: 'agent-1',
        goal: 'Task',
        status: SubagentStatus.running,
      );
      final state = SpawnTreeState(
        nodes: {'agent-1': node},
        order: ['agent-1'],
      );
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.thinking',
                goal: 'Task',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-1',
                text: 'Thinking about X',
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      final updated = next.nodes['agent-1']!;
      expect(updated.status, SubagentStatus.thinking);
      expect(updated.lastActivity, 'Thinking about X');
    });

    test('subagent.tool updates lastToolName and lastActivity', () {
      const node = SubagentNode(id: 'agent-1', goal: 'Task');
      final state = SpawnTreeState(
        nodes: {'agent-1': node},
        order: ['agent-1'],
      );
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.tool',
                goal: 'Task',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-1',
                toolName: 'shell',
                toolPreview: 'ls -la',
                text: 'List files',
                toolCount: 3,
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      final updated = next.nodes['agent-1']!;
      expect(updated.lastToolName, 'shell');
      expect(updated.lastActivity, 'ls -la'); // toolPreview supersedes text.
      expect(updated.toolCount, 3);
    });

    test('subagent.tool with only text (no preview) uses text', () {
      const node = SubagentNode(id: 'agent-1', goal: 'Task');
      final state = SpawnTreeState(
        nodes: {'agent-1': node},
        order: ['agent-1'],
      );
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.tool',
                goal: 'Task',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-1',
                toolName: 'read',
                text: 'Reading file.txt',
                toolCount: 1,
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      final updated = next.nodes['agent-1']!;
      expect(updated.lastActivity, 'Reading file.txt');
    });

    test('subagent.progress updates lastActivity', () {
      const node = SubagentNode(
        id: 'agent-1',
        goal: 'Task',
        lastActivity: 'Old status',
      );
      final state = SpawnTreeState(
        nodes: {'agent-1': node},
        order: ['agent-1'],
      );
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.progress',
                goal: 'Task',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-1',
                text: 'Progress: 50%',
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      final updated = next.nodes['agent-1']!;
      expect(updated.lastActivity, 'Progress: 50%');
    });

    test('subagent.complete sets terminal status + summary + rollups', () {
      const node = SubagentNode(
        id: 'agent-1',
        goal: 'Task',
        status: SubagentStatus.running,
        inputTokens: 100,
        outputTokens: 50,
      );
      final state = SpawnTreeState(
        nodes: {'agent-1': node},
        order: ['agent-1'],
      );
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.complete',
                goal: 'Task',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-1',
                status: 'completed',
                summary: 'Task done',
                durationSeconds: 12.5,
                costUsd: 0.05,
                inputTokens: 1000,
                outputTokens: 500,
                reasoningTokens: 200,
                apiCalls: 3,
                filesRead: ['a.txt', 'b.txt'],
                filesWritten: ['out.txt'],
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      final updated = next.nodes['agent-1']!;
      expect(updated.status, SubagentStatus.completed);
      expect(updated.summary, 'Task done');
      expect(
        updated.lastActivity,
        'Task done',
      ); // summary supersedes old activity.
      expect(updated.durationSeconds, 12.5);
      expect(updated.costUsd, 0.05);
      expect(updated.inputTokens, 1000); // Rolled up.
      expect(updated.outputTokens, 500);
      expect(updated.reasoningTokens, 200);
      expect(updated.apiCalls, 3);
      expect(updated.filesRead, ['a.txt', 'b.txt']);
      expect(updated.filesWritten, ['out.txt']);
    });

    test('subagent.complete with error status sets error', () {
      const node = SubagentNode(
        id: 'agent-1',
        goal: 'Task',
        status: SubagentStatus.running,
      );
      final state = SpawnTreeState(
        nodes: {'agent-1': node},
        order: ['agent-1'],
      );
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.complete',
                goal: 'Task',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-1',
                status: 'error',
                summary: 'Failed',
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      final updated = next.nodes['agent-1']!;
      expect(updated.status, SubagentStatus.error);
      expect(updated.summary, 'Failed');
    });

    test('two siblings preserve order', () {
      const state = SpawnTreeState();
      const event1 =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.start',
                goal: 'Task A',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-a',
              )
              as SubagentEvent;
      const event2 =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.start',
                goal: 'Task B',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-b',
              )
              as SubagentEvent;

      final next1 = foldSubagentEvent(state, event1);
      final next2 = foldSubagentEvent(next1, event2);

      expect(next2.nodes, hasLength(2));
      expect(next2.order, ['agent-a', 'agent-b']);
    });

    test('updates to existing nodes do not change order', () {
      const node = SubagentNode(id: 'agent-1', goal: 'Task');
      final state = SpawnTreeState(
        nodes: {'agent-1': node},
        order: ['agent-1'],
      );
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.progress',
                goal: 'Task',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-1',
                text: 'Update',
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      expect(next.order, ['agent-1']); // Order unchanged.
    });

    test('merge is defensive: null fields do not overwrite existing', () {
      const node = SubagentNode(
        id: 'agent-1',
        goal: 'Task',
        inputTokens: 100,
        filesRead: ['a.txt'],
      );
      final state = SpawnTreeState(
        nodes: {'agent-1': node},
        order: ['agent-1'],
      );
      const event =
          TypedGatewayEvent.subagentEvent(
                sessionId: 's1',
                type: 'subagent.complete',
                goal: 'Task',
                taskCount: 1,
                taskIndex: 0,
                subagentId: 'agent-1',
                status: 'completed',
                // inputTokens, filesRead are null in this event.
              )
              as SubagentEvent;

      final next = foldSubagentEvent(state, event);

      final updated = next.nodes['agent-1']!;
      expect(updated.inputTokens, 100); // Preserved from node.
      expect(updated.filesRead, ['a.txt']); // Preserved.
    });
  });
}
