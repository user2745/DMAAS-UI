import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// SSE client for the DMAAS agent service.
class AgentService {
  AgentService({required this.tokenProvider});

  final Future<String?> Function() tokenProvider;

  // TODO(security): Move to environment config, not hardcoded
  static const String _agentUrl = 'https://dmaas-agent-xr3swhwdua-uc.a.run.app/agent';

  /// Send a message and stream back agent events via SSE.
  /// Returns a stream of parsed event maps.
  Stream<Map<String, dynamic>> sendMessage({
    required String message,
    List<Map<String, dynamic>>? history,
    String? model,
    Map<String, dynamic>? taskContext,
  }) async* {
    final token = await tokenProvider();
    if (token == null) {
      yield {'type': 'error', 'data': 'Not authenticated'};
      return;
    }

    final body = jsonEncode({
      'message': message,
      if (history != null) 'history': history,
      if (model != null) 'model': model,
      if (taskContext != null) 'taskContext': taskContext,
    });

    final request = http.Request('POST', Uri.parse(_agentUrl));
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    request.body = body;

    final client = http.Client();

    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        yield {'type': 'error', 'data': 'HTTP ${response.statusCode}: $errorBody'};
        return;
      }

      // Parse SSE stream
      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty) continue;

          try {
            final event = jsonDecode(jsonStr) as Map<String, dynamic>;
            yield event;

            if (event['type'] == 'done' || event['type'] == 'error') {
              return;
            }
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }
    } catch (e) {
      yield {'type': 'error', 'data': 'Connection error: $e'};
    } finally {
      client.close();
    }
  }
}
