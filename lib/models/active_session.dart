/// Modèles utilisés pendant une séance active (en mémoire uniquement).
/// Les données sont persisées dans history_sets au fil de l'avancement.

class ActiveSession {
  final String historyId;
  final String workoutName;
  final String programName;
  final DateTime startedAt;
  final List<ActiveExercise> exercises;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final bool isResting;
  final int restSecondsRemaining;
  final int restTotalSeconds;
  final bool isCompleted;

  const ActiveSession({
    required this.historyId,
    required this.workoutName,
    required this.programName,
    required this.startedAt,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.isResting,
    required this.restSecondsRemaining,
    this.restTotalSeconds = 0,
    required this.isCompleted,
  });

  ActiveExercise get currentExercise => exercises[currentExerciseIndex];
  ActiveSet get currentSet => currentExercise.sets[currentSetIndex];

  bool get isLastExercise => currentExerciseIndex >= exercises.length - 1;
  bool get isLastSet => currentSetIndex >= currentExercise.sets.length - 1;

  int get totalSets => exercises.fold(0, (s, e) => s + e.sets.length);
  int get completedSets => exercises.fold(0, (s, e) => s + e.sets.where((x) => x.completed).length);

  Duration get elapsed => DateTime.now().difference(startedAt);

  ActiveSession copyWith({
    List<ActiveExercise>? exercises,
    int? currentExerciseIndex,
    int? currentSetIndex,
    bool? isResting,
    int? restSecondsRemaining,
    int? restTotalSeconds,
    bool? isCompleted,
  }) =>
      ActiveSession(
        historyId: historyId,
        workoutName: workoutName,
        programName: programName,
        startedAt: startedAt,
        exercises: exercises ?? this.exercises,
        currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
        currentSetIndex: currentSetIndex ?? this.currentSetIndex,
        isResting: isResting ?? this.isResting,
        restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
        restTotalSeconds: restTotalSeconds ?? this.restTotalSeconds,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

class ActiveExercise {
  final String historyExerciseId;
  final String exerciseId;
  final String exerciseName;
  final String? muscleGroup;
  final List<ActiveSet> sets;

  const ActiveExercise({
    required this.historyExerciseId,
    required this.exerciseId,
    required this.exerciseName,
    this.muscleGroup,
    required this.sets,
  });

  ActiveExercise copyWith({List<ActiveSet>? sets}) => ActiveExercise(
        historyExerciseId: historyExerciseId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        muscleGroup: muscleGroup,
        sets: sets ?? this.sets,
      );
}

class ActiveSet {
  final String historySetId;
  final int setNumber;
  final int? plannedReps;
  final double? plannedWeight;
  final int? plannedDuration;
  final int restSeconds;
  final int? actualReps;
  final double? actualWeight;
  final bool completed;

  const ActiveSet({
    required this.historySetId,
    required this.setNumber,
    this.plannedReps,
    this.plannedWeight,
    this.plannedDuration,
    required this.restSeconds,
    this.actualReps,
    this.actualWeight,
    this.completed = false,
  });

  ActiveSet copyWith({
    int? actualReps,
    double? actualWeight,
    bool? completed,
  }) =>
      ActiveSet(
        historySetId: historySetId,
        setNumber: setNumber,
        plannedReps: plannedReps,
        plannedWeight: plannedWeight,
        plannedDuration: plannedDuration,
        restSeconds: restSeconds,
        actualReps: actualReps ?? this.actualReps,
        actualWeight: actualWeight ?? this.actualWeight,
        completed: completed ?? this.completed,
      );
}
