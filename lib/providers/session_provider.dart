import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/active_session.dart';
import '../models/workout_history.dart';
import 'providers.dart';

final sessionProvider = NotifierProvider<SessionNotifier, ActiveSession?>(SessionNotifier.new);

class SessionNotifier extends Notifier<ActiveSession?> {
  static const _uuid = Uuid();
  Timer? _restTimer;

  @override
  ActiveSession? build() {
    ref.onDispose(() => _restTimer?.cancel());
    return null;
  }

  /// Démarre une nouvelle séance à partir d'un workout template.
  Future<void> startSession(String workoutId) async {
    final workoutRepo = ref.read(workoutRepoProvider);
    final historyRepo = ref.read(historyRepoProvider);
    final programRepo = ref.read(programRepoProvider);

    final workout = await workoutRepo.getById(workoutId);
    if (workout == null) return;

    final program = await programRepo.getById(workout.programId);
    final exercises = await workoutRepo.getExercisesWithSets(workoutId);

    if (exercises.isEmpty) return;

    final historyId = _uuid.v4();
    final now = DateTime.now();

    await historyRepo.createHistory(WorkoutHistory(
      id: historyId,
      workoutId: workoutId,
      programId: workout.programId,
      workoutName: workout.name,
      programName: program?.name ?? '',
      startedAt: now,
    ));

    final activeExercises = <ActiveExercise>[];

    for (final exercise in exercises) {
      final historyExerciseId = _uuid.v4();

      await historyRepo.createHistoryExercise(HistoryExercise(
        id: historyExerciseId,
        historyId: historyId,
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        orderIndex: exercise.orderIndex,
      ));

      final activeSets = <ActiveSet>[];
      for (final set in exercise.sets) {
        final historySetId = _uuid.v4();

        await historyRepo.createHistorySet(HistorySet(
          id: historySetId,
          historyExerciseId: historyExerciseId,
          setNumber: set.setNumber,
          plannedReps: set.reps,
          plannedWeight: set.weight,
          restSeconds: set.restSeconds,
          completed: false,
        ));

        activeSets.add(ActiveSet(
          historySetId: historySetId,
          setNumber: set.setNumber,
          plannedReps: set.reps,
          plannedWeight: set.weight,
          plannedDuration: set.durationSeconds,
          restSeconds: set.restSeconds ?? 60,
        ));
      }

      if (activeSets.isNotEmpty) {
        activeExercises.add(ActiveExercise(
          historyExerciseId: historyExerciseId,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          muscleGroup: exercise.muscleGroup,
          sets: activeSets,
        ));
      }
    }

    if (activeExercises.isEmpty) return;

    state = ActiveSession(
      historyId: historyId,
      workoutName: workout.name,
      programName: program?.name ?? '',
      startedAt: now,
      exercises: activeExercises,
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      isResting: false,
      restSecondsRemaining: 0,
      isCompleted: false,
    );
  }

  /// Complète une série identifiée par son historySetId.
  /// Lance le chrono de repos si configuré, sauf si c'est la dernière série.
  Future<void> completeSetById(String historySetId) async {
    final s = state;
    if (s == null) return;

    // Trouver la série dans tous les exercices
    int exIndex = -1;
    int setIdx = -1;
    for (var i = 0; i < s.exercises.length; i++) {
      for (var j = 0; j < s.exercises[i].sets.length; j++) {
        if (s.exercises[i].sets[j].historySetId == historySetId) {
          exIndex = i;
          setIdx = j;
          break;
        }
      }
      if (exIndex >= 0) break;
    }
    if (exIndex < 0) return;

    final exercises = List.of(s.exercises);
    final exercise = exercises[exIndex];
    final sets = List.of(exercise.sets);
    final targetSet = sets[setIdx].copyWith(
      completed: true,
      actualReps: sets[setIdx].actualReps ?? sets[setIdx].plannedReps,
      actualWeight: sets[setIdx].actualWeight ?? sets[setIdx].plannedWeight,
    );
    sets[setIdx] = targetSet;
    exercises[exIndex] = exercise.copyWith(sets: sets);

    await ref.read(historyRepoProvider).updateHistorySet(
      historySetId,
      actualReps: targetSet.actualReps,
      actualWeight: targetSet.actualWeight,
      completed: true,
    );

    final updatedSession = s.copyWith(exercises: exercises);
    final allDone = updatedSession.exercises
        .expand((e) => e.sets)
        .every((s) => s.completed);

    state = updatedSession;

    // Pas de chrono après la dernière série
    if (allDone) return;

    if (targetSet.restSeconds > 0) {
      _startRestTimer(targetSet.restSeconds);
    }
  }

