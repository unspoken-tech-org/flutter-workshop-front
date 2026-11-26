import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';

import '../../support/fakes/fake_catalog_repository.dart';
import '../../support/fakes/fake_device_repository.dart';
import '../../support/fixtures/page_fixture.dart';

FakeDeviceRepository _recordingDeviceRepository() => FakeDeviceRepository(
  allDevicesFilteringResult: Ok(makePage<DeviceDataTable>(const [])),
  searchDevicesResult: Ok(makePage<DeviceDataTable>(const [])),
);

void main() {
  group('AllDevicesController.filterTable', () {
    test(
      'preserves spaces and accents in customerName and strips masks for cpf/phone/id',
      () async {
        final repo = _recordingDeviceRepository();
        final controller = AllDevicesController(repo, FakeCatalogRepository());
        await Future<void>.delayed(const Duration(milliseconds: 250));

        controller.filterTable('  Maria da Conceição  ');
        expect(controller.filter.customerName, 'Maria da Conceição');
        expect(controller.filter.customerCpf, isNull);
        await Future<void>.delayed(const Duration(milliseconds: 250));

        controller.filterTable('529.982.247-25');
        expect(controller.filter.customerCpf, '52998224725');
        expect(controller.filter.customerName, isNull);
        await Future<void>.delayed(const Duration(milliseconds: 250));

        controller.filterTable('(11) 98765-4321');
        expect(controller.filter.customerPhone, '11987654321');
        await Future<void>.delayed(const Duration(milliseconds: 250));

        controller.filterTable('  99  ');
        expect(controller.filter.deviceId, 99);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      },
    );
  });

  group('SearchDevicesController.filterTable', () {
    test(
      'preserves spaces and accents in searchQuery and strips masks for cpf/phone/id',
      () async {
        final repo = _recordingDeviceRepository();
        final controller = SearchDevicesController(repo);
        await Future<void>.delayed(const Duration(milliseconds: 250));

        controller.filterTable('  José   Antônio  ');
        expect(controller.filter.searchQuery, 'José Antônio');
        await Future<void>.delayed(const Duration(milliseconds: 250));

        controller.filterTable('529.982.247-25');
        expect(controller.filter.customerCpf, '52998224725');
        expect(controller.filter.searchQuery, isNull);
        await Future<void>.delayed(const Duration(milliseconds: 250));

        controller.filterTable('(11) 3333-4444');
        expect(controller.filter.customerPhone, '1133334444');
        await Future<void>.delayed(const Duration(milliseconds: 250));

        controller.filterTable('  77  ');
        expect(controller.filter.deviceId, 77);
        await Future<void>.delayed(const Duration(milliseconds: 250));

        controller.filterTable('   ');
        expect(controller.filter.searchQuery, isNull);
        expect(controller.filter.deviceId, isNull);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      },
    );
  });
}
