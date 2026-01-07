import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';

class TaskListApiService {
  final String baseUrl;
  final http.Client httpClient;

  TaskListApiService({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://dmaas.athletex.io:3302',
    ),
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  Future<List<TaskListItem>> fetchAllTasks() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/tasks'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TaskListItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  Future<List<TaskListItem>> fetchTasksByCategory(String categoryId) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/tasks?categoryId=$categoryId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TaskListItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  Future<TaskListItem> createTask({
    required String title,
    String? description,
    String status = 'todo',
    DateTime? dueDate,
    String? categoryId,
  }) async {
    try {
      final payload = {
        'title': title,
        if (description != null) 'description': description,
        'status': status,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (categoryId != null) 'categoryId': categoryId,
      };

      final response = await httpClient.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TaskListItem.fromJson(json);
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<TaskListItem> updateTask({
    required String taskId,
    required String title,
    String? description,
    String? status,
    DateTime? dueDate,
    String? categoryId,
  }) async {
    try {
      final payload = {
        'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (categoryId != null) 'categoryId': categoryId,
      };

      final response = await httpClient.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TaskListItem.fromJson(json);
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
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }
}
