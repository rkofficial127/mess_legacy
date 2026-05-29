import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/biometric_service.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Auto-prompt biometric on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final bio = ref.read(biometricServiceProvider);
    final success = await bio.authenticate();
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      ref.read(biometricLockProvider.notifier).state = false;
    } else if (mounted) {
      setState(() => _authFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated lock icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withOpacity( 0.1),
                  border: Border.all(
                    color: cs.primary.withOpacity( 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 44,
                  color: _authFailed ? cs.error : cs.primary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Mess 101', style: tt.headlineSmall),
            const SizedBox(height: 8),
            Text(
              _authFailed ? 'Authentication failed' : 'Verify to continue',
              style: tt.bodyMedium?.copyWith(
                color: _authFailed ? cs.error : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint, size: 20),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Global state: true = app is locked, false = unlocked
final biometricLockProvider = StateProvider<bool>((ref) => false);
