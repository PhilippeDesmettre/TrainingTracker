import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../workouts/workout_detail_screen.dart';

class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({super.key, required this.programId});
  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(programWorkoutProvider(programId));

    return workoutAsync.when(
      data: (workout) {
        if (workout == null) {
          // Ne devrait pas arriver : le workout est créé avec le programme.
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return WorkoutDetailScreen(programId: programId, workoutId: workout.id);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur : $e'))),
    );
  }
}
