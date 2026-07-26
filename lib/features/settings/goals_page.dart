import 'package:flutter/material.dart';
import '../../core/database/activity_database.dart';
import '../../shared/localization.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late TextEditingController _dailyStepController;
  late TextEditingController _dailyDistController;
  late TextEditingController _weeklyDistanceController;
  late TextEditingController _weeklyDurationController;
  late TextEditingController _weeklyRunsController;
  late TextEditingController _monthlyDistanceController;
  late TextEditingController _monthlyDurationController;
  late TextEditingController _monthlyRunsController;

  @override
  void initState() {
    super.initState();
    _dailyStepController = TextEditingController(
      text: _formatInt(ActivityDatabase.getGoal('daily_step_target', defaultValue: 8000)),
    );
    _dailyDistController = TextEditingController(
      text: _formatGoal(ActivityDatabase.getGoal('daily_dist_target')),
    );
    _weeklyDistanceController = TextEditingController(
      text: _formatGoal(ActivityDatabase.getGoal('weekly_distance')),
    );
    _weeklyDurationController = TextEditingController(
      text: _formatGoal(ActivityDatabase.getGoal('weekly_duration')),
    );
    _weeklyRunsController = TextEditingController(
      text: _formatGoal(ActivityDatabase.getGoal('weekly_runs')),
    );
    _monthlyDistanceController = TextEditingController(
      text: _formatGoal(ActivityDatabase.getGoal('monthly_distance')),
    );
    _monthlyDurationController = TextEditingController(
      text: _formatGoal(ActivityDatabase.getGoal('monthly_duration')),
    );
    _monthlyRunsController = TextEditingController(
      text: _formatGoal(ActivityDatabase.getGoal('monthly_runs')),
    );
  }

  @override
  void dispose() {
    _dailyStepController.dispose();
    _dailyDistController.dispose();
    _weeklyDistanceController.dispose();
    _weeklyDurationController.dispose();
    _weeklyRunsController.dispose();
    _monthlyDistanceController.dispose();
    _monthlyDurationController.dispose();
    _monthlyRunsController.dispose();
    super.dispose();
  }

  String _formatGoal(double value) {
    return value > 0 ? value.toStringAsFixed(1) : '';
  }

  String _formatInt(double value) {
    return value > 0 ? value.toInt().toString() : '';
  }

  void _saveGoals() {
    ActivityDatabase.saveGoal('daily_step_target', double.tryParse(_dailyStepController.text) ?? 8000);
    ActivityDatabase.saveGoal('daily_dist_target', double.tryParse(_dailyDistController.text) ?? 0);
    ActivityDatabase.saveGoal('weekly_distance', double.tryParse(_weeklyDistanceController.text) ?? 0);
    ActivityDatabase.saveGoal('weekly_duration', double.tryParse(_weeklyDurationController.text) ?? 0);
    ActivityDatabase.saveGoal('weekly_runs', double.tryParse(_weeklyRunsController.text) ?? 0);
    ActivityDatabase.saveGoal('monthly_distance', double.tryParse(_monthlyDistanceController.text) ?? 0);
    ActivityDatabase.saveGoal('monthly_duration', double.tryParse(_monthlyDurationController.text) ?? 0);
    ActivityDatabase.saveGoal('monthly_runs', double.tryParse(_monthlyRunsController.text) ?? 0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.isEnglish ? 'Goals saved' : 'Target tersimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.isEnglish ? 'Goals' : 'Target'),
        actions: [
          TextButton(
            onPressed: _saveGoals,
            child: Text(
              Strings.save,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Goals
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.today, color: Color(0xFFFF6B35), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocale.isEnglish ? 'Daily Goals' : 'Target Harian',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildGoalField(
              AppLocale.isEnglish ? 'Daily Steps Target' : 'Target Langkah Harian',
              _dailyStepController,
              suffix: 'steps',
            ),
            const SizedBox(height: 12),
            _buildGoalField(
              AppLocale.isEnglish ? 'Daily Distance (km)' : 'Jarak Harian (km)',
              _dailyDistController,
              suffix: 'km',
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),

            // Weekly Goals
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: Color(0xFFFF6B35), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    Strings.weeklyGoals,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildGoalField(Strings.distanceKm, _weeklyDistanceController, suffix: 'km'),
            const SizedBox(height: 12),
            _buildGoalField(Strings.durationMin, _weeklyDurationController, suffix: 'min'),
            const SizedBox(height: 12),
            _buildGoalField(Strings.runs, _weeklyRunsController, suffix: ''),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),

            // Monthly Goals
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFFFF6B35), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    Strings.monthlyGoals,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildGoalField(Strings.distanceKm, _monthlyDistanceController, suffix: 'km'),
            const SizedBox(height: 12),
            _buildGoalField(Strings.durationMin, _monthlyDurationController, suffix: 'min'),
            const SizedBox(height: 12),
            _buildGoalField(Strings.runs, _monthlyRunsController, suffix: ''),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalField(String label, TextEditingController controller, {String suffix = ''}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix.isNotEmpty ? suffix : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
