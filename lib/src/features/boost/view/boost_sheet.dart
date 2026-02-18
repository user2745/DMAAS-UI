import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/boost_cubit.dart';
import '../cubit/boost_state.dart';

// ── Intent model ─────────────────────────────────────────────────────────────

class _Intent {
  const _Intent({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
}

const _intents = [
  _Intent(
    id: 'break_down',
    label: 'Break into steps',
    subtitle: 'Get clear action items',
    icon: Icons.format_list_numbered,
  ),
  _Intent(
    id: 'draft_description',
    label: 'Write a description',
    subtitle: 'Clarify what needs to happen',
    icon: Icons.edit_note,
  ),
  _Intent(
    id: 'prioritize',
    label: 'Set priority',
    subtitle: 'Assess urgency & importance',
    icon: Icons.flag_outlined,
  ),
  _Intent(
    id: 'suggest_next',
    label: 'What\'s next',
    subtitle: 'One step after this task',
    icon: Icons.arrow_forward_ios,
  ),
];

// ── Loading phrases ───────────────────────────────────────────────────────────

const _phrases = [
  'Thinking it through',
  'Working on it',
  'Putting it together',
  'Almost there',
];

// ── Public entry point ────────────────────────────────────────────────────────

class BoostSheet extends StatelessWidget {
  const BoostSheet._({
    required this.taskId,
    required this.taskTitle,
    this.taskDescription,
  });

  final String taskId;
  final String taskTitle;
  final String? taskDescription;

  static Future<void> show(
    BuildContext context, {
    required String taskId,
    required String taskTitle,
    String? taskDescription,
  }) {
    // Reset state before opening
    context.read<BoostCubit>().reset();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BoostCubit>(),
        child: BoostSheet._(
          taskId: taskId,
          taskTitle: taskTitle,
          taskDescription: taskDescription,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoostCubit, BoostState>(
      builder: (context, state) {
        return _BoostSheetBody(
          taskId: taskId,
          taskTitle: taskTitle,
          taskDescription: taskDescription,
          state: state,
        );
      },
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _BoostSheetBody extends StatelessWidget {
  const _BoostSheetBody({
    required this.taskId,
    required this.taskTitle,
    required this.state,
    this.taskDescription,
  });

  final String taskId;
  final String taskTitle;
  final String? taskDescription;
  final BoostState state;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30363D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Boost this task',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE6EDF3),
                            ),
                          ),
                          Text(
                            taskTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B949E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Credit badge
                    if (state.creditsLoaded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF21262D),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: Text(
                          '${state.credits} left',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFBB86FC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 24, color: Color(0xFF21262D)),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (state.isLoading) {
      return const _LoadingView();
    }
    if (state.hasResult) {
      return _ResultView(
        result: state.result!,
        onBack: () => context.read<BoostCubit>().reset(),
      );
    }
    if (state.hasError) {
      return _ErrorView(
        message: state.errorMessage ?? 'Something went wrong.',
        onBack: () => context.read<BoostCubit>().reset(),
      );
    }
    // Idle — show intent picker
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you need?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8B949E),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ..._intents.map(
          (intent) => _IntentTile(
            intent: intent,
            onTap: () => context.read<BoostCubit>().boost(
                  taskId: taskId,
                  taskTitle: taskTitle,
                  taskDescription: taskDescription,
                  intent: intent.id,
                ),
          ),
        ),
        if (state.noCredits) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBB86FC).withAlpha(60)),
            ),
            child: const Row(
              children: [
                Text('⚡', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'ve used all your boost credits. More coming soon.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8B949E),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Intent tile ───────────────────────────────────────────────────────────────

class _IntentTile extends StatelessWidget {
  const _IntentTile({required this.intent, required this.onTap});

  final _Intent intent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            children: [
              Icon(intent.icon, size: 20, color: const Color(0xFFBB86FC)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intent.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE6EDF3),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      intent.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFF30363D)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading view ──────────────────────────────────────────────────────────────

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  int _phraseIndex = 0;
  int _dots = 1;
  Timer? _timer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % _phrases.length;
          _dots = (_dots % 3) + 1;
        });
      }
    });
    // Also tick dots faster
    Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _dots = (_dots % 3) + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotsStr = '.' * _dots;
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.1).animate(
              CurvedAnimation(
                parent: _pulseController,
                curve: Curves.easeInOut,
              ),
            ),
            child: const Text('⚡', style: TextStyle(fontSize: 44)),
          ),
          const SizedBox(height: 20),
          Text(
            '${_phrases[_phraseIndex]}$dotsStr',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF8B949E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result view ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onBack});

  final String result;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFBB86FC).withAlpha(80),
            ),
          ),
          child: SelectableText(
            result,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFE6EDF3),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Try another'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B949E),
                  side: const BorderSide(color: Color(0xFF30363D)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB86FC),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text('⚠️', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8B949E),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onBack,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF21262D),
            foregroundColor: const Color(0xFFE6EDF3),
          ),
          child: const Text('Go back'),
        ),
      ],
    );
  }
}
