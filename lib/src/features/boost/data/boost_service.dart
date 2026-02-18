import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'http://74.208.213.94:3302';

class BoostService {
  BoostService({required this.tokenProvider});

  final Future<String?> Function() tokenProvider;

  Future<Map<String, dynamic>> boost({
    required String taskId,
    required String taskTitle,
    String? taskDescription,
    required String intent,
  }) async {
    final token = await tokenProvider();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/boost'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'taskId': taskId,
        'taskTitle': taskTitle,
        if (taskDescription != null && taskDescription.isNotEmpty)
          'taskDescription': taskDescription,
        'intent': intent,
      }),
    ).timeout(const Duration(seconds: 90));

    if (response.statusCode == 402) {
      throw Exception('no_credits');
    }
    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<int> fetchCredits() async {
    final token = await tokenProvider();
    if (token == null) return 0;

    final response = await http.get(
      Uri.parse('$_baseUrl/boost/credits'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['credits'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}
