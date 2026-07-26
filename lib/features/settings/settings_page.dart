import 'package:flutter/material.dart';
import 'goals_page.dart';
import '../../shared/demo_data.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Color(0xFFFF6B35)),
                  title: const Text('Goals'),
                  subtitle: const Text('Set weekly and monthly targets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GoalsPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.science_outlined, color: Color(0xFFFF6B35)),
                  title: const Text('Load Demo Data'),
                  subtitle: const Text('Add sample runs and goals for testing'),
                  onTap: () async {
                    await DemoData.loadAll();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo data loaded! Check Home, History & Stats.')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFFFF6B35)),
                  title: const Text('About'),
                  subtitle: const Text('SoloSprint v1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
