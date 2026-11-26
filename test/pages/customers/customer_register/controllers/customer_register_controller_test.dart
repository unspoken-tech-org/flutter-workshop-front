import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/controllers/customer_register_controller.dart';

import '../../../../support/fakes/fake_customer_repository.dart';
import '../../../../support/fixtures/customer_fixture.dart';
import '../../../../support/ui_message_recorder.dart';

void main() {
  group('CustomerRegisterController', () {
    test('sucesso devolve o id, publica a mensagem e solta a flag', () async {
      final controller = CustomerRegisterController(
        FakeCustomerRepository(
          createCustomerResult: Ok(makeCustomerModel(customerId: 9)),
        ),
      );
      final messages = recordMessages(controller);

      final id = await controller.createCustomer(InputCustomer.empty());

      expect(id, 9);
      expect(messages, [isUiSuccess('Cliente cadastrado com sucesso')]);
      expect(controller.isCreatingCustomer, isFalse);
      expect(controller.create.result, isA<Ok<CustomerModel>>());
    });

    test('falha usa a mensagem da API e devolve null', () async {
      final controller = CustomerRegisterController(
        FakeCustomerRepository(
          createCustomerResult: const Err(
            ValidationFailure(
              message: 'CPF já existe',
              code: '1',
              statusCode: 422,
            ),
          ),
        ),
      );
      final messages = recordMessages(controller);

      expect(await controller.createCustomer(InputCustomer.empty()), isNull);

      expect(messages, [isUiError('CPF já existe')]);
      expect(controller.create.error, isA<ValidationFailure>());
    });

    test('falha sem mensagem usa o texto padrão', () async {
      final controller = CustomerRegisterController(
        FakeCustomerRepository(
          createCustomerResult: const Err(NetworkFailure()),
        ),
      );
      final messages = recordMessages(controller);

      await controller.createCustomer(InputCustomer.empty());

      expect(messages, [isUiError('Erro ao cadastrar cliente')]);
    });

    test('flag acompanha a chamada em andamento', () async {
      final blocker = Completer<Result<CustomerModel>>();
      final controller = CustomerRegisterController(
        FakeCustomerRepository(onCreateCustomer: (_) => blocker.future),
      );

      final pending = controller.createCustomer(InputCustomer.empty());
      expect(controller.isCreatingCustomer, isTrue);

      blocker.complete(Ok(makeCustomerModel()));
      await pending;
      expect(controller.isCreatingCustomer, isFalse);
    });
  });
}
