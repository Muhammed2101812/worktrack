import 'package:uuid/uuid.dart';
import '../core/utils.dart';

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
  final String? projectId;
  final String? projectName;
  final String billingType;
  final double hourlyRate;
  final double totalPrice;
  final String? breakStart;
  final String? breakEnd;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;

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
    this.projectId,
    this.projectName,
    this.billingType = 'hourly',
    this.hourlyRate = 0.0,
    double? totalPrice,
    this.breakStart,
    this.breakEnd,
    String? createdAt,
    String? updatedAt,
    this.isDeleted = false,
  })  : assert(hourlyRate >= 0, 'hourlyRate cannot be negative'),
        assert(
            totalPrice == null || totalPrice >= 0, 'totalPrice cannot be negative'),
        id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String(),
        durationHours = _calcNetDuration(startTime, endTime, breakStart, breakEnd),
        totalPrice = totalPrice ??
            (billingType == 'hourly'
                ? (_calcNetDuration(startTime, endTime, breakStart, breakEnd) *
                    hourlyRate)
                : 0.0);

  /// Parses "HH:mm" into minutes-since-midnight, returning null on bad input.
  static int? _toMinutes(String? s) {
    if (s == null) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  /// Calculates gross duration between two "HH:mm" timestamps, correctly
  /// handling overnight shifts (e.g. 22:00→02:00 = 4 hours, not 0).
  static double _calcSpan(String start, String end) {
    final startMin = _toMinutes(start);
    final endMin = _toMinutes(end);
    if (startMin == null || endMin == null) return 0.0;
    var diff = endMin - startMin;
    if (diff == 0) return 0.0;
    // Overnight shift: end < start means it wraps past midnight.
    if (diff < 0) diff += 24 * 60;
    return diff / 60.0;
  }

  /// Gross work duration (without subtracting break time).
  static double _calcDuration(String start, String end) => _calcSpan(start, end);

  /// Break duration (also overnight-safe, though breaks rarely span midnight).
  static double _calcBreakDuration(String? breakStart, String? breakEnd) {
    if (breakStart == null || breakEnd == null) return 0.0;
    if (breakStart.isEmpty || breakEnd.isEmpty) return 0.0;
    return _calcSpan(breakStart, breakEnd);
  }

  /// Net duration = gross work span minus break time. Never negative.
  static double _calcNetDuration(
      String start, String end, String? breakStart, String? breakEnd) {
    final gross = _calcSpan(start, end);
    final brk = _calcBreakDuration(breakStart, breakEnd);
    final net = gross - brk;
    return net < 0 ? 0.0 : net;
  }

  /// Effective monetary value of this entry. Fixed-price entries use
  /// [totalPrice] when set; hourly entries use `durationHours * hourlyRate`.
  /// This is the single source of truth for income calculation across
  /// finance, stats and PDF export.
  double get effectivePrice {
    if (totalPrice > 0.0) return totalPrice;
    if (billingType == 'hourly') return durationHours * hourlyRate;
    return 0.0;
  }

  WorkEntry copyWith({
    String? clientId,
    String? clientName,
    String? clientColor,
    String? date,
    String? startTime,
    String? endTime,
    String? workType,
    String? notes,
    bool? synced,
    Object? projectId = _sentinel,
    Object? projectName = _sentinel,
    String? billingType,
    double? hourlyRate,
    double? totalPrice,
    Object? breakStart = _sentinel,
    Object? breakEnd = _sentinel,
    String? createdAt,
    String? updatedAt,
    bool? isDeleted,
  }) =>
      WorkEntry(
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
        projectId: identical(projectId, _sentinel)
            ? this.projectId
            : projectId as String?,
        projectName: identical(projectName, _sentinel)
            ? this.projectName
            : projectName as String?,
        billingType: billingType ?? this.billingType,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        totalPrice: totalPrice ?? this.totalPrice,
        breakStart: identical(breakStart, _sentinel)
            ? this.breakStart
            : breakStart as String?,
        breakEnd: identical(breakEnd, _sentinel)
            ? this.breakEnd
            : breakEnd as String?,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  static const _sentinel = Object();

  /// Minimal map sent to Supabase (no local-only sync/conflict fields).
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
        if (projectId != null) 'project_id': projectId,
        if (projectName != null) 'project_name': projectName,
        'billing_type': billingType,
        'hourly_rate': hourlyRate,
        'total_price': totalPrice,
        if (breakStart != null) 'break_start': breakStart,
        if (breakEnd != null) 'break_end': breakEnd,
        'is_deleted': isDeleted,
        'updated_at': updatedAt,
      };

  // SQLite için (synced + is_deleted sütunu var)
  Map<String, dynamic> toLocalMap() => {
        ...toMap(),
        'project_id': projectId,
        'project_name': projectName,
        'break_start': breakStart,
        'break_end': breakEnd,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'synced': synced ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory WorkEntry.fromMap(Map<String, dynamic> m) => WorkEntry(
        id: m['id'],
        clientId: m['client_id'] ?? '',
        clientName: decodeHtmlEntities(m['client_name'] ?? ''),
        clientColor: m['client_color'] ?? '#4A90D9',
        date: m['date'] ?? '',
        startTime: m['start_time'] ?? '',
        endTime: m['end_time'] ?? '',
        workType: decodeHtmlEntities(m['work_type'] ?? ''),
        notes: decodeHtmlEntities(m['notes'] ?? ''),
        synced: m['synced'] == 1 || m['synced'] == true,
        projectId: m['project_id'] as String?,
        projectName: m['project_name'] != null
            ? decodeHtmlEntities(m['project_name'] as String)
            : null,
        billingType: m['billing_type'] ?? 'hourly',
        hourlyRate: (m['hourly_rate'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (m['total_price'] as num?)?.toDouble() ?? 0.0,
        breakStart: (m['break_start'] as String?)?.isNotEmpty == true
            ? m['break_start'] as String?
            : null,
        breakEnd: (m['break_end'] as String?)?.isNotEmpty == true
            ? m['break_end'] as String?
            : null,
        createdAt: m['created_at'],
        updatedAt: m['updated_at'],
        isDeleted: (m['is_deleted'] == 1) || (m['is_deleted'] == true),
      );
}
