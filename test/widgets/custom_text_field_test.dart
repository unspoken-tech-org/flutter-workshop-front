import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CustomTextField sem controller externo', () {
    testWidgets('preserva o texto digitado após rebuild com o mesmo valor',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const CustomTextField(value: 'original', readOnly: false)),
      );
      await tester.enterText(find.byType(TextFormField), 'rascunho');

      // Rebuild do pai (ex.: alternar urgência) com o mesmo valor de origem.
      await tester.pumpWidget(
        _wrap(const CustomTextField(value: 'original', readOnly: false)),
      );

      expect(find.text('rascunho'), findsOneWidget);
    });

    testWidgets('atualiza o texto quando o valor de origem muda',
        (tester) async {
      await tester.pumpWidget(_wrap(const CustomTextField(value: 'a')));
      await tester.pumpWidget(_wrap(const CustomTextField(value: 'b')));

      expect(find.text('b'), findsOneWidget);
    });

    testWidgets('volta ao valor de origem quando sai do modo edição',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const CustomTextField(value: 'original', readOnly: false)),
      );
      await tester.enterText(find.byType(TextFormField), 'rascunho');

      await tester.pumpWidget(
        _wrap(const CustomTextField(value: 'original', readOnly: true)),
      );

      expect(find.text('original'), findsOneWidget);
    });
  });
}
