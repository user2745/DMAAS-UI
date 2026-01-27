import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/field.dart';

class FieldApiService {
  final String baseUrl;
  final http.Client httpClient;
  final Future<String?> Function()? tokenProvider;

  FieldApiService({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://dmaas.athletex.io',
    ),
    http.Client? httpClient,
    this.tokenProvider,
  }) : httpClient = httpClient ?? http.Client();

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await tokenProvider?.call();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Field>> fetchFields() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/fields'),
        headers: await _headers(json: false),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Field.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fields: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching fields: $e');
    }
  }

  Future<Field> createField(Field field) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/fields'),
        headers: await _headers(),
        body: jsonEncode(field.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Field.fromJson(json);
      } else {
        throw Exception('Failed to create field: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating field: $e');
    }
  }

  Future<Field> updateField(String id, Field field) async {
    try {
      final response = await httpClient.put(
        Uri.parse('$baseUrl/fields/$id'),
        headers: await _headers(),
        body: jsonEncode(field.toJson()),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Field.fromJson(json);
      } else {
        throw Exception('Failed to update field: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating field: $e');
    }
  }

  Future<void> deleteField(String id) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/fields/$id'),
        headers: await _headers(json: false),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete field: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting field: $e');
    }
  }

  Future<List<Field>> syncFields(List<Field> fields) async {
    try {
      final payload = {
        'fields': fields.map((f) => f.toJson()).toList(),
      };

      final response = await httpClient.post(
        Uri.parse('$baseUrl/fields/sync'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Field.fromJson(json)).toList();
      } else {
        throw Exception('Failed to sync fields: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error syncing fields: $e');
    }
  }
}
