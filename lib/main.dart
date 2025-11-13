import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'package:crosswords/services/analytics/analytics.service.dart';
import 'package:crosswords/services/databse/database.service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.db;

  final config = ClarityConfig(
      projectId: 'u5e2cci568',
      logLevel: LogLevel.None

  );
  await AnalyticsService.instance.initialize();
  runApp(ClarityWidget(
      app: App(),
      clarityConfig: config,
  ));
}
