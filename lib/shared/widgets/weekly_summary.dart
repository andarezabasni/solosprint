import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';

class WeeklySummary extends StatelessWidget {
  final Map<String, int> dailySteps;
  final double stepTarget;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final String weekLabel;
  final bool hasPreviousWeek;
  final bool hasNextWeek;

  const WeeklySummary({
    super.key,
    required this.dailySteps,
    required this.stepTarget,
    this.onPreviousWeek,
    this.onNextWeek,
    required this.weekLabel,
    this.hasPreviousWeek = true,
    this.hasNextWeek = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week navigation header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: hasPreviousWeek ? onPreviousWeek : null,
                  color: hasPreviousWeek ? AppTheme.accent : Colors.grey[300],
                ),
                Text(
                  weekLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: hasNextWeek ? onNextWeek : null,
                  color: hasNextWeek ? AppTheme.accent : Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Day circles row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: dailySteps.entries.map((entry) {
                return _DayCircle(
                  dateKey: entry.key,
                  steps: entry.value,
                  target: stepTarget,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String dateKey;
  final int steps;
  final double target;

  const _DayCircle({
    required this.dateKey,
    required this.steps,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final parts = dateKey.split('-');
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final date = DateTime(int.parse(parts[0]), month, day);
    final dayName = DateFormat('E').format(date)[0]; // M, T, W, T, F, S, S

    final progress = target > 0 ? (steps / target).clamp(0.0, 1.0) : 0.0;
    final isToday = dateKey ==
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final isComplete = progress >= 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress
        SizedBox(
          width: 48,
          height: 48,
          child: CustomPaint(
            painter: _CircleProgressPainter(
              progress: progress,
              isComplete: isComplete,
              isToday: isToday,
            ),
            child: Center(
              child: Text(
                steps > 999 ? '${(steps / 1000).toStringAsFixed(0)}k' : '$steps',
                style: TextStyle(
                  fontSize: steps > 999 ? 9 : 10,
                  fontWeight: FontWeight.bold,
                  color: isComplete
                      ? Colors.white
                      : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? AppTheme.accent : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final bool isComplete;
  final bool isToday;

  _CircleProgressPainter({
    required this.progress,
    required this.isComplete,
    required this.isToday,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Background circle
    paint.color = isToday ? AppTheme.accentLight.withValues(alpha: 0.2) : Colors.grey[200]!;
    canvas.drawCircle(center, radius, paint);

    if (isComplete) {
      // Filled circle
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF10B981)
          ..style = PaintingStyle.fill,
      );
    } else {
      // Progress arc
      paint.color = AppTheme.accent;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // start from top
        2 * math.pi * progress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isComplete != isComplete ||
      oldDelegate.isToday != isToday;
}
