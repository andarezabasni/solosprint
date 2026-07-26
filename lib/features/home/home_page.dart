import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/database/activity_database.dart';
import '../../core/language_provider.dart';
import '../../shared/localization.dart';
import '../../shared/widgets/weekly_summary.dart';
import '../../shared/widgets/app_logo.dart';
import '../settings/settings_page.dart';
import 'step_provider.dart';
import 'setup_guide.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _weekDistance = 0;
  int _weekDuration = 0;
  int _weekRuns = 0;
  DateTime _currentMonday = DateTime.now();

  @override
  void initState() {
    super.initState();
    _resetToCurrentWeek();
    _checkOnboarding();
  }

  void _resetToCurrentWeek() {
    final now = DateTime.now();
    _currentMonday = now.subtract(Duration(days: now.weekday - 1));
    _loadWeekStats();
  }

  void _loadWeekStats() {
    final end = _currentMonday
        .add(const Duration(days: 7));
    final start = DateTime(_currentMonday.year, _currentMonday.month, _currentMonday.day);

    setState(() {
      _weekDistance = ActivityDatabase.getTotalDistance(start, end);
      _weekDuration = ActivityDatabase.getTotalDuration(start, end);
      _weekRuns = ActivityDatabase.getTotalRuns(start, end);
    });
  }

  void _checkOnboarding() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ActivityDatabase.isFirstLaunch && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SetupGuide()),
        );
      }
    });
  }

  void _previousWeek() {
    setState(() {
      _currentMonday = _currentMonday.subtract(const Duration(days: 7));
      _loadWeekStats();
    });
  }

  void _nextWeek() {
    setState(() {
      _currentMonday = _currentMonday.add(const Duration(days: 7));
      _loadWeekStats();
    });
  }

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final todayMonday = now.subtract(Duration(days: now.weekday - 1));
    return _currentMonday.year == todayMonday.year &&
        _currentMonday.month == todayMonday.month &&
        _currentMonday.day == todayMonday.day;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final stepProvider = context.watch<StepProvider>();
    final stepTarget = ActivityDatabase.getGoal('daily_step_target',
        defaultValue: 8000);
    final distTarget =
        ActivityDatabase.getGoal('daily_dist_target', defaultValue: 5.0);
    final weekLabel = _isCurrentWeek
        ? 'This Week'
        : '${_currentMonday.day}/${_currentMonday.month} - ${_currentMonday.add(const Duration(days: 6)).day}/${_currentMonday.add(const Duration(days: 6)).month}';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 28),
            const SizedBox(width: 10),
            Text(Strings.appName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeekStats,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily summary banner
            Card(
              color: AppTheme.accent,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _bannerStat(
                        '${stepProvider.todaySteps}',
                        'Steps',
                        stepTarget.toInt()),
                    _bannerStat('0.0', 'Distance', 'km'),
                    _bannerStat(
                        stepProvider.status == 'walking' ? 'Walking' : '--',
                        'Status',
                        ''),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Weekly Summary (Apple Fitness style)
            WeeklySummary(
              dailySteps: stepProvider.getWeekSteps(_currentMonday),
              stepTarget: stepTarget,
              weekLabel: weekLabel,
              onPreviousWeek: _previousWeek,
              onNextWeek: _nextWeek,
              hasPreviousWeek: true,
              hasNextWeek: !_isCurrentWeek,
            ),

            const SizedBox(height: 20),

            // This Week stats
            Text(
              _isCurrentWeek ? 'This Week' : 'Week Stats',
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
                      distTarget > 0
                          ? '${(distTarget * 7).toStringAsFixed(1)} km weekly goal'
                          : '',
                    ),
                    const Divider(),
                    _buildWeekStat(
                      'Duration',
                      '$_weekDuration min',
                      '',
                    ),
                    const Divider(),
                    _buildWeekStat('Runs', '$_weekRuns', ''),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerStat(String value, String label, dynamic target) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        if (target is int && target > 0)
          Text(
            '/ $target',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
      ],
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
              if (goal.isNotEmpty)
                Text(goal,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
