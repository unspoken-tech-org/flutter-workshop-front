import '../../support/offline_services.dart';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/widgets/customer_detail_form.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/device_details_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/contact_card.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_info_header_widget.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_technical_info_widget.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';

import '../../support/fakes/fake_catalog_repository.dart';
import '../../support/fakes/fake_customer_repository.dart';
import '../../support/fakes/fake_device_repository.dart';

DeviceCustomer _sampleDevice({
  int technicianId = 10,
  String? technicianName = 'Carlos Silva',
  List<Map<String, dynamic>> customerPhones = const [],
}) => DeviceCustomer.fromJson({
  'deviceId': 42,
  'customerId': 7,
  'customerName': 'Maria da Silva',
  'deviceStatus': 'EM_ANDAMENTO',
  'brandName': 'Samsung',
  'modelName': 'Galaxy',
  'typeName': 'Celular',
  'technicianId': technicianId,
  'technicianName': technicianName,
  'problem': 'Não liga',
  'observation': '',
  'budget': null,
  'serviceValue': null,
  'budgetFee': null,
  'hasUrgency': false,
  'revision': false,
  'deviceColors': const <String>['Preto'],
  'entryDate': '2026-01-10T00:00:00',
  'departureDate': null,
  'lastUpdate': null,
  'customerContacts': const <dynamic>[],
  'customerPhones': customerPhones,
  'otherDevices': const <dynamic>[],
  'payments': const <dynamic>[],
});

Widget _wrapWithRouter(Widget child) {
  final router = GoRouter(
    initialLocation: '/device',
    routes: [
      GoRoute(
        path: '/device',
        name: DeviceDetailsPage.route,
        builder: (context, state) => child,
      ),
    ],
  );
  return ChangeNotifierProvider(
    create: (_) => WsDrawerController(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('DeviceDetailsPage resilience on load failure', () {
    testWidgets(
      'shows error state and retry button when getCustomerDeviceById fails, then recovers on retry',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        var attempts = 0;
        final deviceRepo = FakeDeviceRepository(
          onGetCustomerDeviceById: (id) async {
            attempts++;
            if (attempts == 1) {
              return const Err(
                ValidationFailure(
                  message: 'Falha ao carregar aparelho',
                  code: '500',
                  statusCode: 400,
                ),
              );
            }
            return Ok(_sampleDevice());
          },
        );
        final catalogRepo = FakeCatalogRepository(
          techniciansResult: Ok([
            Technician(id: 10, name: 'Carlos Silva', number: '11999999999'),
          ]),
        );

        await tester.pumpWidget(
          _wrapWithRouter(
            DeviceDetailsPage(
              deviceId: 42,
              controllerFactory: () => testDeviceCustomerPageController(
                deviceRepository: deviceRepo,
                catalogRepository: catalogRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Falha ao carregar aparelho'), findsOneWidget);
        expect(find.text('Tentar novamente'), findsOneWidget);

        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();

        expect(attempts, 2);
        expect(find.text('ID do aparelho # 42'), findsOneWidget);
      },
    );

    testWidgets(
      'renders device details without crashing when getTechnicians fails',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final deviceRepo = FakeDeviceRepository(
          customerDeviceResult: Ok(_sampleDevice()),
        );
        final catalogRepo = FakeCatalogRepository(
          techniciansResult: const Err(NetworkFailure()),
        );

        await tester.pumpWidget(
          _wrapWithRouter(
            DeviceDetailsPage(
              deviceId: 42,
              controllerFactory: () => testDeviceCustomerPageController(
                deviceRepository: deviceRepo,
                catalogRepository: catalogRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ID do aparelho # 42'), findsOneWidget);
        expect(find.text('Telefone principal: Não informado'), findsOneWidget);
      },
    );
  });

  group('Unsafe firstWhere and null conversation guards', () {
    testWidgets(
      'CustomerDeviceInfoHeaderWidget falls back when no main phone exists',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = testDeviceCustomerPageController()
          ..deviceCustomer = _sampleDevice(customerPhones: const []);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider.value(
                value: controller,
                child: const CustomerDeviceInfoHeaderWidget(),
              ),
            ),
          ),
        );

        expect(find.text('Telefone principal: Não informado'), findsOneWidget);
      },
    );

    testWidgets(
      'CustomerDeviceTechnicalInfoWidget preserves technician when missing from list',
      (tester) async {
        final formKey = GlobalKey<FormState>();
        final controller = testDeviceCustomerPageController()
          ..deviceCustomer = _sampleDevice(
            technicianId: 99,
            technicianName: 'Técnico Antigo',
          )
          ..technicians = [
            Technician(id: 1, name: 'Outro Técnico', number: '11988888888'),
          ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider.value(
                value: controller,
                child: Form(
                  key: formKey,
                  child: const CustomerDeviceTechnicalInfoWidget(
                    isEditing: true,
                  ),
                ),
              ),
            ),
          ),
        );

        formKey.currentState!.save();
        expect(controller.deviceCustomer?.technicianId, 99);
        expect(controller.deviceCustomer?.technicianName, 'Técnico Antigo');
      },
    );

    testWidgets('ContactCard renders safely when conversation is null', (
      tester,
    ) async {
      final contact = CustomerContact(
        id: 1,
        deviceId: 42,
        technicianId: 10,
        technicianName: 'Carlos',
        phone: null,
        phoneNumber: null,
        type: 'mensagem',
        hasMadeContact: true,
        lastContact: DateTime(2026, 1, 10),
        conversation: null,
        deviceStatus: StatusEnum.inProgress,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ContactCard(contact: contact)),
        ),
      );

      expect(find.byType(ContactCard), findsOneWidget);
    });

    testWidgets(
      'CustomerDetailForm renders and saves safely when customer has no main phone',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = CustomerDetailController(FakeCustomerRepository());
        final customer = CustomerModel(
          customerId: 1,
          name: 'João',
          createdAt: DateTime(2026, 1, 1),
          cpf: '52998224725',
          gender: 'Masculino',
          email: null,
          phones: const [],
          customerDevices: const [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider.value(
                value: controller,
                child: SingleChildScrollView(
                  child: CustomerDetailForm(
                    customer: customer,
                    controller: controller,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomerDetailForm), findsOneWidget);
        tester.state<FormState>(find.byType(Form)).save();
        expect(controller.updatedCustomerData.phones.first.id, isNull);
      },
    );
  });
}
