import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/workout_history.dart';
import '../../providers/providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: statsAsync.when(
        data: (stats) => historyAsync.when(
          data: (history) => _StatsContent(stats: stats, history: history),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats, required this.history});
  final Map<String, dynamic> stats;
  final List<WorkoutHistory> history;

  @override
  Widget build(BuildContext context) {
    final totalSessions = stats['total_sessions'] as int;
    final thisWeekSessions = stats['this_week_sessions'] as int;
    final totalVolume = stats['total_volume_kg'] as double;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cartes principales
        Row(
          children: [
            Expanded(
              child: _BigStat(
                value: '$totalSessions',
                label: 'Séances\ntotales',
                icon: Icons.emoji_events_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BigStat(
                value: '$thisWeekSessions',
                label: 'Cette\nsemaine',
                icon: Icons.calendar_today_outlined,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _BigStat(
          value: totalVolume > 0 ? '${_formatVolume(totalVolume)} kg' : '—',
          label: 'Volume total soulevé',
          icon: Icons.fitness_center,
          color: AppColors.warning,
          wide: true,
        ),

        if (history.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Fréquence (30 derniers jours)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _WeeklyChart(history: history),

          const SizedBox(height: 28),
          Text('Exercices les plus pratiqués', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _TopExercises(history: history),
        ] else ...[
          const SizedBox(height: 48),
          const Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart_outlined, size: 56, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'Lance ta première séance\npour voir tes stats évoluer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: wide
          ? Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.history});
  final List<WorkoutHistory> history;

  @override
  Widget build(BuildContext context) {
    // Compter les séances par jour sur les 30 derniers jours
    final now = DateTime.now();
    final days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
    final counts = <DateTime, int>{};
    for (final d in days) {
      final key = DateTime(d.year, d.month, d.day);
      counts[key] = 0;
    }
    for (final h in history) {
      if (h.finishedAt == null) continue;
      final key = DateTime(h.startedAt.year, h.startedAt.month, h.startedAt.day);
      if (counts.containsKey(key)) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    final values = counts.values.toList();
    final maxVal = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: counts.entries.map((entry) {
                final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
                final isToday = entry.key == DateTime(now.year, now.month, now.day);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: ratio > 0 ? 20 + ratio * 40 : 4,
                      decoration: BoxDecoration(
                        color: entry.value > 0
                            ? (isToday ? AppColors.secondary : AppColors.primary)
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('d MMM', 'fr_FR').format(days.first),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                "Aujourd'hui",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopExercises extends StatelessWidget {
  const _TopExercises({required this.history});
  final List<WorkoutHistory> history;

  @override
  Widget build(BuildContext context) {
    // Compter les occurrences par exercice
    final counts = <String, int>{};
    for (final h in history) {
      for (final ex in h.exercises) {
        counts[ex.exerciseName] = (counts[ex.exerciseName] ?? 0) + ex.sets.where((s) => s.completed).length;
      }
    }

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    final maxCount = top.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: top.mapIndexed((index, entry) {
          final ratio = maxCount > 0 ? entry.value / maxCount : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: index == 0 ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(
                            index == 0 ? AppColors.primary : AppColors.textMuted,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value} séries',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

extension _IndexedMap<T> on Iterable<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) f) {
    var i = 0;
    return map((item) => f(i++, item)).toList();
  }
}
