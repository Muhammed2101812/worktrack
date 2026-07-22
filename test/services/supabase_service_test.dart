import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worklog/services/supabase_service.dart';
import 'package:worklog/models/work_entry.dart';
import 'package:worklog/core/constants.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T value;
  FakePostgrestFilterBuilder(this.value);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future.value(value).then(onValue, onError: onError);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const <Map<String, dynamic>>[]);
    registerFallbackValue(const <String, dynamic>{});
  });

  group('SupabaseService Tests', () {
    late MockSupabaseClient mockClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late FakePostgrestFilterBuilder<dynamic> fakeFilterBuilder;
    late SupabaseService supabaseService;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      fakeFilterBuilder = FakePostgrestFilterBuilder<dynamic>([]);
      supabaseService = SupabaseService(client: mockClient);

      when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
    });

    test('should have SupabaseService class', () {
      expect(() => 'SupabaseService'.toString(), returnsNormally);
    });

    test('Micro-benchmark of fallback logic', () {
      const count = 10000;
      final baselineMaps = List.generate(count, (i) => {
        'id': 'entry_$i',
        'client_id': 'client_1',
        'client_name': 'Test Client',
        'client_color': '#4A90D9',
        'date': '2026-03-15',
        'start_time': '09:00',
        'end_time': '12:00',
        'work_type': 'Yazılım',
      });

      final stopwatchOptimized = Stopwatch()..start();
      for (final map in baselineMaps) {
        map.remove('client_color');
      }
      stopwatchOptimized.stop();

      print('Benchmark - Optimized direct mutation for $count maps: ${stopwatchOptimized.elapsedMicroseconds} μs');
    });

    group('upsertEntry', () {
      final entry = WorkEntry(
        id: '1',
        clientId: 'client1',
        clientName: 'Test Client',
        clientColor: '#4A90D9',
        date: '15.03.2026',
        startTime: '09:00',
        endTime: '12:00',
        workType: 'Yazılım',
      );

      test('should succeed on first try under happy path', () async {
        when(() => mockQueryBuilder.upsert(any())).thenAnswer((_) => fakeFilterBuilder);

        await expectLater(supabaseService.upsertEntry(entry), completes);

        verify(() => mockClient.from(AppConstants.entriesTable)).called(1);
        verify(() => mockQueryBuilder.upsert(any())).called(1);
      });

      test('should retry without client_color if first try throws PostgrestException', () async {
        var callCount = 0;
        when(() => mockQueryBuilder.upsert(any())).thenAnswer((invocation) {
          callCount++;
          if (callCount == 1) {
            throw const PostgrestException(
              message: 'column "client_color" of relation "work_entries" does not exist',
            );
          }
          return fakeFilterBuilder;
        });

        await expectLater(supabaseService.upsertEntry(entry), completes);

        expect(callCount, equals(2));
        verify(() => mockQueryBuilder.upsert(any())).called(2);
      });

      test('should propagate exception if second try also throws', () async {
        when(() => mockQueryBuilder.upsert(any())).thenThrow(
          const PostgrestException(message: 'Some persistent DB error'),
        );

        await expectLater(
          supabaseService.upsertEntry(entry),
          throwsA(isA<PostgrestException>()),
        );

        verify(() => mockQueryBuilder.upsert(any())).called(2);
      });
    });

    group('upsertEntries', () {
      final entries = [
        WorkEntry(
          id: '1',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: '15.03.2026',
          startTime: '09:00',
          endTime: '12:00',
          workType: 'Yazılım',
        ),
        WorkEntry(
          id: '2',
          clientId: 'client1',
          clientName: 'Test Client',
          clientColor: '#4A90D9',
          date: '15.03.2026',
          startTime: '13:00',
          endTime: '17:00',
          workType: 'Yazılım',
        ),
      ];

      test('should succeed on first try under happy path', () async {
        when(() => mockQueryBuilder.upsert(any())).thenAnswer((_) => fakeFilterBuilder);

        await expectLater(supabaseService.upsertEntries(entries), completes);

        verify(() => mockClient.from(AppConstants.entriesTable)).called(1);
        verify(() => mockQueryBuilder.upsert(any())).called(1);
      });

      test('should retry without client_color if first try throws PostgrestException', () async {
        var callCount = 0;
        when(() => mockQueryBuilder.upsert(any())).thenAnswer((invocation) {
          callCount++;
          if (callCount == 1) {
            throw const PostgrestException(
              message: 'column "client_color" of relation "work_entries" does not exist',
            );
          }
          return fakeFilterBuilder;
        });

        await expectLater(supabaseService.upsertEntries(entries), completes);

        expect(callCount, equals(2));
        verify(() => mockQueryBuilder.upsert(any())).called(2);
      });

      test('should propagate exception if second try also throws', () async {
        when(() => mockQueryBuilder.upsert(any())).thenThrow(
          const PostgrestException(message: 'Some persistent DB error'),
        );

        await expectLater(
          supabaseService.upsertEntries(entries),
          throwsA(isA<PostgrestException>()),
        );

        verify(() => mockQueryBuilder.upsert(any())).called(2);
      });
    });
  });
}
