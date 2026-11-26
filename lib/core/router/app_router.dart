import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/session.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/masters/ui/master_profile_screen.dart';
import '../../features/masters/ui/masters_screen.dart';
import '../../features/tasks/ui/my_tasks_screen.dart';
import '../../features/tasks/ui/task_detail_screen.dart';

/// Routes that need a signed-in user. Guests are sent to login and come back.
const _protected = ['/tasks'];

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever the session changes (login / logout / expiry).
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      if (session.isLoading && !session.hasValue) return null;

      final loc = state.matchedLocation;
      final signedIn = session.value != null;
      final needsAuth = _protected.any((p) => loc == p || loc.startsWith('$p/'));
      if (needsAuth && !signedIn) {
        return Uri(path: '/login', queryParameters: {'from': state.uri.toString()})
            .toString();
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/masters',
              builder: (_, state) => MastersScreen(
                initialCategoryId:
                    int.tryParse(state.uri.queryParameters['cat'] ?? ''),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tasks', builder: (_, _) => const MyTasksScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/master/:id',
        builder: (_, state) =>
            MasterProfileScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (_, state) =>
            TaskDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: LoginScreen(from: state.uri.queryParameters['from']),
        ),
      ),
    ],
  );
});
