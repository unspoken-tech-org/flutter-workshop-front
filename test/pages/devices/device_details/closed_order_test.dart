import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/create_device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_contacts_list_widget.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_info_header_widget.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/open_revision_dialog.dart';
import 'package:flutter_workshop_front/widgets/customer_device/revision_chip.dart';
import 'package:flutter_workshop_front/widgets/customer_device/urgency_chip.dart';
import 'package:provider/provider.dart';

import '../../../support/fakes/fake_device_repository.dart';
import '../../../support/fixtures/device_customer_fixture.dart';
import '../../../support/offline_services.dart';
import '../../../support/ui_message_recorder.dart';
import '../../../support/widget_test_harness.dart';

const _closedStatuses = [StatusEnum.delivered, StatusEnum.disposed];

void main() {
  group('OS encerrada — ViewModel', () {
    test('StatusEnum.isClosed vale só para ENTREGUE e DESCARTADO', () {
      for (final status in StatusEnum.values) {
        expect(
          status.isClosed,
          _closedStatuses.contains(status),
          reason: status.name,
        );
      }
    });

    test('StatusEnum.allowsRevision vale só para ENTREGUE', () {
      for (final status in StatusEnum.values) {
        expect(
          status.allowsRevision,
          status == StatusEnum.delivered,
          reason: status.name,
        );
      }
    });

    test('urgência não chama a API e publica o motivo', () async {
      var calls = 0;
      final controller =
          testDeviceCustomerPageController(
              deviceRepository: FakeDeviceRepository(
                onUpdateDeviceHasUrgency: (_, __) async {
                  calls++;
                  return Ok(makeDeviceCustomer());
                },
              ),
            )
            ..deviceCustomer = makeDeviceCustomer(
              deviceStatus: StatusEnum.delivered,
            );
      final messages = recordMessages(controller);

      await controller.updateDeviceHasUrgency(true);

      expect(calls, 0);
      expect(messages, [
        isUiError(
          DeviceCustomerPageController.closedOrderMessage +
              DeviceCustomerPageController.closedOrderRevisionHint,
        ),
      ]);
    });

    test('OS descartada bloqueia sem sugerir revisão', () async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(),
      )..deviceCustomer = makeDeviceCustomer(deviceStatus: StatusEnum.disposed);
      final messages = recordMessages(controller);

      await controller.updateDeviceHasUrgency(true);

      expect(messages, [
        isUiError(DeviceCustomerPageController.closedOrderMessage),
      ]);
    });

    test('criar e editar contato não chamam a API', () async {
      var calls = 0;
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onCreateCustomerContact: (_) async {
            calls++;
            return const Ok<void>(null);
          },
          onUpdateCustomerContact: (_, __) async {
            calls++;
            return const Ok<void>(null);
          },
        ),
      )..deviceCustomer = makeDeviceCustomer(deviceStatus: StatusEnum.disposed);

      final input = InputCustomerContact(deviceId: 1);
      expect(await controller.createCustomerContact(input), isFalse);
      expect(await controller.updateCustomerContact(5, input), isFalse);
      expect(calls, 0);
    });

    test('OS aberta continua aceitando urgência', () async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceHasUrgency: (_, __) async =>
              Ok(makeDeviceCustomer(hasUrgency: true)),
        ),
      )..deviceCustomer = makeDeviceCustomer();

      await controller.updateDeviceHasUrgency(true);

      expect(controller.deviceCustomer!.hasUrgency, isTrue);
    });

    test(
      'abrir revisão cria a OS nova com a origem (técnico incluso) e marca a revisão',
      () async {
        final inputs = <DeviceInput>[];
        final revisionCalls = <(int, bool)>[];
        final controller =
            testDeviceCustomerPageController(
                deviceRepository: FakeDeviceRepository(
                  onCreateDeviceCustomer: (input) async {
                    inputs.add(input);
                    return Ok(CreateDeviceCustomerResponse(deviceId: 77));
                  },
                  onUpdateDeviceRevision: (id, revision) async {
                    revisionCalls.add((id, revision));
                    return Ok(
                      makeDeviceCustomer(deviceId: id, revision: revision),
                    );
                  },
                ),
              )
              ..deviceCustomer = makeDeviceCustomer(
                deviceId: 10,
                customerId: 3,
                deviceStatus: StatusEnum.delivered,
                problem: 'Não liga',
                deviceColors: const ['Preto', 'Prata'],
                technicianId: 4,
                technicianName: 'Joana',
              );
        final messages = recordMessages(controller);

        final newId = await controller.openRevisionOrder();

        expect(newId, 77);
        expect(inputs.single.toJson(), {
          'customerId': 3,
          'problem': 'Não liga',
          'observation': null,
          'budgetFee': null,
          'hasUrgency': false,
          'technicianId': 4,
          'typeBrandModel': {
            'type': 'Notebook',
            'brand': 'Dell',
            'model': 'Inspiron',
          },
          'colors': ['Preto', 'Prata'],
          'originOrderId': 10,
          'revision': true,
        });
        expect(revisionCalls, [(77, true)]);
        // A OS de origem não muda.
        expect(controller.deviceCustomer!.deviceId, 10);
        expect(controller.deviceCustomer!.deviceStatus, StatusEnum.delivered);
        expect(messages, [isUiSuccess('Revisão aberta em uma nova OS')]);
      },
    );

    test('falha na criação publica o erro e não marca revisão', () async {
      var revisionCalls = 0;
      final controller =
          testDeviceCustomerPageController(
              deviceRepository: FakeDeviceRepository(
                onCreateDeviceCustomer: (_) async => const Err(
                  ValidationFailure(
                    message: 'Recusado',
                    code: '1',
                    statusCode: 422,
                  ),
                ),
                onUpdateDeviceRevision: (_, __) async {
                  revisionCalls++;
                  return Ok(makeDeviceCustomer());
                },
              ),
            )
            ..deviceCustomer = makeDeviceCustomer(
              deviceStatus: StatusEnum.delivered,
            );
      final messages = recordMessages(controller);

      expect(await controller.openRevisionOrder(), isNull);
      expect(revisionCalls, 0);
      expect(messages, [isUiError('Recusado')]);
    });

    test('OS descartada não abre revisão (status final)', () async {
      var creates = 0;
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onCreateDeviceCustomer: (_) async {
            creates++;
            return Ok(CreateDeviceCustomerResponse(deviceId: 1));
          },
        ),
      )..deviceCustomer = makeDeviceCustomer(deviceStatus: StatusEnum.disposed);

      expect(await controller.openRevisionOrder(), isNull);
      expect(creates, 0);
    });

    test('OS aberta não abre revisão por este caminho', () async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(),
      )..deviceCustomer = makeDeviceCustomer();

      expect(await controller.openRevisionOrder(), isNull);
    });
  });

  group('OS encerrada — widgets', () {
    Future<DeviceCustomerPageController> pumpHeader(
      WidgetTester tester,
      DeviceCustomer device,
    ) async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(),
      )..deviceCustomer = device;
      addTearDown(controller.dispose);
      await pumpAppWidget(
        tester,
        ChangeNotifierProvider<DeviceCustomerPageController>.value(
          value: controller,
          child: const Scaffold(body: CustomerDeviceInfoHeaderWidget()),
        ),
      );
      return controller;
    }

    for (final status in _closedStatuses) {
      final revisable = status == StatusEnum.delivered;
      testWidgets('cabeçalho ${status.name}: urgência desabilitada e '
          '${revisable ? '"Abrir revisão"' : 'sem revisão'}', (tester) async {
        await pumpHeader(tester, makeDeviceCustomer(deviceStatus: status));

        final urgency = tester.widget<UrgencyChip>(find.byType(UrgencyChip));
        expect(urgency.onTap, isNull);
        expect(urgency.disabledTooltip, isNotNull);
        expect(
          find.text('Abrir revisão'),
          revisable ? findsOneWidget : findsNothing,
        );
        expect(find.byType(RevisionChip), findsNothing);
      });
    }

    testWidgets('cabeçalho de OS aberta mantém urgência e chip de revisão', (
      tester,
    ) async {
      await pumpHeader(tester, makeDeviceCustomer());

      final urgency = tester.widget<UrgencyChip>(find.byType(UrgencyChip));
      expect(urgency.onTap, isNotNull);
      expect(find.byType(RevisionChip), findsOneWidget);
      expect(find.text('Abrir revisão'), findsNothing);
    });

    testWidgets('"Abrir revisão" pede confirmação e cancelar não cria nada', (
      tester,
    ) async {
      var creates = 0;
      final controller =
          testDeviceCustomerPageController(
              deviceRepository: FakeDeviceRepository(
                onCreateDeviceCustomer: (_) async {
                  creates++;
                  return Ok(CreateDeviceCustomerResponse(deviceId: 2));
                },
              ),
            )
            ..deviceCustomer = makeDeviceCustomer(
              deviceStatus: StatusEnum.delivered,
            );
      addTearDown(controller.dispose);
      await pumpAppWidget(
        tester,
        ChangeNotifierProvider<DeviceCustomerPageController>.value(
          value: controller,
          child: const Scaffold(body: CustomerDeviceInfoHeaderWidget()),
        ),
      );

      await tester.tap(find.text('Abrir revisão'));
      await tester.pumpAndSettle();
      expect(find.byType(OpenRevisionDialog), findsOneWidget);
      expect(find.textContaining('Maria Silva'), findsWidgets);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(creates, 0);
    });

    for (final closed in [true, false]) {
      testWidgets('contatos ${closed ? 'desabilitados' : 'habilitados'} '
          'com OS ${closed ? 'encerrada' : 'aberta'}', (tester) async {
        final controller =
            testDeviceCustomerPageController(
                deviceRepository: FakeDeviceRepository(),
              )
              ..deviceCustomer = makeDeviceCustomer(
                deviceStatus: closed ? StatusEnum.delivered : StatusEnum.ready,
              );
        addTearDown(controller.dispose);
        await pumpAppWidget(
          tester,
          ChangeNotifierProvider<DeviceCustomerPageController>.value(
            value: controller,
            child: Scaffold(
              body: CustomerContactsListWidget(
                customerContacts: const [],
                scrollController: ScrollController(),
              ),
            ),
          ),
        );

        final button = tester.widget<TextButton>(find.byType(TextButton));
        expect(button.onPressed, closed ? isNull : isNotNull);
      });
    }
  });
}
