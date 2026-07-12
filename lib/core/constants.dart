class AppConstants {
  static const String appName = 'WorkLog';

  // Supabase URL ve Anon Key (Loaded securely from environment variables)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qattsgpayyklmtgwygtu.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFhdHRzZ3BheXlrbG10Z3d5Z3R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2OTMyMDEsImV4cCI6MjA5OTI2OTIwMX0.uvFOo6YHz9mDUMEhAGlEFktMEugxYuUmmmjnCBE93pw',
  );

  // Google OAuth Client ID (Loaded securely from environment variables)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '430614470319-al4ugk9ub67kkisacq59dbjqbv9mm6u6.apps.googleusercontent.com',
  );

  static const String entriesTable = 'work_entries';
  static const String clientsTable = 'clients';
  static const String projectsTable = 'projects';

  static const List<String> workTypes = ['Grafik', 'Yazılım', 'Diğer'];

  static const List<String> clientColors = [
    '#4A90D9', '#50C878', '#FF6B6B', '#FFB347',
    '#9B59B6', '#1ABC9C', '#E67E22', '#E91E63',
  ];
}