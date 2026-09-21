import 'package:flutter/material.dart';
import 'dart:async';
import '../core/theme.dart';

class NextMatchTimer extends StatefulWidget {
  final DateTime targetTime;
  const NextMatchTimer({super.key, required this.targetTime});

  @override
  State<NextMatchTimer> createState() => _NextMatchTimerState();
}

class _NextMatchTimerState extends State<NextMatchTimer> {
  late Timer _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calc();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _calc());
  }

  void _calc() {
    final now = DateTime.now();
    if (widget.targetTime.isAfter(now)) {
      setState(() => _timeRemaining = widget.targetTime.difference(now));
    } else {
      setState(() => _timeRemaining = Duration.zero);
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining == Duration.zero) return const SizedBox();
    String days = _timeRemaining.inDays > 0 ? '${_timeRemaining.inDays}d ' : '';
    String hours = (_timeRemaining.inHours % 24).toString().padLeft(2, '0');
    String minutes = (_timeRemaining.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_timeRemaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Text('NEXT MATCH IN: $days$hours : $minutes : $seconds',
              style: const TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 13)),
        ],
      ),
    );
  }
}