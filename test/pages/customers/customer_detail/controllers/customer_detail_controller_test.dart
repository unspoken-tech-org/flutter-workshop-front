import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';

import '../../../../support/fakes/fake_customer_repository.dart';
import '../../../../support/fixtures/customer_fixture.dart';
import '../../../../support/ui_message_recorder.dart';

void main() {
  group('CustomerDetailController', () {
    test('fetchCustomer guarda o cliente sem publicar mensagem', () async {
      final customer = makeCustomerModel(name: 'Ana');
      final controller = CustomerDetailController(
        FakeCustomerRepository(getCustomerResult: Ok(customer)),
      );
      final messages = recordMessages(controller);

      await controller.fetchCustomer(1);

      expect(controller.customer, same(customer));
      expect(controller.errorMessage, isNull);
      expect(controller.fetch.running, isFalse);
      expect(messages, isEmpty);
    });

    test('fetchCustomer com falha guarda e publica o erro', () async {
      final controller = CustomerDetailController(
        FakeCustomerRepository(getCustomerResult: const Err(NetworkFailure())),
      );
      final messages = recordMessages(controller);

      await controller.fetchCustomer(1);

      expect(controller.customer, isNull);
      expect(
        controller.errorMessage,
        'Erro ao buscar cliente. Tente novamente.',
      );
      expect(messages, [isUiError('Erro ao buscar cliente. Tente novamente.')]);
    });

    test(
      'updateCustomer com sucesso sai da edição e publica sucesso',
      () async {
        final updated = makeCustomerModel(name: 'Ana Maria');
        final controller = CustomerDetailController(
          FakeCustomerRepository(updateCustomerResult: Ok(updated)),
        )..setEditing(true);
        final messages = recordMessages(controller);

        expect(await controller.updateCustomer(1), isTrue);

        expect(controller.customer, same(updated));
        expect(controller.isEditing, isFalse);
        expect(controller.update.running, isFalse);
        expect(messages, [isUiSuccess('Cliente atualizado com sucesso')]);
      },
    );

    test('updateCustomer com falha mantém a edição e publica o erro', () async {
      final controller = CustomerDetailController(
        FakeCustomerRepository(
          updateCustomerResult: const Err(NetworkFailure()),
        ),
      )..setEditing(true);
      final messages = recordMessages(controller);

      expect(await controller.updateCustomer(1), isFalse);

      expect(controller.isEditing, isTrue);
      expect(controller.update.error, isA<NetworkFailure>());
      expect(messages, [
        isUiError('Erro ao atualizar cliente. Tente novamente.'),
      ]);
    });
  });
}
