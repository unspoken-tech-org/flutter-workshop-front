import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_infos_widget.dart';
import 'package:provider/provider.dart';

import '../../../../support/fakes/fake_device_repository.dart';
import '../../../../support/fixtures/device_customer_fixture.dart';
import '../../../../support/offline_services.dart';
import '../../../../support/widget_test_harness.dart';

void main() {
  testWidgets('durante o salvamento Salvar e Cancelar ficam desabilitados, '
      'com progresso no Salvar', (tester) async {
    final pending = Completer<Result<DeviceCustomer>>();
    final controller =
        testDeviceCustomerPageController(
            deviceRepository: FakeDeviceRepository(
              onUpdateDeviceCustomer: (_) => pending.future,
            ),
          )
          ..deviceCustomer = makeDeviceCustomer(
            technicianId: 1,
            technicianName: 'Carlos',
          )
          ..technicians = [
            Technician(id: 1, name: 'Carlos', number: '11999999999'),
          ];
    addTearDown(controller.dispose);

    await pumpAppWidget(
      tester,
      ChangeNotifierProvider<DeviceCustomerPageController>.value(
        value: controller,
        child: const Scaffold(
          body: SingleChildScrollView(child: CustomerDeviceInfosWidget()),
        ),
      ),
    );

    TextButton button(String id) => tester.widget<TextButton>(
      find.descendant(
        of: find.bySemanticsIdentifier(id),
        matching: find.byWidgetPredicate((w) => w is TextButton),
      ),
    );

    await tester.tap(find.bySemanticsIdentifier('deviceDetail.edit'));
    await tester.pump();
    await tester.ensureVisible(find.bySemanticsIdentifier('deviceDetail.save'));
    await tester.tap(find.bySemanticsIdentifier('deviceDetail.save'));
    await tester.pump();

    expect(controller.isSaving, isTrue);
    expect(
      find.descendant(
        of: find.bySemanticsIdentifier('deviceDetail.save'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(button('deviceDetail.save').onPressed, isNull);
    expect(button('deviceDetail.cancel').onPressed, isNull);

    pending.complete(const Err(NetworkFailure(shownGlobally: true)));
    await tester.pump();

    // Em erro continua editando, com os botões de volta.
    expect(button('deviceDetail.save').onPressed, isNotNull);
    expect(button('deviceDetail.cancel').onPressed, isNotNull);
  });
}
