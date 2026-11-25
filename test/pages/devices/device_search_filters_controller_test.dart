import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import '../../helpers/result_guard.dart';

class _RecordingDeviceRepository extends Fake implements DeviceRepository {
  DeviceFilter? lastAllDevicesFilter;
  DeviceSearchFilter? lastSearchDevicesFilter;

  Page<DeviceDataTable> _emptyPage() => Page<DeviceDataTable>(
    content: [],
    last: true,
    totalPages: 0,
    totalElements: 0,
    size: 15,
    number: 0,
    numberOfElements: 0,
    first: true,
    empty: true,
  );

  @override
  Future<Result<Page<DeviceDataTable>>> getAllDevicesFiltering([
    DeviceFilter? filter,
  ]) => guardResult(() async {
    lastAllDevicesFilter = filter;
    return _emptyPage();
  });

  @override
  Future<Result<Page<DeviceDataTable>>> searchDevices([
    DeviceSearchFilter? filter,
  ]) => guardResult(() async {
    lastSearchDevicesFilter = filter;
    return _emptyPage();
  });
}

class _StubCatalogRepository extends Fake implements CatalogRepository {
  @override
  Future<Result<List<DeviceBrand>>> getAllDeviceBrands([
    String? name,
    bool forceRefresh = false,
  ]) => guardResult(() async => []);

  @override
  Future<Result<List<DeviceType>>> getAllDeviceTypes([
    String? name,
    bool forceRefresh = false,
  ]) => guardResult(() async => []);
}

void main() {
  group('AllDevicesController.filterTable', () {
    test(
      'preserves spaces and accents in customerName and strips masks for cpf/phone/id',
      () async {
        final repo = _RecordingDeviceRepository();
        final controller = AllDevicesController(repo, _StubCatalogRepository());
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
        final repo = _RecordingDeviceRepository();
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
