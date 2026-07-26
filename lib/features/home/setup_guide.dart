import 'package:flutter/material.dart';
import '../../core/database/activity_database.dart';
import '../../core/theme.dart';
import '../../shared/localization.dart';
import '../../shared/widgets/app_logo.dart';

class SetupGuide extends StatefulWidget {
  const SetupGuide({super.key});

  @override
  State<SetupGuide> createState() => _SetupGuideState();
}

class _SetupGuideState extends State<SetupGuide> {
  int _step = 0;
  final _stepCtrl = TextEditingController(text: '8000');
  final _distCtrl = TextEditingController(text: '5.0');
  bool _isEnglish = true;

  final _steps = <_GuideStep>[
    _GuideStep(
      title: 'Welcome to SoloSprint!',
      icon: Icons.directions_run,
      color: AppTheme.accent,
    ),
    _GuideStep(
      title: 'Choose Language',
      icon: Icons.language,
      color: Colors.blue,
    ),
    _GuideStep(
      title: 'Set Daily Goal',
      icon: Icons.flag_outlined,
      color: AppTheme.success,
    ),
    _GuideStep(
      title: 'Your Features',
      icon: Icons.explore_outlined,
      color: Colors.purple,
    ),
  ];

  @override
  void dispose() {
    _stepCtrl.dispose();
    _distCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: List.generate(_steps.length, (i) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _step ? AppTheme.accent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // "Skip" button
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      _isEnglish ? 'Skip' : 'Lewati',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _isEnglish ? 'Back' : 'Kembali',
                          ),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: _step == 0 ? 1 : 2,
                      child: ElevatedButton(
                        onPressed: _step < _steps.length - 1 ? _next : _finish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _step < _steps.length - 1
                              ? (_isEnglish ? 'Next' : 'Lanjut')
                              : (_isEnglish ? 'Start Running!' : 'Mulai Lari!'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildWelcome();
      case 1:
        return _buildLanguage();
      case 2:
        return _buildGoals();
      case 3:
        return _buildFeatures();
      default:
        return const SizedBox();
    }
  }

  Widget _buildWelcome() {
    return Center(
      key: const ValueKey('welcome'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 100),
          const SizedBox(height: 24),
          Text(
            'SoloSprint',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your personal offline running tracker\nTrack runs, count steps, achieve goals',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Works 100% offline',
                  style: TextStyle(color: AppTheme.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguage() {
    return Center(
      key: const ValueKey('language'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 64, color: Colors.blue),
          const SizedBox(height: 20),
          Text(
            'Choose your language',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih bahasa yang Anda inginkan',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _langOption('English', true),
              const SizedBox(width: 16),
              _langOption('Bahasa Indonesia', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langOption(String label, bool isEnglish) {
    final selected = _isEnglish == isEnglish;
    return GestureDetector(
      onTap: () => setState(() => _isEnglish = isEnglish),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.accent : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              isEnglish ? '🇬🇧' : '🇮🇩',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoals() {
    return Center(
      key: const ValueKey('goals'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 64, color: AppTheme.success),
            const SizedBox(height: 20),
            Text(
              _isEnglish ? 'Set Your Daily Goal' : 'Atur Target Harian',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isEnglish
                  ? 'Stay motivated with daily targets'
                  : 'Tetap termotivasi dengan target harian',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _stepCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isEnglish ? 'Daily Steps' : 'Langkah Harian',
                prefixIcon: const Icon(Icons.directions_walk),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                suffixText: 'steps',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _distCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isEnglish ? 'Daily Distance (km)' : 'Jarak Harian (km)',
                prefixIcon: const Icon(Icons.route),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                suffixText: 'km',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      {'icon': Icons.directions_run, 'label': _isEnglish ? 'GPS Run Tracking' : 'Lacak Lari GPS', 'desc': _isEnglish ? 'Distance, pace, duration & route map' : 'Jarak, kecepatan, durasi & peta rute'},
      {'icon': Icons.directions_walk, 'label': _isEnglish ? 'Step Counter' : 'Penghitung Langkah', 'desc': _isEnglish ? 'Tracks steps even in background' : 'Hitung langkah di latar belakang'},
      {'icon': Icons.bar_chart_outlined, 'label': _isEnglish ? 'Statistics & Goals' : 'Statistik & Target', 'desc': _isEnglish ? 'Weekly summary, monthly stats' : 'Ringkasan mingguan, statistik bulanan'},
      {'icon': Icons.share_outlined, 'label': _isEnglish ? 'Share Cards' : 'Bagikan Kartu', 'desc': _isEnglish ? 'Share your runs on social media' : 'Bagikan lari ke media sosial'},
    ];

    return Center(
      key: const ValueKey('features'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_outlined, size: 64, color: Colors.purple),
            const SizedBox(height: 20),
            Text(
              _isEnglish ? 'Everything you need' : 'Semua yang kamu butuhkan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (f['icon'] as IconData) == Icons.directions_run
                              ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
                              : Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          f['icon'] as IconData,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f['label'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              f['desc'] as String,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _next() {
    setState(() => _step++);
  }

  void _finish() {
    // Save preferences
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

    Navigator.of(context).pop();
  }
}

class _GuideStep {
  final String title;
  final IconData icon;
  final Color color;
  const _GuideStep({
    required this.title,
    required this.icon,
    required this.color,
  });
}
