// P1-02 acceptance: decode the §8 `model.options` example from
// docs/reference/03-mvp-wire-shapes.md → CurrentModel + List<ModelProvider>.

import 'dart:convert';

import 'package:flit/data/dto/model_options_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Verbatim §8 example.
  const frame = '''
{
  "jsonrpc":"2.0","id":"r6",
  "result":{
    "model":"hermes-4-405b",
    "provider":"nous",
    "providers":[
      {"name":"Nous Portal","slug":"nous","authenticated":true,"is_current":true,
       "auth_type":"oauth","key_env":"NOUS_API_KEY","models":["hermes-4-405b","hermes-4-70b"],
       "total_models":2},
      {"name":"OpenRouter","slug":"openrouter","authenticated":false,
       "key_env":"OPENROUTER_API_KEY","models":[],"warning":"no key"}
    ]
  }
}''';

  test('maps the current model', () {
    final dto = ModelOptionsResultDto.fromJson(
      (jsonDecode(frame) as Map<String, dynamic>)['result']
          as Map<String, dynamic>,
    );

    final current = dto.toCurrentModel();
    expect(current.model, 'hermes-4-405b');
    expect(current.provider, 'nous');
  });

  test('maps providers with auth state, warning, and models list', () {
    final dto = ModelOptionsResultDto.fromJson(
      (jsonDecode(frame) as Map<String, dynamic>)['result']
          as Map<String, dynamic>,
    );

    final providers = dto.toProviders();
    expect(providers, hasLength(2));

    final nous = providers[0];
    expect(nous.name, 'Nous Portal');
    expect(nous.slug, 'nous');
    expect(nous.authenticated, isTrue);
    expect(nous.isCurrent, isTrue);
    expect(nous.authType, 'oauth');
    expect(nous.keyEnv, 'NOUS_API_KEY');
    expect(nous.models, ['hermes-4-405b', 'hermes-4-70b']);
    expect(nous.totalModels, 2);
    expect(nous.warning, isNull);

    final openrouter = providers[1];
    expect(openrouter.name, 'OpenRouter');
    expect(openrouter.slug, 'openrouter');
    expect(openrouter.authenticated, isFalse);
    expect(openrouter.isCurrent, isFalse);
    expect(openrouter.authType, isNull);
    expect(openrouter.keyEnv, 'OPENROUTER_API_KEY');
    expect(openrouter.models, isEmpty);
    expect(openrouter.totalModels, isNull);
    expect(openrouter.warning, 'no key');
  });

  test('parses per-model capability metadata', () {
    final provider = ModelProviderDto.fromJson({
      'name': 'Nous Portal',
      'slug': 'nous',
      'authenticated': true,
      'models': ['hermes-4-405b'],
      'capabilities': {
        'hermes-4-405b': {
          'context_window': 200000,
          'max_output_tokens': 8192,
          'reasoning': true,
          'tools': true,
          'vision': true,
          'input_modalities': ['text', 'image'],
          'output_modalities': ['text'],
          'reasoning_levels': ['low', 'medium', 'high'],
          'can_disable_reasoning': true,
        },
      },
    }).toDomain();

    final details = provider.modelDetails['hermes-4-405b'];
    expect(details, isNotNull);
    expect(details!.contextWindow, 200000);
    expect(details.maxOutputTokens, 8192);
    expect(details.reasoning, isTrue);
    expect(details.tools, isTrue);
    expect(details.vision, isTrue);
    expect(details.inputModalities, ['text', 'image']);
    expect(details.reasoningLevels, ['low', 'medium', 'high']);
    expect(details.canDisableReasoning, isTrue);
  });

  test('flattens providers into pickable ModelOptions', () {
    final dto = ModelOptionsResultDto.fromJson(
      (jsonDecode(frame) as Map<String, dynamic>)['result']
          as Map<String, dynamic>,
    );

    final options = dto.toModelOptions();
    expect(options, hasLength(2));
    expect(options[0].providerSlug, 'nous');
    expect(options[0].model, 'hermes-4-405b');
    expect(options[1].providerSlug, 'nous');
    expect(options[1].model, 'hermes-4-70b');
  });
}
