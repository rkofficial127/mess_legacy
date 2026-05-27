import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;
  bool _showMore = false;

  late final AnimationController _staggerController;
  late final AnimationController _shakeController;
  late final Animation<Offset> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.03, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.03, 0), end: const Offset(-0.03, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.03, 0), end: const Offset(0.02, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _staggerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
        );
    if (ok && mounted) {
      context.go('/dashboard');
    } else if (mounted) {
      _shakeController.forward(from: 0);
    }
  }

  Widget _staggeredChild(int index, Widget child) {
    final begin = (index * 0.12).clamp(0.0, 0.6);
    final end = (begin + 0.4).clamp(0.0, 1.0);
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerController,
          curve: Interval(begin, end),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand mark
                _staggeredChild(
                  0,
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withOpacity(0.1),
                    ),
                    child: Icon(Icons.restaurant,
                        size: 28, color: cs.primary),
                  ),
                ),
                const SizedBox(height: 16),
                _staggeredChild(
                  0,
                  Text('Create Account', style: tt.headlineMedium),
                ),
                const SizedBox(height: 4),
                _staggeredChild(
                  0,
                  Text('Join Mess 101', style: tt.bodySmall),
                ),
                const SizedBox(height: 32),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _staggeredChild(
                        1,
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your name'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _staggeredChild(
                        2,
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline, size: 20),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _staggeredChild(
                        3,
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().length < 10
                              ? 'Enter a valid phone number'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _staggeredChild(
                        4,
                        TextFormField(
                          controller: _passCtrl,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon:
                                const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          obscureText: _obscure,
                          validator: (v) {
                            if (v == null || v.length < 8) {
                              return 'Min 8 characters';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ),

                      // Expandable username
                      const SizedBox(height: 8),
                      _staggeredChild(
                        5,
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showMore = !_showMore),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _showMore
                                    ? 'Hide details'
                                    : 'More details (optional)',
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.primary),
                              ),
                              Icon(
                                _showMore
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                                color: cs.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: _showMore
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextFormField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Username (optional)',
                              prefixIcon:
                                  Icon(Icons.alternate_email, size: 20),
                            ),
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),

                      if (auth.error != null) ...[
                        const SizedBox(height: 14),
                        SlideTransition(
                          position: _shakeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 18, color: cs.onErrorContainer),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(auth.error!,
                                      style: TextStyle(
                                          color: cs.onErrorContainer,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      _staggeredChild(
                        5,
                        FilledButton(
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Create Account'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?', style: tt.bodySmall),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
