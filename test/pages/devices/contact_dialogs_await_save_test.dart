import '../../support/offline_services.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/add_contact_modal_dialog.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/edit_contact_modal_dialog.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/core/result/result.dart';

import '../../support/result_guard.dart';

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

class _StubDeviceRepository extends Fake implements DeviceRepository {
  Future<void> Function(InputCustomerContact)? onCreate;
  Future<void> Function(int, InputCustomerContact)? onUpdate;

  _StubDeviceRepository({this.onCreate, this.onUpdate});

  @override
  Future<Result<DeviceCustomer>> getCustomerDeviceById(int deviceId) async =>
      Ok(_sampleDevice());

  @override
  Future<Result<void>> createCustomerContact(
    InputCustomerContact customerContact,
  ) => guardResult(() => onCreate!(customerContact));

  @override
  Future<Result<void>> updateCustomerContact(
    int id,
    InputCustomerContact customerContact,
  ) => guardResult(() => onUpdate!(id, customerContact));
}

void main() {
  testWidgets(
    'AddContactModalDialog awaits save, stays open on error preserving text, and pops on success',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late Completer<void> saveCompleter;
      final deviceRepo = _StubDeviceRepository(
        onCreate: (_) {
          saveCompleter = Completer<void>();
          return saveCompleter.future;
        },
      );

      final controller =
          testDeviceCustomerPageController(deviceRepository: deviceRepo)
            ..deviceCustomer = _sampleDevice()
            ..technicians = [
              Technician(id: 2, name: 'Carlos', number: '11988888888'),
            ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  unawaited(
                    showDialog<void>(
                      context: context,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: controller,
                        child: const AddContactModalDialog(),
                      ),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(AddContactModalDialog), findsOneWidget);

      // Fill required dropdowns: Tipo de contato -> Pessoalmente
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pessoalmente').last);
      await tester.pumpAndSettle();

      // Contactante -> Carlos
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carlos').last);
      await tester.pumpAndSettle();

      // Status do aparelho -> Em andamento
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Em andamento').last);
      await tester.pumpAndSettle();

      // Status do contato -> Realizado
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Realizado').last);
      await tester.pumpAndSettle();

      // Diálogo
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.hintText?.contains('detalhes da conversa') ??
                  false),
        ),
        'Texto importante não pode sumir',
      );
      await tester.pump();

      // Tap Salvar -> stays open while awaiting API
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.byType(AddContactModalDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Fail API call -> dialog stays open with text preserved
      saveCompleter.completeError(
        RequisitionException('Erro ao salvar', '500'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AddContactModalDialog), findsOneWidget);
      expect(find.text('Texto importante não pode sumir'), findsOneWidget);

      // Retry and succeed -> dialog closes
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      saveCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.byType(AddContactModalDialog), findsNothing);
    },
  );

  testWidgets(
    'EditContactModalDialog awaits save, stays open on error preserving text, and pops on success',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late Completer<void> updateCompleter;
      final deviceRepo = _StubDeviceRepository(
        onUpdate: (_, __) {
          updateCompleter = Completer<void>();
          return updateCompleter.future;
        },
      );

      final controller =
          testDeviceCustomerPageController(deviceRepository: deviceRepo)
            ..deviceCustomer = _sampleDevice()
            ..technicians = [
              Technician(id: 2, name: 'Carlos', number: '11988888888'),
            ];

      final contact = CustomerContact(
        id: 55,
        deviceId: 1,
        technicianId: 2,
        technicianName: 'Carlos',
        phone: '11999999999',
        phoneNumber: '11999999999',
        type: 'mensagem',
        hasMadeContact: true,
        lastContact: DateTime(2026, 2, 1),
        conversation: 'Conversa inicial',
        deviceStatus: StatusEnum.inProgress,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  unawaited(
                    showDialog<void>(
                      context: context,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: controller,
                        child: EditContactModalDialog(contact: contact),
                      ),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(EditContactModalDialog), findsOneWidget);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.hintText?.contains('detalhes da conversa') ??
                  false),
        ),
        'Conversa editada',
      );
      await tester.pump();

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.byType(EditContactModalDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      updateCompleter.completeError(Exception('timeout'));
      await tester.pumpAndSettle();

      expect(find.byType(EditContactModalDialog), findsOneWidget);
      expect(find.text('Conversa editada'), findsOneWidget);

      await tester.tap(find.text('Salvar'));
      await tester.pump();
      updateCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.byType(EditContactModalDialog), findsNothing);
    },
  );
}
