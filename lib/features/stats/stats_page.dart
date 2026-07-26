import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/language_provider.dart';
import '../../shared/localization.dart';
import '../../core/database/activity_database.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _selectedPeriod = 'week'; // 'week' or 'month'

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.stats),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Period selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodButton('week', 'Weekly'),
              const SizedBox(width: 12),
              _buildPeriodButton('month', 'Monthly'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildStatsContent()),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    final now = DateTime.now();
    DateTime start;
    String title;

    if (_selectedPeriod == 'week') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      title = '${DateFormat.MMMd().format(start)} - ${DateFormat.MMMd().format(now)}';
    } else {
      start = DateTime(now.year, now.month, 1);
      title = DateFormat.yMMMM().format(now);
    }

    final end = now.add(const Duration(days: 1));
    final activities = ActivityDatabase.getActivitiesInRange(start, end);
    final totalDistance = activities.fold(0.0, (sum, a) => sum + a.distance);
    final totalMinutes = activities.fold(0, (sum, a) => sum + a.duration.inMinutes);
    final totalRuns = activities.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.route,
                  'Distance',
                  '${totalDistance.toStringAsFixed(1)} km',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.timer_outlined,
                  'Duration',
                  _formatMinutes(totalMinutes),
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.directions_run,
                  'Runs',
                  '$totalRuns',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.speed,
                  'Avg Pace',
                  totalRuns > 0
                      ? _formatPace(totalMinutes / totalDistance)
                      : '--',
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (activities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No activities yet', style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  String _formatPace(double pace) {
    if (pace <= 0 || pace.isInfinite || pace.isNaN) return '--';
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
