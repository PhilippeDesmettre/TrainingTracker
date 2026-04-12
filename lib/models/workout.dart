class Workout {
  final String id;
  final String programId;
  final String name;
  final String? description;
  final int orderIndex;
  final DateTime createdAt;

  const Workout({
    required this.id,
    required this.programId,
    required this.name,
    this.description,
    required this.orderIndex,
    required this.createdAt,
  });

  Workout copyWith({
    String? name,
    String? description,
    int? orderIndex,
  }) =>
      Workout(
        id: id,
        programId: programId,
        name: name ?? this.name,
        description: description ?? this.description,
        orderIndex: orderIndex ?? this.orderIndex,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'program_id': programId,
        'name': name,
        'description': description,
        'order_index': orderIndex,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Workout.fromMap(Map<String, dynamic> map) => Workout(
        id: map['id'] as String,
        programId: map['program_id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        orderIndex: map['order_index'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
