import 'exercise_set.dart';

class Exercise {
  final String id;
  final String workoutId;
  final String name;
  final String? muscleGroup;
  final int orderIndex;
  final String? notes;
  final List<ExerciseSet> sets;

  const Exercise({
    required this.id,
    required this.workoutId,
    required this.name,
    this.muscleGroup,
    required this.orderIndex,
    this.notes,
    this.sets = const [],
  });

  Exercise copyWith({
    String? name,
    String? muscleGroup,
    int? orderIndex,
    String? notes,
    List<ExerciseSet>? sets,
  }) =>
      Exercise(
        id: id,
        workoutId: workoutId,
        name: name ?? this.name,
        muscleGroup: muscleGroup ?? this.muscleGroup,
        orderIndex: orderIndex ?? this.orderIndex,
        notes: notes ?? this.notes,
        sets: sets ?? this.sets,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'workout_id': workoutId,
        'name': name,
        'muscle_group': muscleGroup,
        'order_index': orderIndex,
        'notes': notes,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as String,
        workoutId: map['workout_id'] as String,
        name: map['name'] as String,
        muscleGroup: map['muscle_group'] as String?,
        orderIndex: map['order_index'] as int,
        notes: map['notes'] as String?,
      );
}
