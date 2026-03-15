class AppConstants {
  static const String appName = 'WorkLog';

  // Supabase URL ve Anon Key (ADIM 1'DE MCP'DEN ALINDI)
  static const String supabaseUrl = 'https://eclvmlwnjtiulrthzjxx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjbHZtbHduanRpdWxydGh6anh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDc5MzIsImV4cCI6MjA4ODkyMzkzMn0.Tt2bUaOWJrb25CyIVO6p1uRbAX96WcKVnXVeOqm7c6Y';

  static const String entriesTable = 'work_entries';
  static const String clientsTable = 'clients';

  static const List<String> workTypes = ['Grafik', 'Yazılım', 'Diğer'];

  static const List<String> clientColors = [
    '#4A90D9', '#50C878', '#FF6B6B', '#FFB347',
    '#9B59B6', '#1ABC9C', '#E67E22', '#E91E63',
  ];
}