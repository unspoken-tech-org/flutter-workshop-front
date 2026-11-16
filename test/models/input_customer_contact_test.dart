import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

CustomerContact _contact({required bool hasMadeContact}) => CustomerContact(
      id: 1,
      deviceId: 10,
      technicianId: 2,
      technicianName: 'Tecnico',
      phone: null,
      phoneNumber: null,
      type: 'mensagem',
      hasMadeContact: hasMadeContact,
      lastContact: DateTime(2026, 1, 1),
      conversation: null,
      deviceStatus: StatusEnum.inProgress,
    );

void main() {
  group('InputCustomerContact — status do contato', () {
    test('realizado é enviado como true', () {
      final input = InputCustomerContact(
        deviceId: 1,
        contactStatus: ContactStatus.realizado.name,
      );

      expect(input.toJson()['contactStatus'], isTrue);
    });

    test('pendente é enviado como false', () {
      final input = InputCustomerContact(
        deviceId: 1,
        contactStatus: ContactStatus.pendente.name,
      );

      expect(input.toJson()['contactStatus'], isFalse);
    });

    test('edição preenche o status com um valor do enum', () {
      expect(
        InputCustomerContact.fromCustomerContact(_contact(hasMadeContact: true))
            .contactStatus,
        ContactStatus.realizado.name,
      );
      expect(
        InputCustomerContact.fromCustomerContact(_contact(hasMadeContact: false))
            .contactStatus,
        ContactStatus.pendente.name,
      );
    });

    test('ida e volta preserva hasMadeContact', () {
      final input =
          InputCustomerContact.fromCustomerContact(_contact(hasMadeContact: true));

      expect(input.toJson()['contactStatus'], isTrue);
    });
  });
}
