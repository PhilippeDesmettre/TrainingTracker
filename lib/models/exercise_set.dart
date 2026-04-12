class ExerciseSet {
  final String id;
  final String exerciseId;
  final int setNumber;
  final int? reps;
  final double? weight;
  final int? durationSeconds;
  final int? restSeconds;
  final String? notes;

  const ExerciseSet({
    required this.id,
    required this.exerciseId,
    required this.setNumber,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.restSeconds,
    this.notes,
  });

  ExerciseSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    int? durationSeconds,
    int? restSeconds,
    String? notes,
  }) =>
      ExerciseSet(
        id: id,
        exerciseId: exerciseId,
        setNumber: setNumber ?? this.setNumber,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        restSeconds: restSeconds ?? this.restSeconds,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'reps': reps,
        'weight': weight,
        'duration_seconds': durationSeconds,
        'rest_seconds': restSeconds,
        'notes': notes,
      };

  factory ExerciseSet.fromMap(Map<String, dynamic> map) => ExerciseSet(
        id: map['id'] as String,
        exerciseId: map['exercise_id'] as String,
        setNumber: map['set_number'] as int,
        reps: map['reps'] as int?,
        weight: (map['weight'] as num?)?.toDouble(),
        durationSeconds: map['duration_seconds'] as int?,
        restSeconds: map['rest_seconds'] as int?,
        notes: map['notes'] as String?,
      );
}
