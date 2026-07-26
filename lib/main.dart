import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/language_provider.dart';
import 'core/database/activity_database.dart';
import 'features/home/home_page.dart';
import 'features/home/step_provider.dart';
import 'features/run/run_page.dart';
import 'features/history/history_page.dart';
import 'features/stats/stats_page.dart';
import 'features/settings/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ActivityDatabase.init();
  runApp(const SoloSprintApp());
}

class SoloSprintApp extends StatefulWidget {
  const SoloSprintApp({super.key});

  @override
  State<SoloSprintApp> createState() => _SoloSprintAppState();
}

class _SoloSprintAppState extends State<SoloSprintApp> {
  final _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => StepProvider()..startListening()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'SoloSprint',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.themeMode,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomePage(),
    RunPage(),
    HistoryPage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Run'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
