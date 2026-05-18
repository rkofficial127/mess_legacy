import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  container.read(authProvider.notifier).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MessApp(),
    ),
  );
}
