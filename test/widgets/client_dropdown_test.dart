import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/screens/add_entry/widgets/client_dropdown.dart';
import 'package:worklog/models/client.dart';

void main() {
  group('ClientDropdown Widget Tests', () {
    testWidgets('should display placeholder when no client selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientDropdown(
              clients: const [],
              selectedClient: null,
              onClientSelected: (_) {},
              onAddClient: () {},
            ),
          ),
        ),
      );

      expect(find.text('Müşteri Seç'), findsOneWidget);
    });

    testWidgets('should display selected client', (WidgetTester tester) async {
      final client = Client(id: '1', name: 'Test Client', color: '#4A90D9');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientDropdown(
              clients: [client],
              selectedClient: client,
              onClientSelected: (_) {},
              onAddClient: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Client'), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('should show bottom sheet when tapped',
        (WidgetTester tester) async {
      final client = Client(id: '1', name: 'Test Client', color: '#4A90D9');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientDropdown(
              clients: [client],
              selectedClient: client,
              onClientSelected: (_) {},
              onAddClient: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.text('MÜŞTERİ SEÇİN'), findsOneWidget);
    });

    testWidgets('should display clients in bottom sheet',
        (WidgetTester tester) async {
      final clients = [
        Client(id: '1', name: 'Client A', color: '#4A90D9'),
        Client(id: '2', name: 'Client B', color: '#FF6B6B'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientDropdown(
              clients: clients,
              selectedClient: null,
              onClientSelected: (_) {},
              onAddClient: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.text('Client A'), findsOneWidget);
      expect(find.text('Client B'), findsOneWidget);
    });

    testWidgets('should display add client button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientDropdown(
              clients: const [],
              selectedClient: null,
              onClientSelected: (_) {},
              onAddClient: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.text('YENİ MÜŞTERİ EKLE'), findsOneWidget);
    });
  });
}
