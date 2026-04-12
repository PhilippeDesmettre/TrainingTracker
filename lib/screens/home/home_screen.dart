import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/workout_history.dart';
import '../../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final statsAsync = ref.watch(statsProvider);
    final now = DateTime.now();
    final greeting = _greeting(now.hour);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                greeting,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.fitness_center),
                tooltip: 'Programmes',
                onPressed: () => context.go('/programs'),
              ),
            ],
          ),

          // Stats rapides
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (stats) => _QuickStats(stats: stats),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Bouton principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/programs'),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('Commencer un entraînement'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ),
          ),

          // Titre section historique
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Séances récentes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),

          // Liste historique
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.textMuted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aucune séance pour le moment.\nCommence ton premier entraînement !',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, index < history.length - 1 ? 10 : 20),
                    child: _HistoryCard(history: history[index]),
                  ),
                  childCount: history.take(5).length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Bonjour 💪';
    if (hour < 18) return 'Bonne séance 🔥';
    return 'Bonsoir 🌙';
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          _StatChip(
            label: 'Cette semaine',
            value: '${stats['this_week_sessions']}',
            unit: 'séances',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Total',
            value: '${stats['total_sessions']}',
            unit: 'séances',
            icon: Icons.emoji_events_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});
  final WorkoutHistory history;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM', 'fr_FR');
    final duration = history.duration;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
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
                  '${history.programName} · ${dateFormat.format(history.startedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (duration != null)
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              Text(
                '${history.completedSets} séries',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
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
