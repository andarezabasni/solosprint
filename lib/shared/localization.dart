import '../core/database/activity_database.dart';

class AppLocale {
  static const _key = 'app_language';

  static bool get isEnglish {
    final lang = ActivityDatabase.getGoal(_key, defaultValue: 0);
    return lang == 0;
  }

  static bool get isIndonesian => !isEnglish;

  static void setEnglish() => ActivityDatabase.saveGoal(_key, 0);
  static void setIndonesian() => ActivityDatabase.saveGoal(_key, 1);

  static String get(String en, String id) => isEnglish ? en : id;
}

/// All user-facing strings organized by feature.
class Strings {
  // App
  static String get appName => AppLocale.get('SoloSprint', 'SoloSprint');
  static String get ok => AppLocale.get('OK', 'OK');
  static String get cancel => AppLocale.get('Cancel', 'Batal');
  static String get save => AppLocale.get('Save', 'Simpan');
  static String get done => AppLocale.get('Done', 'Selesai');
  static String get loading => AppLocale.get('Loading...', 'Memuat...');
  static String get noData => AppLocale.get('No data', 'Tidak ada data');
  static String get error => AppLocale.get('Error', 'Kesalahan');

  // Home
  static String get today => AppLocale.get('Today', 'Hari Ini');
  static String get thisWeek => AppLocale.get('This Week', 'Minggu Ini');
  static String get steps => AppLocale.get('Steps', 'Langkah');
  static String get distance => AppLocale.get('Distance', 'Jarak');
  static String get duration => AppLocale.get('Duration', 'Durasi');
  static String get pace => AppLocale.get('Pace', 'Kecepatan');
  static String get runs => AppLocale.get('Runs', 'Lari');
  static String get status => AppLocale.get('Status', 'Status');
  static String get walking => AppLocale.get('Walking', 'Berjalan');
  static String get running => AppLocale.get('Running', 'Berlari');
  static String get stopped => AppLocale.get('Stopped', 'Berhenti');

  // Run
  static String get readyToRun => AppLocale.get('Ready to run?', 'Siap lari?');
  static String get start => AppLocale.get('Start', 'Mulai');
  static String get pause => AppLocale.get('Pause', 'Jeda');
  static String get resume => AppLocale.get('Resume', 'Lanjut');
  static String get stop => AppLocale.get('Stop', 'Berhenti');
  static String get finishRun => AppLocale.get('Finish Run?', 'Akhiri Lari?');
  static String get saveRun => AppLocale.get('Save', 'Simpan');

  // History
  static String get history => AppLocale.get('History', 'Riwayat');
  static String get noActivities => AppLocale.get('No activities yet', 'Belum ada aktivitas');
  static String get tapToViewRoute => AppLocale.get('Tap to view route map', 'Tap untuk lihat rute');
  static String get runDetail => AppLocale.get('Run Detail', 'Detail Lari');

  // Stats
  static String get stats => AppLocale.get('Stats', 'Statistik');
  static String get weekly => AppLocale.get('Weekly', 'Mingguan');
  static String get monthly => AppLocale.get('Monthly', 'Bulanan');
  static String get avgPace => AppLocale.get('Avg Pace', 'Rata-rata Kecepatan');

  // Settings
  static String get settings => AppLocale.get('Settings', 'Pengaturan');
  static String get goals => AppLocale.get('Goals', 'Target');
  static String get goalsSubtitle => AppLocale.get('Set weekly and monthly targets', 'Atur target mingguan & bulanan');
  static String get about => AppLocale.get('About', 'Tentang');
  static String get loadDemo => AppLocale.get('Load Demo Data', 'Muat Data Demo');
  static String get loadDemoSubtitle => AppLocale.get('Add sample runs and goals for testing', 'Tambah contoh lari & target');
  static String get demoLoaded => AppLocale.get('Demo data loaded!', 'Data demo dimuat!');
  static String get darkMode => AppLocale.get('Dark Mode', 'Mode Gelap');
  static String get language => AppLocale.get('Language', 'Bahasa');
  static String get languageSubtitle => AppLocale.get('English / Indonesian', 'English / Indonesia');

  // Share
  static String get shareActivity => AppLocale.get('Share Activity', 'Bagikan Aktivitas');
  static String get classic => AppLocale.get('Classic', 'Klasik');
  static String get photo => AppLocale.get('Photo', 'Foto');
  static String get map => AppLocale.get('Map', 'Peta');
  static String get choosePhoto => AppLocale.get('Choose Photo', 'Pilih Foto');
  static String get changePhoto => AppLocale.get('Change Photo', 'Ganti Foto');
  static String get saveImage => AppLocale.get('Save Image', 'Simpan Gambar');
  static String get share => AppLocale.get('Share', 'Bagikan');
  static String get savedToGallery => AppLocale.get('Image saved to gallery!', 'Gambar tersimpan di galeri!');
  static String get saveFailed => AppLocale.get('Save failed', 'Gagal menyimpan');
  static String get shareFailed => AppLocale.get('Share failed', 'Gagal membagikan');

  // Onboarding / Goals
  static String get setDailyGoal => AppLocale.get('Set Your Daily Goal', 'Atur Target Harian');
  static String get setDailyGoalSubtitle => AppLocale.get('Set a daily step target to stay motivated!', 'Atur target langkah harian untuk tetap termotivasi!');
  static String get dailySteps => AppLocale.get('Daily Steps Target', 'Target Langkah Harian');
  static String get dailyDistance => AppLocale.get('Daily Distance Target', 'Target Jarak Harian');
  static String get weeklyGoals => AppLocale.get('Weekly Goals', 'Target Mingguan');
  static String get monthlyGoals => AppLocale.get('Monthly Goals', 'Target Bulanan');
  static String get distanceKm => AppLocale.get('Distance (km)', 'Jarak (km)');
  static String get durationMin => AppLocale.get('Duration (min)', 'Durasi (menit)');
  static String get goalsSaved => AppLocale.get('Goals saved', 'Target tersimpan');

  // Week summary
  static String get weekLabel => AppLocale.get('This Week', 'Minggu Ini');
  static String get weekStats => AppLocale.get('Week Stats', 'Statistik Minggu');

  // Dark mode
  static String get dark => AppLocale.get('Dark', 'Gelap');
  static String get light => AppLocale.get('Light', 'Terang');

  // Language selection dialog
  static String get selectLanguage => AppLocale.get('Select Language', 'Pilih Bahasa');
  static String get english => 'English';
  static String get indonesian => 'Bahasa Indonesia';

  // Credits
  static String get madeBy => AppLocale.get('Made with ❤️ by', 'Dibuat dengan ❤️ oleh');
}
