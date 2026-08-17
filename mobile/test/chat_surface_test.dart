import 'package:aetherride_mobile/domain/ai/chat_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('402 and HTML bodies are unavailable, not a status dump', () {
    expect(
      chatSurfaceFault(statusCode: 402, jsonText: null, jsonError: null),
      ChatSurfaceFault.unavailable,
    );
    expect(
      chatSurfaceFault(statusCode: 500, jsonError: 'r.bike.setups is not iterable'),
      ChatSurfaceFault.unavailable,
    );
  });

  test('429 stays a limit', () {
    expect(
      chatSurfaceFault(statusCode: 429, jsonText: 'too many'),
      ChatSurfaceFault.limit,
    );
  });

  test('ok JSON with rider copy stays ok', () {
    expect(
      chatSurfaceFault(
        statusCode: 200,
        jsonText: 'In deiner Garage: Mein Bike.',
      ),
      isNull,
    );
  });

  test('200 with engine dump is unavailable', () {
    expect(
      chatSurfaceFault(
        statusCode: 200,
        jsonText: 'r.bike.setups is not iterable',
      ),
      ChatSurfaceFault.unavailable,
    );
  });

  test('persisted Fehler 402 is rewritten', () {
    expect(
      sanitizeStoredAssistantText('Fehler 402', fallback: 'später'),
      'später',
    );
    expect(
      sanitizeStoredAssistantText(
        'r.bike.setups is not iterable',
        fallback: 'später',
      ),
      'später',
    );
    expect(
      sanitizeStoredAssistantText('In deiner Garage: Focus.', fallback: 'x'),
      'In deiner Garage: Focus.',
    );
  });
}
