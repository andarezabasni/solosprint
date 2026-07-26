import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme_provider.dart';
import '../../core/language_provider.dart';
import '../../shared/localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/backup_service.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/demo_data.dart';
import 'goals_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(Strings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Goals
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Color(0xFFFF6B35)),
                  title: Text(Strings.goals),
                  subtitle: Text(Strings.goalsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalsPage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Appearance
          Card(
            child: Column(
              children: [
                // Dark mode toggle
                SwitchListTile(
                  secondary: Icon(
                    theme.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: const Color(0xFFFF6B35),
                  ),
                  title: Text(Strings.darkMode),
                  value: theme.isDark,
                  onChanged: (_) => theme.toggleTheme(),
                  activeThumbColor: const Color(0xFFFF6B35),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // Language
                ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFFFF6B35)),
                  title: Text(Strings.language),
                  subtitle: Text(Strings.languageSubtitle),
                  trailing: Text(
                    AppLocale.isEnglish ? 'EN' : 'ID',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  onTap: () => _showLanguageDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Data management
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined, color: Color(0xFFFF6B35)),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Export all data as Hive files'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => BackupService.exportData(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.restore_outlined, color: Color(0xFFFF6B35)),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Import from backup files'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => BackupService.restoreData(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Demo data
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined, color: Color(0xFFFF6B35)),
              title: Text(Strings.loadDemo),
              subtitle: Text(Strings.loadDemoSubtitle),
              onTap: () async {
                await DemoData.loadAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(Strings.demoLoaded)),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // Support Developer
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, color: Colors.red[400], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Support Developer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If you like this app, consider supporting:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _supportButton(
                          icon: Icons.coffee_outlined,
                          label: 'Saweria',
                          color: const Color(0xFFFFA726),
                          url: 'https://saweria.co/andreza09',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _supportButton(
                          icon: Icons.payments_outlined,
                          label: 'PayPal',
                          color: const Color(0xFF0070BA),
                          url: 'https://www.paypal.com/paypalme/andreza110',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Credits / Watermark
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppLogo(size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'SoloSprint',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Strings.madeBy,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  // Instagram — clickable
                  InkWell(
                    onTap: () => _openUrl('https://instagram.com/andreza.dev'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'andreza.dev',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new, size: 12, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // GitHub — clickable
                  InkWell(
                    onTap: () => _openUrl('https://github.com/andarezabasni'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.code, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'github.com/andarezabasni',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new, size: 12, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportButton({
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _openUrl(url),
      icon: Icon(icon, size: 18, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Strings.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle,
                  color: lang.isEnglish ? const Color(0xFFFF6B35) : Colors.grey),
              title: const Text('English'),
              onTap: () {
                lang.setEnglish();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle,
                  color: !lang.isEnglish ? const Color(0xFFFF6B35) : Colors.grey),
              title: const Text('Bahasa Indonesia'),
              onTap: () {
                lang.setIndonesian();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
