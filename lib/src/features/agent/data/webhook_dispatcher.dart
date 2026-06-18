import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fire-and-forget webhook dispatcher to the DMAAS agent-service.
/// Sends task mutations so the Semantic Desk stays in sync.
class WebhookDispatcher {
  WebhookDispatcher({
    this.agentBaseUrl = const String.fromEnvironment(
      'AGENT_BASE_URL',
      defaultValue: 'https://dmaas-agent-xr3swhwdua-uc.a.run.app',
    ),
    this.webhookSecret = const String.fromEnvironment(
      'WEBHOOK_SECRET',
      defaultValue: 'dev-webhook-secret',
    ),
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String agentBaseUrl;
  final String webhookSecret;
  final http.Client _client;

  String? _userId;

  void setUserId(String userId) {
    _userId = userId;
  }

  /// Dispatch a task webhook event. Fire-and-forget — errors are silently logged.
  Future<void> dispatch({
    required String event,
    required Map<String, dynamic> task,
    String? boardId,
  }) async {
    if (_userId == null) return;

    try {
      await _client.post(
        Uri.parse('$agentBaseUrl/webhooks/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Secret': webhookSecret,
        },
        body: jsonEncode({
          'event': event,
          'userId': _userId,
          'boardId': boardId,
          'task': task,
        }),
      );
    } catch (_) {
      // Fire and forget — don't block the UI for webhook failures.
    }
  }

  /// Convenience: notify that a task was created.
  Future<void> taskCreated(Map<String, dynamic> taskJson, {String? boardId}) =>
      dispatch(event: 'task.created', task: taskJson, boardId: boardId);

  /// Convenience: notify that a task was updated.
  Future<void> taskUpdated(Map<String, dynamic> taskJson, {String? boardId}) =>
      dispatch(event: 'task.updated', task: taskJson, boardId: boardId);

  /// Convenience: notify that a task was deleted.
  Future<void> taskDeleted(String taskId) =>
      dispatch(event: 'task.deleted', task: {'id': taskId});
}
