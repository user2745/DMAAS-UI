import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result from a smart search query.
class SmartSearchResult {
  final String summary;
  final List<SmartSearchTask> tasks;
  final int total;

  SmartSearchResult({
    required this.summary,
    required this.tasks,
    required this.total,
  });

  factory SmartSearchResult.fromJson(Map<String, dynamic> json) {
    return SmartSearchResult(
      summary: json['summary'] as String? ?? '',
      tasks: (json['results'] as List<dynamic>?)
              ?.map((r) => SmartSearchTask.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
    );
  }
}

class SmartSearchTask {
  final String id;
  final String title;
  final String? description;
  final String? status;
  final String? dueDate;
  final String? assignee;
  final double score;

  SmartSearchTask({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.dueDate,
    this.assignee,
    required this.score,
  });

  factory SmartSearchTask.fromJson(Map<String, dynamic> json) {
    final task = json['task'] as Map<String, dynamic>? ?? {};
    return SmartSearchTask(
      id: task['id'] as String? ?? '',
      title: task['title'] as String? ?? '',
      description: task['description'] as String?,
      status: task['status'] as String?,
      dueDate: task['dueDate'] as String?,
      assignee: task['assignee'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Client for the agent-service smart search endpoint.
class SmartSearchService {
  SmartSearchService({
    required this.baseUrl,
    required this.getAuthToken,
  });

  final String baseUrl;
  final Future<String?> Function() getAuthToken;

  Timer? _debounce;

  /// Debounced smart search — calls the backend after a delay.
  void debouncedSearch(
    String query, {
    Duration delay = const Duration(milliseconds: 400),
    required void Function(SmartSearchResult) onResult,
    required void Function(String) onError,
    required void Function() onLoading,
  }) {
    _debounce?.cancel();

    if (query.trim().length < 3) return;

    _debounce = Timer(delay, () async {
      onLoading();
      try {
        final result = await search(query);
        onResult(result);
      } catch (e) {
        onError(e.toString());
      }
    });
  }

  /// Direct smart search call.
  Future<SmartSearchResult> search(String query, {int limit = 10}) async {
    final token = await getAuthToken();
    final res = await http.post(
      Uri.parse('$baseUrl/desk/smart-search'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'query': query, 'limit': limit}),
    );

    if (res.statusCode != 200) {
      throw Exception('Smart search failed: ${res.statusCode}');
    }

    return SmartSearchResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  void dispose() {
    _debounce?.cancel();
  }
}
