import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';

class TaskApiService {
  final String baseUrl;
  final http.Client httpClient;
  final String? Function()? authTokenProvider;
  final String? Function()? anonymousIdProvider;

  TaskApiService({
    this.baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://dmaas.athletex.io'),
    http.Client? httpClient,
    this.authTokenProvider,
    this.anonymousIdProvider,
  }) : httpClient = httpClient ?? http.Client();

  Map<String, String> _headers([Map<String, String>? extras]) {
    final headers = {'Content-Type': 'application/json', ...?extras};
    final token = authTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final anonId = anonymousIdProvider?.call();
    if (anonId != null && anonId.isNotEmpty) {
      headers['X-Anonymous-Id'] = anonId;
    }
    return headers;
  }

  Future<List<Task>> fetchAllTasks() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/tasks'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  Future<Task> createTask({
    required String title,
    String? description,
    String status = 'todo',
    DateTime? dueDate,
  }) async {
    try {
      final payload = {
        'title': title,
        if (description != null) 'description': description,
        'status': status,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      };

      final response = await httpClient.post(
        Uri.parse('$baseUrl/tasks'),
        headers: _headers(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<Task> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? status,
    DateTime? dueDate,
    Map<String, Object?>? fieldValues,
  }) async {
    try {
      final payload = {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (fieldValues != null)
          'fieldValues': fieldValues.map((key, value) {
            if (value is DateTime) {
              return MapEntry(key, value.toIso8601String());
            }
            return MapEntry(key, value);
          }),
      };

      final response = await httpClient.patch(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: _headers(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: _headers(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }
}
