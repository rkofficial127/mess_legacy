import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/auth_provider.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/bills_management_screen.dart';
import '../features/admin/mess_off_screen.dart';
import '../features/admin/user_management_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/bills/bill_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/profile/profile_screen.dart';
import '../shared/widgets/app_scaffold.dart';

final _rootNavKey = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!loggedIn && !onAuthPage) return '/login';
      if (loggedIn && onAuthPage) {
        return auth.isAdmin ? '/admin' : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // User shell
      ShellRoute(
        navigatorKey: _shellNavKey,
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CalendarScreen()),
          ),
          GoRoute(
            path: '/bills',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BillScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
          // Admin
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminDashboardScreen()),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UserManagementScreen()),
          ),
          GoRoute(
            path: '/admin/mess-off',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MessOffScreen()),
          ),
          GoRoute(
            path: '/admin/bills',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BillsManagementScreen()),
          ),
        ],
      ),
    ],
  );
});
