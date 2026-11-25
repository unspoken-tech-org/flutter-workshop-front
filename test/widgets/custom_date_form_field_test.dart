import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_date_form_field.dart';

void main() {
  final now = DateTime(2026, 11, 24, 15, 30);

  group('DateFieldSelection.parse', () {
    test('reads single dates and ranges written by the field', () {
      expect(DateFieldSelection.parse('05/03/2025'), [DateTime(2025, 3, 5)]);
      expect(DateFieldSelection.parse('01/11/2026 - 10/11/2026'), [
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 10),
      ]);
    });

    test('returns nothing for empty or invalid text', () {
      expect(DateFieldSelection.parse(''), isEmpty);
      expect(DateFieldSelection.parse('abc'), isEmpty);
      expect(DateFieldSelection.parse('31/02/2026'), isEmpty);
    });
  });

  group('DateFieldSelection.initialDate', () {
    DateTime initial(String text, {DateTime? lastDate}) =>
        DateFieldSelection.initialDate(
          text: text,
          now: now,
          firstDate: DateTime(2000),
          lastDate: lastDate ?? now,
        );

    test('opens on the selected date', () {
      expect(initial('05/03/2025'), DateTime(2025, 3, 5));
    });

    test('opens on today when nothing is selected', () {
      expect(initial(''), now);
    });

    test('clamps to the allowed bounds', () {
      expect(initial('05/03/1990'), DateTime(2000));
      expect(initial('05/03/2030'), now);
      expect(
        initial('05/03/2030', lastDate: DateTime(2100)),
        DateTime(2030, 3, 5),
      );
    });
  });

  group('DateFieldSelection.range', () {
    test('keeps both picked dates, in order', () {
      expect(
        DateFieldSelection.range([
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 1),
        ], now),
        (DateTime(2026, 11, 1), DateTime(2026, 11, 10)),
      );
    });

    test('a single past date runs until now', () {
      expect(DateFieldSelection.range([DateTime(2026, 11, 1)], now), (
        DateTime(2026, 11, 1),
        now,
      ));
    });

    test('a single future date never ends before it starts', () {
      final (start, end) = DateFieldSelection.range([
        DateTime(2026, 12, 5),
      ], now);
      expect(start, DateTime(2026, 12, 5));
      expect(end, DateTime(2026, 12, 5));
    });
  });

  testWidgets('X clears the field and turns into an inert calendar icon', (
    tester,
  ) async {
    var cleared = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomDateFormField(
            value: '05/03/2025',
            onClear: () => cleared++,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(find.text('05/03/2025'), findsNothing);
    expect(cleared, 1);
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });
}
