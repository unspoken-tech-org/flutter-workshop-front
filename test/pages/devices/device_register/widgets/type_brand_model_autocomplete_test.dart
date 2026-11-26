import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/type_brand_model_autocomplete_form_field.dart';

import '../../../../support/widget_test_harness.dart';

void main() {
  group('findByNameKey', () {
    final types = [Type(idType: 1, type: 'Micro-ondas')];

    test('casa por name_key, ignorando caixa, acento e pontuação', () {
      for (final query in ['microondas', '  MICRO ONDAS ', 'Micro-Ondas']) {
        expect(
          findByNameKey(types, query, (t) => t.type)?.idType,
          1,
          reason: query,
        );
      }
    });

    test('não casa nomes diferentes nem consulta sem alfanumérico', () {
      expect(findByNameKey(types, 'micro', (t) => t.type), isNull);
      expect(findByNameKey(types, '--', (t) => t.type), isNull);
    });
  });

  group('TypeBrandModelAutocompleteFormField', () {
    Future<(List<Type>, List<String>)> pumpField(
      WidgetTester tester, {
      required List<Type> existing,
    }) async {
      final accepted = <Type>[];
      final created = <String>[];
      await pumpAppWidget(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              height: 80,
              child: TypeBrandModelAutocompleteFormField<Type>(
                semanticsIdentifier: 'test.type',
                searchFn: (_) async => existing,
                createFn: (name) async {
                  created.add(name);
                  return Type(idType: 99, type: name);
                },
                getName: (t) => t.type,
                getId: (t) => t.idType,
                onAccept: accepted.add,
              ),
            ),
          ),
        ),
      );
      return (accepted, created);
    }

    testWidgets(
      'nome que difere só na grafia seleciona o existente e não cria',
      (tester) async {
        final (accepted, created) = await pumpField(
          tester,
          existing: [Type(idType: 1, type: 'Micro-ondas')],
        );

        await tester.enterText(find.byType(TextFormField), 'microondas');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        await tester.pump();

        // O existente aparece na lista e a opção "Criar novo" some.
        expect(find.textContaining('Micro'), findsOneWidget);
        expect(find.textContaining('Criar novo'), findsNothing);

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(created, isEmpty);
        expect(accepted.map((t) => t.idType), [1]);
      },
    );

    testWidgets('nome novo continua oferecendo e chamando a criação', (
      tester,
    ) async {
      final (accepted, created) = await pumpField(
        tester,
        existing: [Type(idType: 1, type: 'Micro-ondas')],
      );

      await tester.enterText(find.byType(TextFormField), 'Geladeira');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Criar novo'), findsOneWidget);
      await tester.tap(find.textContaining('Criar novo'));
      await tester.pump();
      await tester.pump();

      expect(created, ['Geladeira']);
      expect(accepted.single.idType, 99);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
