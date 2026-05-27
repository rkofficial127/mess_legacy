import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 24,
          left: 20,
          right: 20,
          bottom: 40,
        ),
        children: [
          // Gradient-ringed avatar
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surface,
                  ),
                  child: user?.avatarUrl != null
                      ? CircleAvatar(
                          radius: 38,
                          backgroundImage: NetworkImage(user!.avatarUrl!),
                        )
                      : Center(
                          child: Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase()
                                : '?',
                            style: tt.headlineMedium
                                ?.copyWith(color: cs.primary),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(user?.fullName ?? '-', style: tt.titleLarge),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(user?.email ?? '-', style: tt.bodySmall),
          ),
          if (user?.role != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user!.role,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          // Member since
          if (user != null) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Member since ${DateFormat('MMMM yyyy').format(user.createdAt)}',
                style: tt.labelSmall,
              ),
            ),
          ],
          const SizedBox(height: 28),

          // Phone
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              trailing: Text(user?.phone ?? '',
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ]),
          const SizedBox(height: 12),

          // Account
          _SettingsGroup(children: [
            if (user?.hasPassword == true)
              _SettingsRow(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => _showChangePassword(context, ref),
              )
            else
              _SettingsRow(
                icon: Icons.lock_outline,
                label: 'Set Password',
                subtitle: 'Add a password for email sign-in',
                onTap: () => _showSetPassword(context, ref),
              ),
          ]),
          const SizedBox(height: 12),

          // Sign out in settings group
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.logout,
              iconColor: cs.error,
              label: 'Sign Out',
              labelColor: cs.error,
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ]),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current Password'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'New Password'),
                validator: (v) {
                  if (v == null || v.length < 8) return 'Min 8 characters';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final err = await ref
                  .read(authProvider.notifier)
                  .changePassword(currentCtrl.text, newCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err ?? 'Password changed successfully'),
                ));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showSetPassword(BuildContext context, WidgetRef ref) {
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: newCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
            validator: (v) {
              if (v == null || v.length < 8) return 'Min 8 characters';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final err = await ref
                  .read(authProvider.notifier)
                  .changePassword('', newCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err ?? 'Password set successfully'),
                ));
              }
            },
            child: const Text('Set Password'),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast) Divider(height: 1, indent: 52, color: cs.outline),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final Color? labelColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    this.iconColor,
    required this.label,
    this.labelColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? cs.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: tt.titleSmall?.copyWith(
                            color: labelColor)),
                    if (subtitle != null)
                      Text(subtitle!, style: tt.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null && trailing == null)
                Icon(Icons.chevron_right,
                    size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
