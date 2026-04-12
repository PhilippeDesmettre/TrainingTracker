import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({
    super.key,
    required this.programId,
    required this.workoutId,
  });

  final String programId;
  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutProvider(workoutId));
    final exercisesAsync = ref.watch(exercisesProvider(workoutId));

    return Scaffold(
      appBar: AppBar(
        title: workoutAsync.when(
          data: (w) => Text(w?.name ?? ''),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Text('Erreur'),
        ),
      ),
      body: exercisesAsync.when(
        data: (exercises) => _ExerciseList(
          exercises: exercises,
          workoutId: workoutId,
          programId: programId,
          ref: ref,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
      bottomNavigationBar: _BottomBar(workoutId: workoutId),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({
    required this.exercises,
    required this.workoutId,
    required this.programId,
    required this.ref,
  });

  final List<Exercise> exercises;
  final String workoutId;
  final String programId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return EmptyState(
        icon: Icons.add_box_outlined,
        title: 'Aucun exercice',
        subtitle: 'Ajoute des exercices à cette séance.',
        action: () => _showAddExerciseDialog(context),
        actionLabel: 'Ajouter un exercice',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ExerciseCard(
        exercise: exercises[index],
        onDelete: () async {
          await ref.read(workoutRepoProvider).deleteExercise(exercises[index].id);
          ref.invalidate(exercisesProvider(workoutId));
        },
        onAddSet: () => _showAddSetDialog(context, exercises[index]),
        onDeleteSet: (set) async {
          await ref.read(workoutRepoProvider).deleteSet(set.id);
          ref.invalidate(exercisesProvider(workoutId));
        },
      ),
    );
  }

  Future<void> _showAddExerciseDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final muscleCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un exercice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                hintText: 'Ex: Développé couché',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: muscleCtrl,
              decoration: const InputDecoration(
                labelText: 'Groupe musculaire',
                hintText: 'Ex: Pectoraux',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      final exercise = Exercise(
        id: const Uuid().v4(),
        workoutId: workoutId,
        name: nameCtrl.text.trim(),
        muscleGroup: muscleCtrl.text.trim().isEmpty ? null : muscleCtrl.text.trim(),
        orderIndex: exercises.length,
      );
      await ref.read(workoutRepoProvider).insertExercise(exercise);
      ref.invalidate(exercisesProvider(workoutId));
    }
  }

  Future<void> _showAddSetDialog(BuildContext context, Exercise exercise) async {
    final repsCtrl = TextEditingController(text: '10');
    final weightCtrl = TextEditingController(text: '0');
    final restCtrl = TextEditingController(text: '90');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Série #${exercise.sets.length + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: repsCtrl,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    decoration: const InputDecoration(labelText: 'Charge (kg)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: restCtrl,
              decoration: const InputDecoration(labelText: 'Repos (secondes)', hintText: '90'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final set = ExerciseSet(
        id: const Uuid().v4(),
        exerciseId: exercise.id,
        setNumber: exercise.sets.length + 1,
        reps: int.tryParse(repsCtrl.text),
        weight: double.tryParse(weightCtrl.text),
        restSeconds: int.tryParse(restCtrl.text) ?? 90,
      );
      await ref.read(workoutRepoProvider).insertSet(set);
      ref.invalidate(exercisesProvider(workoutId));
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onDelete,
    required this.onAddSet,
    required this.onDeleteSet,
  });

  final Exercise exercise;
  final VoidCallback onDelete;
  final VoidCallback onAddSet;
  final void Function(ExerciseSet) onDeleteSet;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de l'exercice
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: Theme.of(context).textTheme.titleLarge),
                      if (exercise.muscleGroup != null)
                        Text(
                          exercise.muscleGroup!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: onAddSet,
                  tooltip: 'Ajouter une série',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                  color: AppColors.cardAlt,
                  onSelected: (v) { if (v == 'delete') onDelete(); },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tableau des séries
          if (exercise.sets.isNotEmpty) ...[
            Divider(color: AppColors.divider, height: 1),
            // En-têtes colonnes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _ColHeader('Série', width: 40),
                  _ColHeader('Reps', width: 60),
                  _ColHeader('Charge', width: 80),
                  _ColHeader('Repos', width: 60),
                  const Spacer(),
                ],
              ),
            ),
            ...exercise.sets.map((set) => _SetRow(set: set, onDelete: () => onDeleteSet(set))),
          ],

          // Bouton ajouter série si vide
          if (exercise.sets.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter une série'),
              ),
            ),

          if (exercise.sets.isNotEmpty) const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text, {required this.width});
  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.set, required this.onDelete});
  final ExerciseSet set;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final weight = set.weight != null
        ? (set.weight! % 1 == 0 ? '${set.weight!.toInt()}kg' : '${set.weight}kg')
        : '—';
    final rest = set.restSeconds != null ? '${set.restSeconds}s' : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${set.setNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text('${set.reps ?? '—'}', style: Theme.of(context).textTheme.bodyMedium),
          ),
          SizedBox(
            width: 80,
            child: Text(weight, style: Theme.of(context).textTheme.bodyMedium),
          ),
          SizedBox(
            width: 60,
            child: Text(rest, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.remove_circle_outline, color: AppColors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.workoutId});
  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider(workoutId));
    final hasExercises = exercisesAsync.valueOrNull?.isNotEmpty == true;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasExercises)
              ElevatedButton.icon(
                onPressed: () => context.push('/session/$workoutId'),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('Lancer la séance'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddExerciseDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un exercice'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddExerciseDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final muscleCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un exercice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom *', hintText: 'Ex: Squat'),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: muscleCtrl,
              decoration: const InputDecoration(labelText: 'Groupe musculaire'),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      final exercises = await ref.read(workoutRepoProvider).getExercises(workoutId);
      final exercise = Exercise(
        id: const Uuid().v4(),
        workoutId: workoutId,
        name: nameCtrl.text.trim(),
        muscleGroup: muscleCtrl.text.trim().isEmpty ? null : muscleCtrl.text.trim(),
        orderIndex: exercises.length,
      );
      await ref.read(workoutRepoProvider).insertExercise(exercise);
      ref.invalidate(exercisesProvider(workoutId));
    }
  }
}
