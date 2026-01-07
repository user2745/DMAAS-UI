import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/category.dart';

class CategoryApiService {
  final String baseUrl;
  final http.Client httpClient;

  CategoryApiService({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://dmaas.athletex.io',
    ),
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  Future<List<Category>> fetchAllCategories() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/categories'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<Category> createCategory({
    required String name,
    required String color,
  }) async {
    try {
      final payload = {
        'name': name,
        'color': color,
      };

      final response = await httpClient.post(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Category.fromJson(json);
      } else {
        throw Exception('Failed to create category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating category: $e');
    }
  }

  Future<Category> updateCategory({
    required String categoryId,
    required String name,
    required String color,
  }) async {
    try {
      final payload = {
        'name': name,
        'color': color,
      };

      final response = await httpClient.put(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Category.fromJson(json);
      } else {
        throw Exception('Failed to update category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/categories/$categoryId'),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting category: $e');
    }
  }
}
