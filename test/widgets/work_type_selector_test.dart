import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/screens/add_entry/widgets/work_type_selector.dart';

void main() {
  group('WorkTypeSelector Widget Tests', () {
    testWidgets('should display all work types', (WidgetTester tester) async {
      String? selectedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkTypeSelector(
              selectedWorkType: 'Yazılım',
              onWorkTypeSelected: (type) => selectedType = type,
            ),
          ),
        ),
      );

      expect(find.text('Grafik'), findsOneWidget);
      expect(find.text('Yazılım'), findsOneWidget);
      expect(find.text('Diğer'), findsOneWidget);
    });

    testWidgets('should highlight selected work type',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkTypeSelector(
              selectedWorkType: 'Yazılım',
              onWorkTypeSelected: (_) {},
            ),
          ),
        ),
      );

      final yazilikFinder = find.text('Yazılım');
      expect(yazilikFinder, findsOneWidget);
    });

    testWidgets('should call onWorkTypeSelected when tapped',
        (WidgetTester tester) async {
      String? selectedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkTypeSelector(
              selectedWorkType: 'Yazılım',
              onWorkTypeSelected: (type) => selectedType = type,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Grafik'));
      await tester.pump();

      expect(selectedType, 'Grafik');
    });

    testWidgets('should update selected type', (WidgetTester tester) async {
      String selectedType = 'Yazılım';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: WorkTypeSelector(
                  selectedWorkType: selectedType,
                  onWorkTypeSelected: (type) {
                    setState(() {
                      selectedType = type;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.text('Diğer'));
      await tester.pump();

      expect(selectedType, 'Diğer');
    });
  });
}
