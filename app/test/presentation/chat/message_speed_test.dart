import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/usage.dart';
import 'package:flit/presentation/chat/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(ChatMessage message) => MaterialApp(
  home: Scaffold(
    body: ListView(children: <Widget>[MessageBubble(message: message)]),
  ),
);

ChatMessage _reply({CallSpeed? speed, bool streaming = false}) => ChatMessage(
  role: MessageRole.assistant,
  text: 'answer',
  streaming: streaming,
  usage: Usage(input: 100, output: 10, speed: speed),
);

void main() {
  test('speedCaptionText', () {
    expect(
      speedCaptionText(
        const CallSpeed(
          timeToFirstTokenMs: 900,
          promptTokensPerSecond: 1300.4,
          generationTokensPerSecond: 45.56,
          cachedTokens: 40000,
          inputTokens: 48000,
        ),
      ),
      '45.6 tok/s · prompt 1300 tok/s · first token 900ms · 40k/48k cached',
    );
    expect(
      speedCaptionText(
        const CallSpeed(timeToFirstTokenMs: 2500, generationTokensPerSecond: 8),
      ),
      '8.0 tok/s · first token 2.5s',
    );
  });

  testWidgets('a finished reply shows how fast it was', (tester) async {
    await tester.pumpWidget(
      _app(
        _reply(
          speed: const CallSpeed(
            promptTokensPerSecond: 250,
            generationTokensPerSecond: 40.5,
            source: 'llama.cpp',
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(messageSpeedKey),
        matching: find.text('40.5 tok/s · prompt 250 tok/s'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'no caption without timings, with nothing to show, or mid-stream',
    (tester) async {
      await tester.pumpWidget(_app(_reply()));
      expect(find.byKey(messageSpeedKey), findsNothing);

      await tester.pumpWidget(_app(_reply(speed: const CallSpeed())));
      expect(find.byKey(messageSpeedKey), findsNothing);

      await tester.pumpWidget(
        _app(
          _reply(
            speed: const CallSpeed(generationTokensPerSecond: 10),
            streaming: true,
          ),
        ),
      );
      expect(find.byKey(messageSpeedKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
