import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services here if needed
  // - Database
  // - Notifications
  // - Preferences

  runApp(const ProviderScope(child: TimeTrackerApp()));
}
