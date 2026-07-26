import 'package:flutter/material.dart';
import '../../core/database/activity_database.dart';
import '../../core/theme.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final _stepCtrl = TextEditingController(text: '8000');
  final _distCtrl = TextEditingController(text: '5.0');

  @override
  void dispose() {
    _stepCtrl.dispose();
    _distCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Set Your Daily Goal',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Set a daily step target to stay motivated!'),
          const SizedBox(height: 24),
          TextField(
            controller: _stepCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Daily Steps Target',
              prefixIcon: const Icon(Icons.directions_walk),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              suffixText: 'steps',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _distCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Daily Distance Target',
              prefixIcon: const Icon(Icons.route),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              suffixText: 'km',
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Start', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _save() {
    final steps = int.tryParse(_stepCtrl.text) ?? 8000;
    final dist = double.tryParse(_distCtrl.text) ?? 5.0;
    ActivityDatabase.saveGoal('daily_step_target', steps.toDouble());
    ActivityDatabase.saveGoal('daily_dist_target', dist);
    ActivityDatabase.setOnboardingDone();
    Navigator.pop(context);
  }
}
