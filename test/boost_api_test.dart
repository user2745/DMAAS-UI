import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  test('DeepSeek API direct call', () async {
    const apiKey = 'sk-dd93a332c5344496aa2c9bd767412035';

    final response = await http.post(
      Uri.parse('https://api.deepseek.com/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'user', 'content': 'Say hello in one word.'}
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    expect(response.statusCode, 200);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['choices'][0]['message']['content'] as String;
    print('Result: $result');
    expect(result, isNotEmpty);
  });
}
