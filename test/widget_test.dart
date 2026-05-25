// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'package:DMAAS/src/app.dart';
import 'package:DMAAS/src/features/board/data/task_api_service.dart';
import 'package:DMAAS/src/features/preferences/data/preferences_api_service.dart';
import 'package:DMAAS/src/features/tasks_list/data/field_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Renders board columns', (WidgetTester tester) async {
    final mockHttpClient = MockClient((request) async {
      if (request.url.path.endsWith('/tasks')) {
        return http.Response(jsonEncode([]), 200);
      }
      if (request.url.path.endsWith('/fields')) {
        return http.Response(jsonEncode([]), 200);
      }
      if (request.url.path.endsWith('/preferences')) {
        return http.Response(jsonEncode({}), 200);
      }
      return http.Response('Not found', 404);
    });

    final taskApiService = TaskApiService(
      httpClient: mockHttpClient,
      baseUrl: 'https://mock.dmaas',
    );
    final fieldApiService = FieldApiService(
      httpClient: mockHttpClient,
      baseUrl: 'https://mock.dmaas',
    );
    final preferencesApiService = PreferencesApiService(
      httpClient: mockHttpClient,
      baseUrl: 'https://mock.dmaas',
    );

    await tester.pumpWidget(
      TaskBoardApp(
        taskApiService: taskApiService,
        fieldApiService: fieldApiService,
        preferencesApiService: preferencesApiService,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('DMAAS'), findsOneWidget);

    for (final columnLabel in ['To Do', 'In Progress', 'Done']) {
      expect(find.text(columnLabel), findsWidgets);
    }
  });
}
