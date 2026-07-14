import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/screens/add_entry/widgets/client_dropdown.dart';
import 'package:worklog/models/client.dart';
import 'package:worklog/core/theme.dart';
import 'package:worklog/core/widgets/app_widgets.dart';

void main() {
  group('ClientDropdown Widget Tests', () {
    testWidgets('should display placeholder when no client selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
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

    testWidgets('should display selected client with AppAvatar initial',
        (WidgetTester tester) async {
      final client = Client(id: '1', name: 'Test Client', color: '#4A90D9');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
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
      // AppAvatar renders the first letter of the name as its initial.
      expect(find.byType(AppAvatar), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('should render trigger as AppCard',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
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

      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('should show bottom sheet with AppSheet title when tapped',
        (WidgetTester tester) async {
      final client = Client(id: '1', name: 'Test Client', color: '#4A90D9');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
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

      await tester.tap(find.byType(AppCard).first);
      await tester.pumpAndSettle();

      // AppSheet.decoration upper-cases the title argument (i -> I).
      expect(find.text('MÜŞTERI SEÇ'), findsOneWidget);
    });

    testWidgets('should display clients in bottom sheet', (WidgetTester tester) async {
      final clients = [
        Client(id: '1', name: 'Client A', color: '#4A90D9'),
        Client(id: '2', name: 'Client B', color: '#FF6B6B'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
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

      await tester.tap(find.byType(AppCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Client A'), findsOneWidget);
      expect(find.text('Client B'), findsOneWidget);
    });

    testWidgets('should display add client button as AppButton',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
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

      await tester.tap(find.byType(AppCard).first);
      await tester.pumpAndSettle();

      expect(find.text('YENİ MÜŞTERİ EKLE'), findsOneWidget);
      // The add-client CTA is an AppButton.
      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
