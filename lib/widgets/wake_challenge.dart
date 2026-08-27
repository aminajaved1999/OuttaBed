import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class WakeChallenge {
  WakeChallenge({
    required this.question,
    required this.answer,
    required this.options,
  });

  final String question;
  final int answer;
  final List<int> options;

  factory WakeChallenge.random() {
    final random = Random();
    final a = 10 + random.nextInt(20);
    final b = 5 + random.nextInt(15);
    final answer = a + b;
    final options = <int>{answer};
    while (options.length < 4) {
      options.add(answer + random.nextInt(7) - 3);
    }
    final shuffled = options.toList()..shuffle(random);
    return WakeChallenge(
      question: '$a + $b = ?',
      answer: answer,
      options: shuffled,
    );
  }
}

class WakeChallengeSheet extends StatefulWidget {
  const WakeChallengeSheet({super.key, required this.onPassed});

  final VoidCallback onPassed;

  @override
  State<WakeChallengeSheet> createState() => _WakeChallengeSheetState();
}

class _WakeChallengeSheetState extends State<WakeChallengeSheet>
    with SingleTickerProviderStateMixin {
  late WakeChallenge _challenge;
  late AnimationController _shakeController;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _challenge = WakeChallenge.random();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _pick(int value) {
    HapticFeedback.mediumImpact();
    if (value == _challenge.answer) {
      HapticFeedback.heavyImpact();
      setState(() => _feedback = 'passed');
      Future.delayed(const Duration(milliseconds: 900), widget.onPassed);
      return;
    }
    HapticFeedback.vibrate();
    _shakeController.forward(from: 0);
    setState(() {
      _feedback = 'nope — try again bestie';
      _challenge = WakeChallenge.random();
    });
  }

  @override
  Widget build(BuildContext context) {
    final passed = _feedback == 'passed';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: passed ? _SuccessView() : _ChallengeView(
          key: ValueKey(_challenge.question),
          challenge: _challenge,
          feedback: _feedback,
          shakeController: _shakeController,
          onPick: _pick,
        ),
      ),
    );
  }
}

class _ChallengeView extends StatelessWidget {
  const _ChallengeView({
    super.key,
    required this.challenge,
    required this.feedback,
    required this.shakeController,
    required this.onPick,
  });

  final WakeChallenge challenge;
  final String? feedback;
  final AnimationController shakeController;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🧠', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(
          'QUICK CHECK',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.plumSoft,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'prove it.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.plum,
              ),
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: shakeController,
          builder: (context, child) {
            final offset = sin(shakeController.value * pi * 6) * 8;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: Text(
            challenge.question,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: AppColors.plum,
                ),
          ),
        ),
        if (feedback != null) ...[
          const SizedBox(height: 10),
          Text(
            feedback!,
            style: TextStyle(
              color: AppColors.rose,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          physics: const NeverScrollableScrollPhysics(),
          children: challenge.options.map((option) {
            return Material(
              color: AppColors.blush.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () => onPick(option),
                borderRadius: BorderRadius.circular(22),
                child: Center(
                  child: Text(
                    '$option',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.plum,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('✓', style: TextStyle(fontSize: 72, color: AppColors.coral)),
        Text(
          "YOU'RE ALIVE",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'GOOD MORNING.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.plumSoft,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
        ),
      ],
    );
  }
}