  /// Termine explicitement la séance (appelé depuis l'UI quand toutes les séries sont faites).
  Future<void> finishSession() async => _finishSession();

  void skipRest() {
    _restTimer?.cancel();
    state = state?.copyWith(isResting: false, restSecondsRemaining: 0, restTotalSeconds: 0);
  }

  Future<void> abandonSession() async {
    _restTimer?.cancel();
    final s = state;
    if (s != null) {
      await ref.read(historyRepoProvider).deleteHistory(s.historyId);
    }
    state = null;
  }

  void clearSession() {
    _restTimer?.cancel();
    state = null;
    ref.invalidate(historyProvider);
    ref.invalidate(statsProvider);
  }

  // ── Méthodes conservées pour compatibilité (non utilisées dans le nouveau UX) ──

  void updateCurrentSetValues({int? reps, double? weight}) {
    final s = state;
    if (s == null) return;
    final exercises = List.of(s.exercises);
    final exercise = exercises[s.currentExerciseIndex];
    final sets = List.of(exercise.sets);
    sets[s.currentSetIndex] = sets[s.currentSetIndex].copyWith(
      actualReps: reps,
      actualWeight: weight,
    );
    exercises[s.currentExerciseIndex] = exercise.copyWith(sets: sets);
    state = s.copyWith(exercises: exercises);
  }

  Future<void> completeCurrentSet() async {
    final s = state;
    if (s == null) return;
    final exercises = List.of(s.exercises);
    final exercise = exercises[s.currentExerciseIndex];
    final sets = List.of(exercise.sets);
    final currentSet = sets[s.currentSetIndex].copyWith(completed: true);
    sets[s.currentSetIndex] = currentSet;
    exercises[s.currentExerciseIndex] = exercise.copyWith(sets: sets);
    await ref.read(historyRepoProvider).updateHistorySet(
      currentSet.historySetId,
      actualReps: currentSet.actualReps,
      actualWeight: currentSet.actualWeight,
      completed: true,
    );
    final isLastSet = s.currentSetIndex >= exercise.sets.length - 1;
    final isLastExercise = s.currentExerciseIndex >= exercises.length - 1;
    state = s.copyWith(exercises: exercises);
    if (isLastSet && isLastExercise) {
      await _finishSession();
      return;
    }
    final restSeconds = currentSet.restSeconds;
    if (restSeconds > 0) {
      _startRestTimer(restSeconds);
    } else {
      _advanceToNext(isLastSet: isLastSet);
    }
  }

  void skipCurrentExercise() {
    final s = state;
    if (s == null || s.isLastExercise) return;
    _restTimer?.cancel();
    state = s.copyWith(
      isResting: false,
      restSecondsRemaining: 0,
      currentExerciseIndex: s.currentExerciseIndex + 1,
      currentSetIndex: 0,
    );
  }

  // ── Privé ──────────────────────────────────────────────────────────────────

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    state = state!.copyWith(
      isResting: true,
      restSecondsRemaining: seconds,
      restTotalSeconds: seconds,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state;
      if (s == null) return;
      final remaining = s.restSecondsRemaining - 1;
      if (remaining <= 0) {
        _restTimer?.cancel();
        state = s.copyWith(isResting: false, restSecondsRemaining: 0);
      } else {
        state = s.copyWith(restSecondsRemaining: remaining);
      }
    });
  }

  void _advanceToNext({required bool isLastSet}) {
    final s = state;
    if (s == null) return;
    if (isLastSet) {
      state = s.copyWith(
        currentExerciseIndex: s.currentExerciseIndex + 1,
        currentSetIndex: 0,
      );
    } else {
      state = s.copyWith(currentSetIndex: s.currentSetIndex + 1);
    }
  }

  Future<void> _finishSession() async {
    final s = state;
    if (s == null) return;
    _restTimer?.cancel();
    final now = DateTime.now();
    await ref.read(historyRepoProvider).finishHistory(s.historyId, now);
    state = s.copyWith(isCompleted: true);
  }
}
