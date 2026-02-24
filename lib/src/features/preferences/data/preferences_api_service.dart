import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_preferences.dart';

class PreferencesApiService {
  PreferencesApiService({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://74-208-213-94.nip.io',
    ),
    http.Client? httpClient,
    this.tokenProvider,
  }) : httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client httpClient;
  final Future<String?> Function()? tokenProvider;

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = await tokenProvider?.call();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<UserPreferences> getPreferences() async {
    final response = await httpClient.get(
      Uri.parse('$baseUrl/preferences'),
      headers: await _headers(json: false),
    );
    if (response.statusCode == 200) {
      return UserPreferences.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    // Return defaults on error rather than throwing — preferences are
    // non-critical and should not block the UI.
    return const UserPreferences();
  }

  Future<UserPreferences> patchPreferences(Map<String, dynamic> patch) async {
    final response = await httpClient.patch(
      Uri.parse('$baseUrl/preferences'),
      headers: await _headers(),
      body: jsonEncode(patch),
    );
    if (response.statusCode == 200) {
      return UserPreferences.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to update preferences: ${response.statusCode}');
  }
}
