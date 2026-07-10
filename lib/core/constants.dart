class AppConstants {
  static const String appName = 'WorkLog';

  // Supabase URL ve Anon Key (Loaded securely from environment variables)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eclvmlwnjtiulrthzjxx.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String entriesTable = 'work_entries';
  static const String clientsTable = 'clients';

  static const List<String> workTypes = ['Grafik', 'Yazılım', 'Diğer'];

  static const List<String> clientColors = [
    '#4A90D9', '#50C878', '#FF6B6B', '#FFB347',
    '#9B59B6', '#1ABC9C', '#E67E22', '#E91E63',
  ];
}