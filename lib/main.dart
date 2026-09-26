import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // If a Firebase session was already persisted from a previous run,
  // pre-fetch the MongoDB-backed profile so it's ready before the first
  // frame that needs it. Safe to skip (screens fetch on demand too).
  await AuthService.instance.init();

  runApp(
    const ProviderScope(
      child: ExpenseFlowApp(),
    ),
  );
}
