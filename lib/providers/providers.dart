import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_helper.dart';
import '../models/program.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/workout_history.dart';
import '../repositories/history_repository.dart';
import '../repositories/program_repository.dart';
import '../repositories/workout_repository.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

final dbProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final programRepoProvider = Provider<ProgramRepository>(
  (ref) => ProgramRepository(ref.read(dbProvider)),
);

final workoutRepoProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.read(dbProvider)),
);

final historyRepoProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.read(dbProvider)),
);

// ── Programs ──────────────────────────────────────────────────────────────────

final programsProvider = FutureProvider<List<Program>>((ref) {
  return ref.watch(programRepoProvider).getAll();
});

final programProvider = FutureProvider.family<Program?, String>((ref, id) {
  return ref.watch(programRepoProvider).getById(id);
});

// ── Workouts ──────────────────────────────────────────────────────────────────

final workoutsProvider = FutureProvider.family<List<Workout>, String>((ref, programId) {
  return ref.watch(workoutRepoProvider).getByProgram(programId);
});

final workoutProvider = FutureProvider.family<Workout?, String>((ref, workoutId) {
  return ref.watch(workoutRepoProvider).getById(workoutId);
});

/// Retourne le workout unique associé à un programme.
/// Chaque programme possède exactement un workout créé automatiquement.
final programWorkoutProvider = FutureProvider.family<Workout?, String>((ref, programId) async {
  final workouts = await ref.watch(workoutRepoProvider).getByProgram(programId);
  return workouts.isEmpty ? null : workouts.first;
});

// ── Exercises ─────────────────────────────────────────────────────────────────

final exercisesProvider = FutureProvider.family<List<Exercise>, String>((ref, workoutId) {
  return ref.watch(workoutRepoProvider).getExercisesWithSets(workoutId);
});

final setsProvider = FutureProvider.family<List<ExerciseSet>, String>((ref, exerciseId) {
  return ref.watch(workoutRepoProvider).getSets(exerciseId);
});

// ── History ───────────────────────────────────────────────────────────────────

final historyProvider = FutureProvider<List<WorkoutHistory>>((ref) {
  return ref.watch(historyRepoProvider).getAll();
});

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(historyRepoProvider).getStats();
});
