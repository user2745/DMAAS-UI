import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/anonymous_id.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final anonymousId = await AnonymousId.getOrCreate();
  runApp(TaskBoardApp(anonymousId: anonymousId));
}
