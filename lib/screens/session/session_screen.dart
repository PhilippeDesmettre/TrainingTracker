import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';
import '../../models/active_session.dart';
import '../../providers/session_provider.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.workoutId});
  final String workoutId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  bool _loading = true;
  late final AudioPlayer _audioPlayer;
  ProviderSubscription<ActiveSession?>? _sessionSub;

  @override
  void initState() {
    super.initState();
    _sessionSub = ref.listenManual<ActiveSession?>(
      sessionProvider,
      (previous, next) {
        debugPrint(
          '[SESSION_LISTEN] '
          'prev: isResting=${previous?.isResting}, rest=${previous?.restSecondsRemaining}, total=${previous?.restTotalSeconds} '
          '-> '
          'next: isResting=${next?.isResting}, rest=${next?.restSecondsRemaining}, total=${next?.restTotalSeconds}',
        );
      },
    );
    _init();
  }

  Future<void> _init() async {
    _audioPlayer = AudioPlayer();
    await _startSession();
  }

  @override
  void dispose() {
    _sessionSub?.close();
    ref.read(sessionProvider.notifier).onRestDone = null;
    _elapsedTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    await ref.read(sessionProvider.notifier).startSession(widget.workoutId);
    if (!mounted) return;
    ref.read(sessionProvider.notifier).onRestDone = () async {
      if (!mounted) return;
      _audioPlayer.seek(Duration.zero).then((_) => _audioPlayer.play());
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
    };
    setState(() => _loading = false);
    await _audioPlayer.setAsset('assets/sounds/beep.wav');
    await _audioPlayer.load();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = ref.read(sessionProvider)?.elapsed ?? Duration.zero);
    });
  }

  Future<void> _confirmAbandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonner la séance ?'),
        content: const Text('La progression de cette séance sera perdue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuer')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionProvider.notifier).abandonSession();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    debugPrint(
      '[SESSION_UI] build: '
      'loading=$_loading, '
      'isResting=${session?.isResting}, '
      'rest=${session?.restSecondsRemaining}, '
      'total=${session?.restTotalSeconds}, '
      'isCompleted=${session?.isCompleted}',
    );

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (session == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text('Impossible de démarrer la séance.'),
                const SizedBox(height: 8),
                const Text(
                  'Vérifie que la séance contient des exercices avec des séries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => context.pop(), child: const Text('Retour')),
              ],
            ),
          ),
        ),
      );
    }

    if (session.isCompleted) {
      return _CompletionScreen(
        session: session,
        elapsed: _elapsed,
        onDone: () {
          ref.read(sessionProvider.notifier).clearSession();
          context.go('/history');
        },
      );
    }

    final allDone = session.exercises
        .expand((e) => e.sets)
        .every((s) => s.completed);

    final nextSetId = allDone ? null : _findNextSetId(session);

    debugPrint(
      '[SESSION_UI] bottomNavigationBar='
      '${session.isResting ? 'RestBanner' : allDone ? 'FinishButton' : 'null'}',
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmAbandon();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Barre de progression globale
              LinearProgressIndicator(
                value: session.totalSets > 0
                    ? session.completedSets / session.totalSets
                    : 0,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 3,
              ),

              // Header
              _SessionHeader(
                session: session,
                elapsed: _elapsed,
                onAbandon: _confirmAbandon,
              ),

              // Liste scrollable de tous les exercices
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: session.exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _ExerciseSection(
                    exercise: session.exercises[index],
                    exerciseIndex: index,
                    totalExercises: session.exercises.length,
                    nextSetId: nextSetId,
                    isResting: session.isResting,
                    onCheckSet: (setId) =>
                        ref.read(sessionProvider.notifier).completeSetById(setId),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bandeau bas : chrono de repos OU bouton terminer
        bottomNavigationBar: session.isResting
            ? _RestBanner(
                secondsRemaining: session.restSecondsRemaining,
                totalSeconds: session.restTotalSeconds,
                onSkip: () {
                  ref.read(sessionProvider.notifier).skipRest();
                  final nextId = _findNextSetId(ref.read(sessionProvider)!);
                  if (nextId != null) {
                    ref.read(sessionProvider.notifier).completeSetById(nextId);
                  }
                },
              )
            : allDone
                ? _FinishButton(
                    onTap: () =>
                        ref.read(sessionProvider.notifier).finishSession(),
                  )
                : null,
      ),
    );
  }

  String? _findNextSetId(ActiveSession session) {
    for (final ex in session.exercises) {
      for (final s in ex.sets) {
        if (!s.completed) return s.historySetId;
      }
    }
    return null;
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.session,
    required this.elapsed,
    required this.onAbandon,
  });

  final ActiveSession session;
  final Duration elapsed;
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final elapsedStr = h > 0 ? '$h:$m:$s' : '$m:$s';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: onAbandon,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  session.workoutName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  elapsedStr,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${session.completedSets}/${session.totalSets}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section exercice ──────────────────────────────────────────────────────────

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.nextSetId,
    required this.isResting,
    required this.onCheckSet,
  });

  final ActiveExercise exercise;
  final int exerciseIndex;
  final int totalExercises;
  final String? nextSetId;
  final bool isResting;
  final void Function(String historySetId) onCheckSet;

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
          // En-tête exercice
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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
                Text(
                  '${exerciseIndex + 1}/$totalExercises',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // En-tête colonnes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
            child: Row(
              children: [
                const SizedBox(width: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reps · Charge',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // Lignes de séries
          ...exercise.sets.map(
            (set) => _SetRow(
              set: set,
              isNext: set.historySetId == nextSetId,
              onCheck: (set.completed || isResting) ? null : () => onCheckSet(set.historySetId),
            ),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ── Ligne de série ────────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  const _SetRow({required this.set, required this.isNext, required this.onCheck});

  final ActiveSet set;
  final bool isNext;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final done = set.completed;
    final textColor = done ? AppColors.textMuted : AppColors.textPrimary;
    final reps = set.plannedReps;
    final weight = set.plannedWeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isNext ? AppColors.primary.withValues(alpha: 0.07) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isNext
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          // Numéro de série
          SizedBox(
            width: 22,
            child: Text(
              '${set.setNumber}',
              style: TextStyle(
                color: done ? AppColors.textMuted : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Reps
          Expanded(
            child: Row(
              children: [
                Text(
                  reps != null ? '$reps' : '—',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
                const Text(
                  ' reps',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                if (weight != null && weight > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· ${_fmt(weight)} kg',
                    style: TextStyle(
                      color: done ? AppColors.textMuted : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Checkbox
          GestureDetector(
            onTap: onCheck,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.success.withValues(alpha: 0.15) : Colors.transparent,
                border: done
                    ? null
                    : Border.all(
                        color: isNext ? AppColors.primary : AppColors.divider,
                        width: 2,
                      ),
              ),
              child: done
                  ? const Icon(Icons.check, color: AppColors.success, size: 16)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double w) => w % 1 == 0 ? w.toInt().toString() : w.toString();
}

// ── Bandeau repos ─────────────────────────────────────────────────────────────

class _RestBanner extends StatelessWidget {
  const _RestBanner({
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.onSkip,
  });

  final int secondsRemaining;
  final int totalSeconds;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[REST_BANNER] build: secondsRemaining=$secondsRemaining, totalSeconds=$totalSeconds',
    );
    final progress =
        totalSeconds > 0 ? 1.0 - (secondsRemaining / totalSeconds) : 1.0;
    final mm = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Repos : $mm:$ss',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Passer'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bouton terminer ───────────────────────────────────────────────────────────

class _FinishButton extends StatelessWidget {
  const _FinishButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: const Text('Terminer la séance'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ),
    );
  }
}

// ── Écran de fin de séance (inchangé) ─────────────────────────────────────────

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    required this.session,
    required this.elapsed,
    required this.onDone,
  });

  final ActiveSession session;
  final Duration elapsed;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes;
    final completedSets = session.completedSets;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.success, size: 50),
                ),
                const SizedBox(height: 28),
                Text('Séance terminée !', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(session.workoutName, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBadge(value: '${minutes}min', label: 'Durée'),
                    _StatBadge(value: '${session.exercises.length}', label: 'Exercices'),
                    _StatBadge(value: '$completedSets', label: 'Séries'),
                  ],
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(200, 52)),
                  child: const Text("Voir l'historique"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
