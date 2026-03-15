import 'package:uuid/uuid.dart';

class WorkEntry {
  final String id;
  final String clientId;
  final String clientName;
  final String clientColor;
  final String date;
  final String startTime;
  final String endTime;
  final double durationHours;
  final String workType;
  final String notes;
  final bool synced;

  WorkEntry({
    String? id,
    required this.clientId,
    required this.clientName,
    required this.clientColor,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.workType,
    this.notes = '',
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        durationHours = _calcDuration(startTime, endTime);

  static double _calcDuration(String start, String end) {
    final s = start.split(':');
    final e = end.split(':');
    final startMin = int.parse(s[0]) * 60 + int.parse(s[1]);
    final endMin = int.parse(e[0]) * 60 + int.parse(e[1]);
    final diff = endMin - startMin;
    return diff > 0 ? diff / 60.0 : 0.0;
  }

  WorkEntry copyWith({
    String? clientId, String? clientName, String? clientColor, String? date,
    String? startTime, String? endTime, String? workType,
    String? notes, bool? synced,
  }) => WorkEntry(
    id: id,
    clientId: clientId ?? this.clientId,
    clientName: clientName ?? this.clientName,
    clientColor: clientColor ?? this.clientColor,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    workType: workType ?? this.workType,
    notes: notes ?? this.notes,
    synced: synced ?? this.synced,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'client_id': clientId,
    'client_name': clientName,
    'client_color': clientColor,
    'date': date,
    'start_time': startTime,
    'end_time': endTime,
    'duration_hours': durationHours,
    'work_type': workType,
    'notes': notes,
  };

  // SQLite için (synced sütunu var)
  Map<String, dynamic> toLocalMap() => {
    ...toMap(),
    'synced': synced ? 1 : 0,
  };

  factory WorkEntry.fromMap(Map<String, dynamic> m) => WorkEntry(
    id: m['id'],
    clientId: m['client_id'] ?? '',
    clientName: m['client_name'] ?? '',
    clientColor: m['client_color'] ?? '#4A90D9',
    date: m['date'] ?? '',
    startTime: m['start_time'] ?? '',
    endTime: m['end_time'] ?? '',
    workType: m['work_type'] ?? '',
    notes: m['notes'] ?? '',
    synced: m['synced'] == 1 || m['synced'] == true,
  );
}