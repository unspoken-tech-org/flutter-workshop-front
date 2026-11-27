import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/open_revision_dialog.dart';

import '../../../../support/fixtures/device_customer_fixture.dart';

void main() {
  final origin = makeDeviceCustomer(
    deviceId: 9,
    deviceStatus: StatusEnum.delivered,
    problem: 'Tela com manchas',
    deviceColors: const ['Cinza Grafite'],
    technicianId: 4,
    technicianName: 'joana reparos',
  );

  Future<Future<int?>> open(
    WidgetTester tester, {
    required DeviceCustomer origin,
    required Future<int?> Function() onConfirm,
  }) async {
    late Future<int?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => result = OpenRevisionDialog.show(
                context,
                origin: origin,
                onConfirm: onConfirm,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return result;
  }

  Finder bySemantics(String id) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.identifier == id,
  );

  testWidgets('mostra o resumo da origem com técnico copiado', (tester) async {
    await open(tester, origin: origin, onConfirm: () async => null);

    expect(find.text('Abrir revisão'), findsNWidgets(2));
    expect(find.textContaining('A partir da OS #9'), findsOneWidget);
    expect(find.text('Cinza Grafite'), findsOneWidget);
    expect(find.text('Joana Reparos'), findsOneWidget);
    expect(find.textContaining('Copiado da OS #9'), findsOneWidget);
    expect(find.text('Tela com manchas'), findsOneWidget);
    expect(find.textContaining('A OS #9 continua encerrada'), findsOneWidget);
  });

  testWidgets('sem técnico e sem cor mostra "Não informado"', (tester) async {
    await open(
      tester,
      origin: makeDeviceCustomer(
        deviceStatus: StatusEnum.delivered,
        deviceColors: const [],
      ),
      onConfirm: () async => null,
    );

    expect(find.text('Não informado'), findsNWidgets(2));
  });

  testWidgets(
    'enquanto abre, desabilita ações e ignora segundo clique; fecha com o id',
    (tester) async {
      final completer = Completer<int?>();
      var calls = 0;
      final result = await open(
        tester,
        origin: origin,
        onConfirm: () {
          calls++;
          return completer.future;
        },
      );

      await tester.tap(
        find.descendant(
          of: bySemantics('deviceDetail.openRevision.confirm'),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pump();

      expect(find.text('Abrindo…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final cancel = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(cancel.onPressed, isNull);
      final confirm = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(confirm.onPressed, isNull);

      // Voltar (Esc/barreira) não fecha durante a criação.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(OpenRevisionDialog), findsOneWidget);

      completer.complete(51);
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.byType(OpenRevisionDialog), findsNothing);
      expect(await result, 51);
    },
  );

  testWidgets('erro mantém o diálogo aberto para tentar de novo', (
    tester,
  ) async {
    await open(tester, origin: origin, onConfirm: () async => null);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(OpenRevisionDialog), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('cancelar fecha sem criar', (tester) async {
    var calls = 0;
    final result = await open(
      tester,
      origin: origin,
      onConfirm: () async {
        calls++;
        return 1;
      },
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(await result, isNull);
  });

  testWidgets('cabe em 360px sem overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await open(
      tester,
      origin: makeDeviceCustomer(
        deviceStatus: StatusEnum.delivered,
        customerName: 'Pedro Henrique Albuquerque Montenegro Filho',
        problem: 'Não liga na bateria, só na tomada. ' * 10,
        deviceColors: const ['Preto', 'Prata', 'Azul Marinho'],
        technicianName: 'Carlos Técnico',
      ),
      onConfirm: () async => null,
    );

    expect(tester.takeException(), isNull);
  });
}
