import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/widgets/form_fields/searchable_dropdown_form_field.dart';

Future<List<String>> _accepted(
  WidgetTester tester, {
  required bool clearOnAccept,
}) async {
  final accepted = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 300,
            height: 80,
            child: SearchableDropdownFormField<String>(
              searchFn: (query) async => [
                'britania',
                'brastemp',
              ].where((e) => e.contains(query.toLowerCase())).toList(),
              getName: (item) => item,
              getId: (item) => item.hashCode,
              onAccept: accepted.add,
              clearOnAccept: clearOnAccept,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.enterText(find.byType(TextFormField), 'brit');
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Britania'));
  await tester.pumpAndSettle();
  return accepted;
}

String _fieldText(WidgetTester tester) =>
    tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text;

void main() {
  testWidgets('padrão: mantém o nome escolhido e o botão de limpar', (
    tester,
  ) async {
    final accepted = await _accepted(tester, clearOnAccept: false);

    expect(accepted, ['britania']);
    expect(_fieldText(tester), 'Britania');
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('clearOnAccept: aceita o item e volta o campo para a busca', (
    tester,
  ) async {
    final accepted = await _accepted(tester, clearOnAccept: true);

    expect(accepted, ['britania']);
    expect(_fieldText(tester), isEmpty);
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
