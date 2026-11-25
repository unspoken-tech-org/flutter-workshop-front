import '../../support/offline_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/edit_contact_modal_dialog.dart';
import 'package:provider/provider.dart';

DeviceCustomer _sampleDevice() => DeviceCustomer.fromJson(const {
  'deviceId': 1,
  'customerId': 1,
  'customerName': 'Cliente',
  'deviceStatus': 'EM_ANDAMENTO',
  'brandName': 'Marca',
  'modelName': 'Modelo',
  'typeName': 'Tipo',
  'technicianId': 2,
  'technicianName': 'Carlos',
  'problem': 'Não liga',
  'observation': '',
  'budget': null,
  'serviceValue': null,
  'budgetFee': null,
  'hasUrgency': false,
  'revision': false,
  'deviceColors': <String>[],
  'entryDate': '2026-01-01T00:00:00',
  'departureDate': null,
  'lastUpdate': null,
  'customerContacts': <dynamic>[],
  'customerPhones': <Map<String, dynamic>>[
    {'id': 1, 'number': '11999999999', 'main': true},
  ],
  'otherDevices': <dynamic>[],
  'payments': <dynamic>[],
});

void main() {
  testWidgets(
    'EditContactModalDialog opens with unknown type WHATSAPP, shows helper text, and requires selecting valid option',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = testDeviceCustomerPageController()
        ..deviceCustomer = _sampleDevice()
        ..technicians = [
          Technician(id: 2, name: 'Carlos', number: '11988888888'),
        ];

      final contact = CustomerContact(
        id: 10,
        deviceId: 1,
        technicianId: 2,
        technicianName: 'Carlos',
        phone: '11999999999',
        phoneNumber: '11999999999',
        type: 'WHATSAPP',
        hasMadeContact: true,
        lastContact: DateTime(2026, 2, 1),
        conversation: 'Cliente respondeu',
        deviceStatus: StatusEnum.inProgress,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: controller,
              child: EditContactModalDialog(contact: contact),
            ),
          ),
        ),
      );

      expect(find.byType(EditContactModalDialog), findsOneWidget);
      expect(
        find.text('Tipo atual: WHATSAPP — selecione uma opção'),
        findsOneWidget,
      );

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('Selecione um tipo de contato'), findsOneWidget);
    },
  );
}
