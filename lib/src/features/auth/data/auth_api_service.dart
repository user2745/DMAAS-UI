import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiService {
  final String baseUrl;
  final http.Client httpClient;

  AuthApiService({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  Future<(String token, Map<String, dynamic> user)> login(
    String email,
    String password,
  ) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          json['token'] as String,
          json['user'] as Map<String, dynamic>,
        );
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  Future<(String token, Map<String, dynamic> user)> register(
    String email,
    String password,
    String? name,
  ) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          json['token'] as String,
          json['user'] as Map<String, dynamic>,
        );
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }
}
