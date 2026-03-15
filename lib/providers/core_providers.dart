import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';

final localDBServiceProvider = Provider((ref) => LocalDBService());
final supabaseServiceProvider = Provider((ref) => SupabaseService());
final syncServiceProvider = Provider((ref) => SyncService(
  localDB: ref.watch(localDBServiceProvider),
  supabase: ref.watch(supabaseServiceProvider),
));
