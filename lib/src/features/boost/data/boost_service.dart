import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _boostProxyUrl =
    'https://boostproxy-xr3swhwdua-uc.a.run.app';

class BoostService {
  BoostService({required this.tokenProvider});

  final Future<String?> Function() tokenProvider;

  Future<int> _getCreditsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final monthKey = '${currentYear}_$currentMonth';
    
    final savedMonth = prefs.getString('boost_credits_month');
    if (savedMonth != monthKey) {
      await prefs.setString('boost_credits_month', monthKey);
      await prefs.setInt('boost_credits', 100);
      return 100;
    }
    
    return prefs.getInt('boost_credits') ?? 100;
  }

  Future<void> _decrementCredit() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _getCreditsFromPrefs();
    if (current > 0) {
      await prefs.setInt('boost_credits', current - 1);
    }
  }

  Future<Map<String, dynamic>> boost({
    required String taskId,
    required String taskTitle,
    String? taskDescription,
    required String intent,
  }) async {
    final credits = await _getCreditsFromPrefs();
    if (credits <= 0) {
      throw Exception('no_credits');
    }

    final response = await http.post(
      Uri.parse(_boostProxyUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content': 'You are an AI assistant that helps boost task productivity. Provide actionable insights, breakdown the task, or draft a response based on the user intent.'
          },
          {
            'role': 'user',
            'content': 'Task Title: $taskTitle\n'
                '${taskDescription != null && taskDescription.isNotEmpty ? 'Description: $taskDescription\n' : ''}'
                'Intent: $intent\n\n'
                'Please provide a boost for this task.'
          }
        ],
      }),
    ).timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      throw Exception('Proxy error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['choices'][0]['message']['content'] as String;

    await _decrementCredit();
    final remaining = await _getCreditsFromPrefs();

    return {
      'result': result,
      'creditsRemaining': remaining,
    };
  }

  Future<int> fetchCredits() async {
    return await _getCreditsFromPrefs();
  }
}
