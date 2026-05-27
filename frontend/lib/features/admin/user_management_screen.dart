import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/user.dart';
import '../../core/providers/admin_providers.dart';
import '../../shared/widgets/shimmer_loading.dart';

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
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 24),
          child: ShimmerCardList(count: 5),
        ),
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
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: u.isActive ? cs.outline : cs.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: u.isActive
                            ? cs.primary.withOpacity(0.1)
                            : cs.surfaceContainer,
                        child: Text(
                          u.fullName.isNotEmpty
                              ? u.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: u.isActive
                                ? cs.primary
                                : cs.onSurfaceVariant,
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
                                      color: cs.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Inactive',
                                        style: TextStyle(
                                            color: cs.error,
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
                                      color: cs.tertiary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('No Plan',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: cs.tertiary)),
                                  );
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${sub.planName ?? 'Plan'} · ₹${sub.planMonthlyRate?.toStringAsFixed(0) ?? '-'}',
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
                                  ? cs.secondary.withOpacity(0.1)
                                  : cs.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(u.role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: u.role == 'ADMIN'
                                      ? cs.secondary
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
      BuildContext context, WidgetRef ref, User user, List? plans) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (ctx, scrollController) {
            return _UserDetailSheet(
              user: user,
              plans: plans,
              scrollController: scrollController,
              parentContext: context,
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
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().length < 10
                      ? 'Enter a valid phone number'
                      : null,
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
                        phone: phoneCtrl.text.trim(),
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

class _UserDetailSheet extends ConsumerStatefulWidget {
  final User user;
  final List? plans;
  final ScrollController scrollController;
  final BuildContext parentContext;

  const _UserDetailSheet({
    required this.user,
    required this.plans,
    required this.scrollController,
    required this.parentContext,
  });

  @override
  ConsumerState<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends ConsumerState<_UserDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  DateTime _extraDate = DateTime.now().add(const Duration(days: 1));
  String _extraMeal = 'BREAKFAST';
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = widget.user;
    final now = DateTime.now();
    final subAsync = ref.watch(userSubscriptionProvider(
        (userId: user.id, month: now.month, year: now.year)));

    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primary.withOpacity(0.1),
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: tt.titleLarge),
                    Text(user.email,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? cs.primary.withOpacity(0.1)
                      : cs.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.isActive ? cs.primary : cs.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Plan'),
            Tab(text: 'Extras'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildProfileTab(cs, tt, user),
              _buildPlanTab(cs, tt, user, subAsync),
              _buildExtrasTab(cs, tt, user),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab(ColorScheme cs, TextTheme tt, User user) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    await updateUser(
                      userId: user.id,
                      fullName: _nameCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim(),
                    );
                    ref.invalidate(usersProvider);
                    if (mounted) Navigator.pop(context);
                    if (widget.parentContext.mounted) {
                      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                        const SnackBar(content: Text('Profile updated')),
                      );
                    }
                  } catch (e) {
                    if (widget.parentContext.mounted) {
                      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Changes'),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: OutlinedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: Text(user.isActive
                          ? 'Deactivate User?'
                          : 'Activate User?'),
                      content: Text(user.isActive
                          ? '${user.fullName} will no longer be able to log in.'
                          : '${user.fullName} will be able to log in again.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(d, false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.pop(d, true),
                            child: Text(user.isActive
                                ? 'Deactivate'
                                : 'Activate')),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  try {
                    await updateUser(
                      userId: user.id,
                      isActive: !user.isActive,
                    );
                    ref.invalidate(usersProvider);
                    if (mounted) Navigator.pop(context);
                    if (widget.parentContext.mounted) {
                      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                        SnackBar(
                            content: Text(user.isActive
                                ? '${user.fullName} deactivated'
                                : '${user.fullName} activated')),
                      );
                    }
                  } catch (e) {
                    if (widget.parentContext.mounted) {
                      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: user.isActive ? cs.error : cs.primary,
                  minimumSize: const Size(0, 52),
                ),
                child:
                    Text(user.isActive ? 'Deactivate' : 'Activate'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanTab(
      ColorScheme cs, TextTheme tt, User user, AsyncValue subAsync) {
    final now = DateTime.now();
    final plans = widget.plans;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Current Plan', style: tt.titleMedium),
        const SizedBox(height: 8),
        subAsync.when(
          loading: () => const ShimmerCardList(count: 1, cardHeight: 56),
          error: (e, _) => Text('Error: $e'),
          data: (sub) {
            if (sub == null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.tertiary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: cs.tertiary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: cs.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No plan assigned',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.tertiary,
                              )),
                          Text(
                            'Assign a plan below.',
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.tertiary.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: cs.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.restaurant_menu,
                          color: cs.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sub.planName ?? 'Plan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                )),
                            Text(
                              '${sub.planFoodType ?? '-'} · ${sub.planMealsPerDay ?? '-'} meals/day · ₹${sub.planMonthlyRate?.toStringAsFixed(0) ?? '-'}/mo',
                              style: TextStyle(
                                  fontSize: 13, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Meal Dates', style: tt.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerTile(
                        label: 'Start Date',
                        icon: Icons.play_arrow_rounded,
                        date: sub.startDate,
                        color: cs.primary,
                        onPick: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: sub.startDate ?? DateTime(sub.year, sub.month, 1),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2100),
                          );
                          if (picked == null) return;
                          try {
                            await updateSubscriptionDates(
                              subscriptionId: sub.id,
                              startDate: picked,
                            );
                            ref.invalidate(userSubscriptionProvider((
                              userId: user.id,
                              month: now.month,
                              year: now.year,
                            )));
                            if (widget.parentContext.mounted) {
                              ScaffoldMessenger.of(widget.parentContext)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'Start date set to ${DateFormat('d MMM yyyy').format(picked)}'),
                              ));
                            }
                          } catch (e) {
                            if (widget.parentContext.mounted) {
                              ScaffoldMessenger.of(widget.parentContext)
                                  .showSnackBar(
                                      SnackBar(content: Text('Error: $e')));
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerTile(
                        label: 'Stop Date',
                        icon: Icons.stop_rounded,
                        date: sub.stopDate,
                        color: cs.error,
                        onPick: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: sub.stopDate ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2100),
                          );
                          if (picked == null) return;
                          try {
                            await updateSubscriptionDates(
                              subscriptionId: sub.id,
                              stopDate: picked,
                            );
                            ref.invalidate(userSubscriptionProvider((
                              userId: user.id,
                              month: now.month,
                              year: now.year,
                            )));
                            if (widget.parentContext.mounted) {
                              ScaffoldMessenger.of(widget.parentContext)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'Stop date set to ${DateFormat('d MMM yyyy').format(picked)}'),
                              ));
                            }
                          } catch (e) {
                            if (widget.parentContext.mounted) {
                              ScaffoldMessenger.of(widget.parentContext)
                                  .showSnackBar(
                                      SnackBar(content: Text('Error: $e')));
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          subAsync.valueOrNull == null ? 'Assign Plan' : 'Change Plan',
          style: tt.titleMedium,
        ),
        const SizedBox(height: 8),
        if (plans != null && plans.isNotEmpty)
          ...plans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      try {
                        await assignSubscription(
                          userId: user.id,
                          planId: p.id,
                          month: now.month,
                          year: now.year,
                        );
                        ref.invalidate(userSubscriptionProvider((
                          userId: user.id,
                          month: now.month,
                          year: now.year,
                        )));
                        if (mounted) Navigator.pop(context);
                        if (widget.parentContext.mounted) {
                          ScaffoldMessenger.of(widget.parentContext)
                              .showSnackBar(SnackBar(
                            content: Text(
                                '${p.name} assigned to ${user.fullName}'),
                          ));
                        }
                      } catch (e) {
                        if (widget.parentContext.mounted) {
                          ScaffoldMessenger.of(widget.parentContext)
                              .showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                          ));
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            p.foodType == 'VEG'
                                ? Icons.eco_outlined
                                : Icons.restaurant_outlined,
                            size: 20,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  '${p.foodType} · ${p.mealsPerDay} meals/day',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurfaceVariant),
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
                              color: cs.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
        else
          const Text('No meal plans available'),
      ],
    );
  }

  Widget _buildExtrasTab(ColorScheme cs, TextTheme tt, User user) {
    return StatefulBuilder(
      builder: (ctx, setLocal) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Add Extra Meal', style: tt.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Add a one-off meal outside this user\'s plan.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ActionChip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text(
                '${_extraDate.day}/${_extraDate.month}/${_extraDate.year}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: _extraDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setLocal(() => _extraDate = picked);
              }
            },
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'BREAKFAST',
                  label: Icon(Icons.wb_twilight_rounded, size: 18)),
              ButtonSegment(
                  value: 'LUNCH',
                  label: Icon(Icons.wb_sunny_rounded, size: 18)),
              ButtonSegment(
                  value: 'DINNER',
                  label: Icon(Icons.nightlight_round, size: 18)),
            ],
            selected: {_extraMeal},
            onSelectionChanged: (s) =>
                setLocal(() => _extraMeal = s.first),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              try {
                await createExtraMeal(
                  userId: user.id,
                  date: _extraDate,
                  mealType: _extraMeal,
                  note: _noteCtrl.text.trim().isNotEmpty
                      ? _noteCtrl.text.trim()
                      : null,
                );
                if (mounted) Navigator.pop(context);
                if (widget.parentContext.mounted) {
                  ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Extra ${_extraMeal.toLowerCase()} added for ${user.fullName}'),
                    ),
                  );
                }
              } catch (e) {
                if (widget.parentContext.mounted) {
                  ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Add Extra Meal'),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;
  final Color color;
  final VoidCallback onPick;

  const _DatePickerTile({
    required this.label,
    required this.icon,
    required this.date,
    required this.color,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              date != null
                  ? DateFormat('d MMM yyyy').format(date!)
                  : 'Not set',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: date != null ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
