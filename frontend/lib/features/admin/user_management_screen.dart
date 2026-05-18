import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/admin_providers.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final usersAsync = ref.watch(usersProvider);
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUser(context, ref, plansAsync.valueOrNull),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add User'),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(usersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final u = users[i];
              final now = DateTime.now();
              final subAsync = ref.watch(userSubscriptionProvider(
                  (userId: u.id, month: now.month, year: now.year)));

              return GestureDetector(
                onTap: () => _showUserDetail(
                    context, ref, u, plansAsync.valueOrNull),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: u.isActive
                          ? cs.outlineVariant.withOpacity(0.5)
                          : cs.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: u.isActive
                            ? cs.primaryContainer
                            : Colors.grey.shade200,
                        child: Text(
                          u.fullName.isNotEmpty
                              ? u.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: u.isActive
                                ? cs.onPrimaryContainer
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(u.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (!u.isActive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cs.error,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Inactive',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(u.email,
                                style: TextStyle(
                                    fontSize: 13, color: cs.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            // Subscription status
                            subAsync.when(
                              loading: () => Text('Loading plan...',
                                  style: TextStyle(
                                      fontSize: 12, color: cs.onSurfaceVariant)),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (sub) {
                                if (sub == null) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('No Plan',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade800)),
                                  );
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${sub.planName ?? 'Plan'} • ₹${sub.planMonthlyRate?.toStringAsFixed(0) ?? '-'}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: cs.primary),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: u.role == 'ADMIN'
                                  ? cs.tertiaryContainer
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(u.role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: u.role == 'ADMIN'
                                      ? cs.onTertiaryContainer
                                      : cs.onSurfaceVariant,
                                )),
                          ),
                          const SizedBox(height: 4),
                          Icon(Icons.chevron_right,
                              size: 20, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showUserDetail(
      BuildContext context, WidgetRef ref, dynamic user, List? plans) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final subAsync = ref.watch(userSubscriptionProvider(
                (userId: user.id, month: now.month, year: now.year)));

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName,
                                  style: Theme.of(ctx).textTheme.titleLarge),
                              Text(user.email,
                                  style:
                                      TextStyle(color: cs.onSurfaceVariant)),
                              if (user.phone != null &&
                                  user.phone!.isNotEmpty)
                                Text(user.phone!,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.isActive
                                ? cs.primaryContainer
                                : cs.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: user.isActive
                                  ? cs.onPrimaryContainer
                                  : cs.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Current plan section
                    Text('Current Plan',
                        style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    subAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Error: $e'),
                      data: (sub) {
                        if (sub == null) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('No plan assigned',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade800,
                                          )),
                                      Text(
                                        'This user cannot track meals until a plan is assigned.',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color:
                                                Colors.orange.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.restaurant_menu,
                                  color: cs.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(sub.planName ?? 'Plan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: cs.primary,
                                        )),
                                    Text(
                                      '${sub.planFoodType ?? '-'} • ${sub.planMealsPerDay ?? '-'} meals/day • ₹${sub.planMonthlyRate?.toStringAsFixed(0) ?? '-'}/mo',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Assign plan section
                    Text(
                      subAsync.valueOrNull == null
                          ? 'Assign Plan'
                          : 'Change Plan',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (plans != null && plans.isNotEmpty)
                      ...plans.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  try {
                                    await assignSubscription(
                                      userId: user.id,
                                      planId: p.id,
                                      month: now.month,
                                      year: now.year,
                                    );
                                    ref.invalidate(
                                        userSubscriptionProvider((
                                      userId: user.id,
                                      month: now.month,
                                      year: now.year,
                                    )));
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            '${p.name} assigned to ${user.fullName}'),
                                      ));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text('Error: $e'),
                                      ));
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer
                                              .withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          p.foodType == 'VEG'
                                              ? Icons.eco_outlined
                                              : Icons.restaurant_outlined,
                                          size: 20,
                                          color: cs.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(p.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(
                                              '${p.foodType} • ${p.mealsPerDay} meals/day',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      cs.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${p.monthlyRate.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: cs.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.add_circle_outline,
                                          color: cs.primary, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ))
                    else
                      const Text('No meal plans available'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddUser(BuildContext context, WidgetRef ref, List? plans) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedPlanId;
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 8,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add New User',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Valid email required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Initial Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                if (plans != null && plans.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (ctx2, setLocal) =>
                        DropdownButtonFormField<String>(
                      value: selectedPlanId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Plan (optional)',
                        prefixIcon: Icon(Icons.restaurant_menu),
                      ),
                      items: plans
                          .map((p) => DropdownMenuItem(
                              value: p.id as String,
                              child: Text(p.name as String)))
                          .toList(),
                      onChanged: (v) => setLocal(() => selectedPlanId = v),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      final user = await createUser(
                        email: emailCtrl.text.trim(),
                        fullName: nameCtrl.text.trim(),
                        password: passCtrl.text,
                        phone: phoneCtrl.text.isNotEmpty
                            ? phoneCtrl.text.trim()
                            : null,
                      );
                      if (selectedPlanId != null) {
                        await assignSubscription(
                          userId: user.id,
                          planId: selectedPlanId!,
                          month: now.month,
                          year: now.year,
                        );
                      }
                      ref.invalidate(usersProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('${user.fullName} created')),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Create User'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
