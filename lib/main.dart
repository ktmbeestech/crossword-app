import 'package:flutter/material.dart';

import 'app.dart';
import 'package:crosswords/services/databse/database.service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize/open the database before running the app
  await DatabaseService.instance.db;
  runApp(const App());
}
