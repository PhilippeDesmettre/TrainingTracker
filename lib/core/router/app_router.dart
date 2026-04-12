import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/history/history_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/programs/program_detail_screen.dart';
import '../../screens/programs/program_list_screen.dart';
import '../../screens/session/session_screen.dart';
import '../../screens/stats/stats_screen.dart';
import '../../screens/workouts/workout_detail_screen.dart';
import '../shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/programs',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProgramListScreen()),
            routes: [
              GoRoute(
                path: ':programId',
                builder: (context, state) => ProgramDetailScreen(
                  programId: state.pathParameters['programId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'workouts/:workoutId',
                    builder: (context, state) => WorkoutDetailScreen(
                      programId: state.pathParameters['programId']!,
                      workoutId: state.pathParameters['workoutId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => const NoTransitionPage(child: StatsScreen()),
          ),
        ],
      ),
      // Session en plein écran, hors shell
      GoRoute(
        path: '/session/:workoutId',
        builder: (context, state) => SessionScreen(
          workoutId: state.pathParameters['workoutId']!,
        ),
      ),
    ],
  );
});
