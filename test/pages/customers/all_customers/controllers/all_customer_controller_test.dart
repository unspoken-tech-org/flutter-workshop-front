import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/controllers/all_customer_controller.dart';

import '../../../../support/fakes/fake_customer_repository.dart';
import '../../../../support/fixtures/customer_fixture.dart';
import '../../../../support/fixtures/page_fixture.dart';
import '../../../../support/ui_message_recorder.dart';

void main() {
  group('AllCustomerController', () {
    test('carrega a primeira página sem publicar mensagem', () async {
      final controller = AllCustomerController(
        customerRepository: FakeCustomerRepository(
          searchCustomersResult: Ok(makePage([makeMinifiedCustomer()])),
        ),
      );
      final messages = recordMessages(controller);

      await Future<void>.delayed(Duration.zero);

      expect(controller.customers, hasLength(1));
      expect(messages, isEmpty);
    });

    test('falha na primeira página publica a mensagem fixa', () async {
      final controller = AllCustomerController(
        customerRepository: FakeCustomerRepository(
          searchCustomersResult: const Err(
            ValidationFailure(message: 'ignorada', code: '1', statusCode: 422),
          ),
        ),
      );
      final messages = recordMessages(controller);

      await Future<void>.delayed(Duration.zero);

      expect(messages, [
        isUiError('Erro ao buscar clientes. Tente novamente.'),
      ]);
      expect(controller.customers, isEmpty);
    });
  });
}
