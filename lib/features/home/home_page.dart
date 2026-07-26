import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/activity_database.dart';
import '../../shared/widgets/stat_card.dart';
import 'step_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _weekDistance = 0;
  int _weekDuration = 0;
  int _weekRuns = 0;

  @override
  void initState() {
    super.initState();
    _loadWeekStats();
  }

  void _loadWeekStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = now.add(const Duration(days: 1));

    setState(() {
      _weekDistance = ActivityDatabase.getTotalDistance(start, end);
      _weekDuration = ActivityDatabase.getTotalDuration(start, end);
      _weekRuns = ActivityDatabase.getTotalRuns(start, end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final weekDistanceGoal = ActivityDatabase.getGoal('weekly_distance');
    final weekDurationGoal = ActivityDatabase.getGoal('weekly_duration');
    final weekRunsGoal = ActivityDatabase.getGoal('weekly_runs');

    return Scaffold(
      appBar: AppBar(
        title: const Text('SoloSprint'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeekStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.directions_walk,
                    label: 'Steps',
                    value: '${stepProvider.todaySteps}',
                    unit: 'steps',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.route,
                    label: 'Distance',
                    value: '0.0',
                    unit: 'km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: '0',
                    unit: 'min',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.speed,
                    label: 'Pace',
                    value: '--',
                    unit: '/km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.directions_run, size: 28),
                label: const Text(
                  'Start Run',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'This Week',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildWeekStat(
                      'Distance',
                      '${_weekDistance.toStringAsFixed(1)} km',
                      weekDistanceGoal > 0 ? '${weekDistanceGoal.toStringAsFixed(1)} km goal' : 'No goal set',
                    ),
                    const Divider(),
                    _buildWeekStat(
                      'Duration',
                      '$_weekDuration min',
                      weekDurationGoal > 0 ? '${weekDurationGoal.toStringAsFixed(0)} min goal' : 'No goal set',
                    ),
                    const Divider(),
                    _buildWeekStat(
                      'Runs',
                      '$_weekRuns',
                      weekRunsGoal > 0 ? '${weekRunsGoal.toStringAsFixed(0)} runs goal' : 'No goal set',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStat(String label, String current, String goal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(current,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(goal,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
