import 'package:flutter/material.dart';
import '../../core/database/activity_database.dart';
import '../../core/theme.dart';
import '../../shared/localization.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final _stepCtrl = TextEditingController(text: '8000');
  final _distCtrl = TextEditingController(text: '5.0');
  bool _isEnglish = true;

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
      title: const Text('Welcome!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_run, size: 48, color: AppTheme.accent),
            const SizedBox(height: 16),
            const Text(
              'Choose your language / Pilih bahasa:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _langButton('English', true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _langButton('Bahasa Indonesia', false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              _isEnglish
                  ? 'Set your daily goal to stay motivated!'
                  : 'Atur target harianmu untuk tetap termotivasi!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stepCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isEnglish ? 'Daily Steps Target' : 'Target Langkah Harian',
                prefixIcon: const Icon(Icons.directions_walk),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixText: 'steps',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _distCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isEnglish ? 'Daily Distance Target (km)' : 'Target Jarak Harian (km)',
                prefixIcon: const Icon(Icons.route),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixText: 'km',
              ),
            ),
          ],
        ),
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
            child: Text(
              _isEnglish ? 'Start' : 'Mulai',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _langButton(String label, bool isEnglish) {
    final selected = _isEnglish == isEnglish;
    return GestureDetector(
      onTap: () => setState(() => _isEnglish = isEnglish),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.accent : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_isEnglish) {
      AppLocale.setEnglish();
    } else {
      AppLocale.setIndonesian();
    }

    final steps = int.tryParse(_stepCtrl.text) ?? 8000;
    final dist = double.tryParse(_distCtrl.text) ?? 5.0;
    ActivityDatabase.saveGoal('daily_step_target', steps.toDouble());
    ActivityDatabase.saveGoal('daily_dist_target', dist);
    ActivityDatabase.setOnboardingDone();
    Navigator.pop(context);
  }
}
