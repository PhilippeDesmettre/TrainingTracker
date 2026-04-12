import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/workout_history.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const EmptyState(
              icon: Icons.history_outlined,
              title: 'Aucune séance',
              subtitle: 'Lance ta première séance\npour voir ton historique ici.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _HistoryItem(
              history: history[index],
              onDelete: () => _confirmDelete(context, ref, history[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, WorkoutHistory history) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer la séance du ${DateFormat('d MMM yyyy', 'fr_FR').format(history.startedAt)} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyRepoProvider).deleteHistory(history.id);
      ref.invalidate(historyProvider);
      ref.invalidate(statsProvider);
    }
  }
}

class _HistoryItem extends StatefulWidget {
  const _HistoryItem({required this.history, required this.onDelete});
  final WorkoutHistory history;
  final VoidCallback onDelete;

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');
    final duration = history.duration;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(history.workoutName, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFormat.format(history.startedAt)} à ${timeFormat.format(history.startedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (duration != null)
                              _Tag(
                                icon: Icons.timer_outlined,
                                text: _formatDuration(duration),
                              ),
                            const SizedBox(width: 8),
                            _Tag(
                              icon: Icons.check_circle_outline,
                              text: '${history.completedSets} séries',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                        color: AppColors.cardAlt,
                        onSelected: (v) { if (v == 'delete') widget.onDelete(); },
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
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Détail des exercices
          if (_expanded && history.exercises.isNotEmpty) ...[
            Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: history.exercises.map((ex) => _ExerciseSummary(exercise: ex)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return '${m}min';
    return '${d.inHours}h${d.inMinutes.remainder(60).toString().padLeft(2, '0')}';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ExerciseSummary extends StatelessWidget {
  const _ExerciseSummary({required this.exercise});
  final HistoryExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.exerciseName, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: exercise.sets.where((s) => s.completed).map((s) {
              final reps = s.actualReps ?? s.plannedReps;
              final weight = s.actualWeight ?? s.plannedWeight;
              String label = 'Série ${s.setNumber}';
              if (reps != null) label += ' · $reps reps';
              if (weight != null && weight > 0) {
                label += ' @ ${weight % 1 == 0 ? weight.toInt() : weight}kg';
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.success),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
