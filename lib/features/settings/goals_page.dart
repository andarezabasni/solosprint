import 'package:flutter/material.dart';
import '../../core/database/activity_database.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late TextEditingController _weeklyDistanceController;
  late TextEditingController _weeklyDurationController;
  late TextEditingController _weeklyRunsController;
  late TextEditingController _monthlyDistanceController;
  late TextEditingController _monthlyDurationController;
  late TextEditingController _monthlyRunsController;

  @override
  void initState() {
    super.initState();
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

  void _saveGoals() {
    ActivityDatabase.saveGoal('weekly_distance', double.tryParse(_weeklyDistanceController.text) ?? 0);
    ActivityDatabase.saveGoal('weekly_duration', double.tryParse(_weeklyDurationController.text) ?? 0);
    ActivityDatabase.saveGoal('weekly_runs', double.tryParse(_weeklyRunsController.text) ?? 0);
    ActivityDatabase.saveGoal('monthly_distance', double.tryParse(_monthlyDistanceController.text) ?? 0);
    ActivityDatabase.saveGoal('monthly_duration', double.tryParse(_monthlyDurationController.text) ?? 0);
    ActivityDatabase.saveGoal('monthly_runs', double.tryParse(_monthlyRunsController.text) ?? 0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          TextButton(
            onPressed: _saveGoals,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Goals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildGoalField('Distance (km)', _weeklyDistanceController),
            const SizedBox(height: 12),
            _buildGoalField('Duration (min)', _weeklyDurationController),
            const SizedBox(height: 12),
            _buildGoalField('Runs', _weeklyRunsController),
            const SizedBox(height: 32),
            Text('Monthly Goals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildGoalField('Distance (km)', _monthlyDistanceController),
            const SizedBox(height: 12),
            _buildGoalField('Duration (min)', _monthlyDurationController),
            const SizedBox(height: 12),
            _buildGoalField('Runs', _monthlyRunsController),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
