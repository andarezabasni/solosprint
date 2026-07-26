import 'dart:io';
import 'package:flutter/material.dart';
import '../../run/run_activity.dart';
import '../share_service.dart';

class PhotoTemplate extends StatelessWidget {
  final RunActivity activity;
  final String? imagePath;

  const PhotoTemplate({
    super.key,
    required this.activity,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;
    final subtextColor = Colors.white70;

    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        image: imagePath != null
            ? DecorationImage(
                image: FileImage(File(imagePath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Container(
        // 50% dark overlay
        decoration: const BoxDecoration(
          color: Color(0x80000000),
        ),
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Row(
              children: [
                const Icon(Icons.directions_run, color: Color(0xFFFF6B35), size: 36),
                const SizedBox(width: 12),
                Text(
                  'SoloSprint',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ShareService.formatDate(activity.startTime),
              style: TextStyle(color: subtextColor, fontSize: 18),
            ),
            const Spacer(),

            // Stats card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xCC1A1A2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('DISTANCE', activity.distance.toStringAsFixed(2), 'km', textColor, subtextColor),
                  _statItem('PACE', ShareService.formatPace(activity.pace), '/km', textColor, subtextColor),
                  _statItem('DURATION', ShareService.formatDuration(activity.duration), '', textColor, subtextColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Route stats line
            Center(
              child: Text(
                '${activity.route.length} GPS points tracked',
                style: TextStyle(color: subtextColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, String unit, Color textColor, Color subtextColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: subtextColor, fontSize: 14, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(unit, style: TextStyle(color: subtextColor, fontSize: 16)),
              ),
          ],
        ),
      ],
    );
  }
}
