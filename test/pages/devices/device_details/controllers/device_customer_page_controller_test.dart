import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

import '../../../../support/fakes/fake_catalog_repository.dart';
import '../../../../support/fakes/fake_device_repository.dart';
import '../../../../support/fixtures/device_customer_fixture.dart';
import '../../../../support/offline_services.dart';
import '../../../../support/ui_message_recorder.dart';

const _rejected = Err<DeviceCustomer>(
  ValidationFailure(message: 'Recusado', code: '1', statusCode: 422),
);

void main() {
  group('DeviceCustomerPageController — carga', () {
    test('init carrega o aparelho e não publica mensagem', () async {
      final device = makeDeviceCustomer();
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onGetCustomerDeviceById: (_) async => Ok(device),
        ),
        catalogRepository: FakeCatalogRepository(),
      );
      final messages = recordMessages(controller);

      await controller.init(1);

      expect(controller.deviceCustomer, same(device));
      expect(controller.loadError, isNull);
      expect(controller.isLoading, isFalse);
      expect(controller.load.result, isA<Ok<void>>());
      expect(messages, isEmpty);
    });

    test('init com falha guarda loadError e publica o erro', () async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onGetCustomerDeviceById: (_) async => _rejected,
        ),
      );
      final messages = recordMessages(controller);

      await controller.init(1);

      expect(controller.deviceCustomer, isNull);
      expect(controller.loadError, 'Recusado');
      expect(messages, contains(isUiError('Recusado')));
    });
  });

  group('DeviceCustomerPageController — ações rápidas', () {
    test('urgência: aplica a resposta e publica sucesso', () async {
      final updated = makeDeviceCustomer(hasUrgency: true);
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceHasUrgency: (_, __) async => Ok(updated),
        ),
      )..deviceCustomer = makeDeviceCustomer();
      final messages = recordMessages(controller);

      await controller.updateDeviceHasUrgency(true);

      expect(controller.deviceCustomer, same(updated));
      expect(controller.setUrgency.running, isFalse);
      expect(messages, [
        isUiSuccess('Urgencia do dispositivo atualizada com sucesso'),
      ]);
    });

    test('revisão: falha não altera o aparelho e publica o erro', () async {
      final original = makeDeviceCustomer();
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceRevision: (_, __) async => _rejected,
        ),
      )..deviceCustomer = original;
      final messages = recordMessages(controller);

      await controller.updateDeviceRevision(true);

      expect(controller.deviceCustomer, same(original));
      expect(controller.setRevision.error, isA<ValidationFailure>());
      expect(messages, [isUiError('Recusado')]);
    });

    test('status: cada ação tem a sua flag', () async {
      final blocker = Completer<Result<DeviceCustomer>>();
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceStatus: (_, __) => blocker.future,
        ),
      )..deviceCustomer = makeDeviceCustomer();

      final pending = controller.updateDeviceStatus(StatusEnum.ready);

      expect(controller.setStatus.running, isTrue);
      expect(controller.setUrgency.running, isFalse);
      expect(controller.setRevision.running, isFalse);
      expect(controller.save.running, isFalse);
      expect(controller.isUpdating, isTrue);

      blocker.complete(Ok(makeDeviceCustomer()));
      await pending;
      expect(controller.isUpdating, isFalse);
    });
  });

  group('DeviceCustomerPageController — salvar, contatos e pagamento', () {
    test('salvar: sucesso limpa o snapshot e publica sucesso', () async {
      final saved = makeDeviceCustomer(problem: 'Tela');
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceCustomer: (_) async => Ok(saved),
        ),
      )..deviceCustomer = makeDeviceCustomer();
      controller.onEditingStarted();
      final messages = recordMessages(controller);

      expect(await controller.updateDeviceCustomer(), isTrue);

      expect(controller.persistedDeviceCustomer, same(saved));
      expect(messages, [isUiSuccess('Dispositivo atualizado com sucesso')]);
    });

    test('salvar: falha devolve false e publica a mensagem da API', () async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceCustomer: (_) async => _rejected,
        ),
      )..deviceCustomer = makeDeviceCustomer();
      final messages = recordMessages(controller);

      expect(await controller.updateDeviceCustomer(), isFalse);

      expect(controller.save.error, isA<ValidationFailure>());
      expect(messages, [isUiError('Recusado')]);
    });

    test('criar contato: recarrega o aparelho e publica sucesso', () async {
      var reloads = 0;
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onCreateCustomerContact: (_) async => const Ok<void>(null),
          onGetCustomerDeviceById: (_) async {
            reloads++;
            return Ok(makeDeviceCustomer());
          },
        ),
      )..deviceCustomer = makeDeviceCustomer();
      final messages = recordMessages(controller);

      expect(
        await controller.createCustomerContact(InputCustomerContact.empty(1)),
        isTrue,
      );

      expect(reloads, 1);
      expect(messages, [isUiSuccess('Contato criado com sucesso')]);
    });

    test('editar contato: falha publica o texto padrão', () async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateCustomerContact: (_, __) async => const Err(NetworkFailure()),
        ),
      )..deviceCustomer = makeDeviceCustomer();
      final messages = recordMessages(controller);

      expect(
        await controller.updateCustomerContact(
          3,
          InputCustomerContact.empty(1),
        ),
        isFalse,
      );

      expect(controller.isEditingContact, isFalse);
      expect(messages, [isUiError('Erro ao editar contato. Tente novamente.')]);
    });

    test('pagamento: sucesso acrescenta à lista e publica sucesso', () async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onCreatePayment: (_) async => const Ok<void>(null),
        ),
      )..deviceCustomer = makeDeviceCustomer();
      final messages = recordMessages(controller);

      final created = await controller.createCustomerDevicePayment(
        InputPayment(
          deviceId: 1,
          value: Money.zero,
          paymentType: PaymentType.values.first,
          category: PaymentCategory.values.first,
          paymentDate: DateTime(2026, 1, 1),
        ),
      );

      expect(created, isTrue);
      expect(controller.deviceCustomer!.payments, hasLength(1));
      expect(controller.isCreatingPayment, isFalse);
      expect(messages, [isUiSuccess('Pagamento criado com sucesso')]);
    });
  });
}
