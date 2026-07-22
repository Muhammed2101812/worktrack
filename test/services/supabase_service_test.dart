import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worklog/services/supabase_service.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/core/constants.dart';

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final Future<T> _future;

  FakePostgrestFilterBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Future<dynamic> Function(Object values) onUpsert;

  FakeSupabaseQueryBuilder({required this.onUpsert});

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    return FakePostgrestFilterBuilder<dynamic>(onUpsert(values));
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final FakeSupabaseQueryBuilder queryBuilder;

  FakeSupabaseClient(this.queryBuilder);

  @override
  FakeSupabaseQueryBuilder from(String relation) {
    return queryBuilder;
  }
}

void main() {
  group('SupabaseService Tests', () {
    late FakeSupabaseClient fakeSupabaseClient;
    late FakeSupabaseQueryBuilder fakeQueryBuilder;
    late SupabaseService supabaseService;
    late List<Object> upsertCalls;
    late Future<dynamic> Function(Object) upsertHandler;

    setUp(() {
      upsertCalls = [];
      upsertHandler = (values) async {
        if (values is List) {
          upsertCalls.add(
            values.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
          );
        } else if (values is Map) {
          upsertCalls.add(Map<String, dynamic>.from(values));
        } else {
          upsertCalls.add(values);
        }
        return <Map<String, dynamic>>[];
      };
      fakeQueryBuilder = FakeSupabaseQueryBuilder(
        onUpsert: (values) => upsertHandler(values),
      );
      fakeSupabaseClient = FakeSupabaseClient(fakeQueryBuilder);
      supabaseService = SupabaseService(client: fakeSupabaseClient);
    });

    test('should have SupabaseService class', () {
      expect(() => SupabaseService(client: fakeSupabaseClient), returnsNormally);
    });

    group('upsertEntry', () {
      final entry = WorkEntry(
        id: 'e1',
        clientId: 'c1',
        clientName: 'Client 1',
        clientColor: '#123456',
        date: '01.01.2025',
        startTime: '09:00',
        endTime: '17:00',
        workType: 'Software',
      );

      test('should succeed directly on the first try', () async {
        await expectLater(supabaseService.upsertEntry(entry), completes);

        expect(upsertCalls.length, equals(1));
        expect(upsertCalls.first, equals(entry.toMap()));
      });

      test('should remove client_color and retry on client_color PostgrestException', () async {
        var callCount = 0;
        upsertHandler = (values) async {
          if (values is List) {
            upsertCalls.add(
              values.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
            );
          } else if (values is Map) {
            upsertCalls.add(Map<String, dynamic>.from(values));
          } else {
            upsertCalls.add(values);
          }
          callCount++;
          if (callCount == 1) {
            throw const PostgrestException(
              message: 'Could not find column client_color in table work_entries',
            );
          }
          return <Map<String, dynamic>>[];
        };

        await expectLater(supabaseService.upsertEntry(entry), completes);

        expect(upsertCalls.length, equals(2));
        expect(upsertCalls[0], equals(entry.toMap()));

        final expectedMap = entry.toMap()..remove('client_color');
        expect(upsertCalls[1], equals(expectedMap));
      });

      test('should rethrow immediately without retrying on other PostgrestExceptions', () async {
        upsertHandler = (values) async {
          if (values is List) {
            upsertCalls.add(
              values.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
            );
          } else if (values is Map) {
            upsertCalls.add(Map<String, dynamic>.from(values));
          } else {
            upsertCalls.add(values);
          }
          throw const PostgrestException(
            message: 'Database connection timeout',
          );
        };

        await expectLater(
          supabaseService.upsertEntry(entry),
          throwsA(isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            'Database connection timeout',
          )),
        );

        expect(upsertCalls.length, equals(1));
        expect(upsertCalls[0], equals(entry.toMap()));
      });
    });

    group('upsertEntries', () {
      final entries = [
        WorkEntry(
          id: 'e1',
          clientId: 'c1',
          clientName: 'Client 1',
          clientColor: '#123456',
          date: '01.01.2025',
          startTime: '09:00',
          endTime: '17:00',
          workType: 'Software',
        ),
        WorkEntry(
          id: 'e2',
          clientId: 'c2',
          clientName: 'Client 2',
          clientColor: '#654321',
          date: '02.01.2025',
          startTime: '10:00',
          endTime: '18:00',
          workType: 'Hardware',
        ),
      ];

      test('should succeed directly on the first try', () async {
        await expectLater(supabaseService.upsertEntries(entries), completes);

        expect(upsertCalls.length, equals(1));
        final expectedList = entries.map((e) => e.toMap()).toList();
        expect(upsertCalls.first, equals(expectedList));
      });

      test('should remove client_color and retry on client_color PostgrestException', () async {
        var callCount = 0;
        upsertHandler = (values) async {
          if (values is List) {
            upsertCalls.add(
              values.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
            );
          } else if (values is Map) {
            upsertCalls.add(Map<String, dynamic>.from(values));
          } else {
            upsertCalls.add(values);
          }
          callCount++;
          if (callCount == 1) {
            throw const PostgrestException(
              message: 'Could not find column client_color in table work_entries',
            );
          }
          return <Map<String, dynamic>>[];
        };

        await expectLater(supabaseService.upsertEntries(entries), completes);

        expect(upsertCalls.length, equals(2));

        final expectedListTry1 = entries.map((e) => e.toMap()).toList();
        expect(upsertCalls[0], equals(expectedListTry1));

        final expectedListTry2 = entries.map((e) => e.toMap()..remove('client_color')).toList();
        expect(upsertCalls[1], equals(expectedListTry2));
      });

      test('should rethrow immediately without retrying on other PostgrestExceptions', () async {
        upsertHandler = (values) async {
          if (values is List) {
            upsertCalls.add(
              values.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
            );
          } else if (values is Map) {
            upsertCalls.add(Map<String, dynamic>.from(values));
          } else {
            upsertCalls.add(values);
          }
          throw const PostgrestException(
            message: 'Database connection timeout',
          );
        };

        await expectLater(
          supabaseService.upsertEntries(entries),
          throwsA(isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            'Database connection timeout',
          )),
        );

        expect(upsertCalls.length, equals(1));
        final expectedList = entries.map((e) => e.toMap()).toList();
        expect(upsertCalls[0], equals(expectedList));
      });
    });
  });
}
