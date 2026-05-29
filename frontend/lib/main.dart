import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/biometric_service.dart';
import 'features/auth/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(authProvider.notifier).init();

  // Check if biometric lock should be shown
  final bioService = container.read(biometricServiceProvider);
  final bioEnabled = await bioService.isEnabled;
  final hasToken = container.read(authProvider).isLoggedIn;
  if (bioEnabled && hasToken) {
    container.read(biometricLockProvider.notifier).state = true;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MessApp(),
    ),
  );
}
