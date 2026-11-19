import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';

class _RecordingAllDevicesRepository implements AllDevicesRepository {
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
  Future<Page<DeviceDataTable>> getAllDevicesFiltering([
    DeviceFilter? filter,
  ]) async {
    lastAllDevicesFilter = filter;
    return _emptyPage();
  }

  @override
  Future<Page<DeviceDataTable>> searchDevices([
    DeviceSearchFilter? filter,
  ]) async {
    lastSearchDevicesFilter = filter;
    return _emptyPage();
  }

  @override
  Future<List<DeviceBrand>> getAllDeviceBrands([String? name]) async => [];

  @override
  Future<List<DeviceType>> getAllDeviceTypes([String? name]) async => [];
}

void main() {
  group('AllDevicesController.filterTable', () {
    test(
      'preserves spaces and accents in customerName and strips masks for cpf/phone/id',
      () async {
        final repo = _RecordingAllDevicesRepository();
        final controller = AllDevicesController(repo);
        await Future.delayed(const Duration(milliseconds: 250));

        controller.filterTable('  Maria da Conceição  ');
        expect(controller.filter.customerName, 'Maria da Conceição');
        expect(controller.filter.customerCpf, isNull);
        await Future.delayed(const Duration(milliseconds: 250));

        controller.filterTable('529.982.247-25');
        expect(controller.filter.customerCpf, '52998224725');
        expect(controller.filter.customerName, isNull);
        await Future.delayed(const Duration(milliseconds: 250));

        controller.filterTable('(11) 98765-4321');
        expect(controller.filter.customerPhone, '11987654321');
        await Future.delayed(const Duration(milliseconds: 250));

        controller.filterTable('  99  ');
        expect(controller.filter.deviceId, 99);
        await Future.delayed(const Duration(milliseconds: 250));
      },
    );
  });

  group('SearchDevicesController.filterTable', () {
    test(
      'preserves spaces and accents in searchQuery and strips masks for cpf/phone/id',
      () async {
        final repo = _RecordingAllDevicesRepository();
        final controller = SearchDevicesController(repo);
        await Future.delayed(const Duration(milliseconds: 250));

        controller.filterTable('  José   Antônio  ');
        expect(controller.filter.searchQuery, 'José Antônio');
        await Future.delayed(const Duration(milliseconds: 250));

        controller.filterTable('529.982.247-25');
        expect(controller.filter.customerCpf, '52998224725');
        expect(controller.filter.searchQuery, isNull);
        await Future.delayed(const Duration(milliseconds: 250));

        controller.filterTable('(11) 3333-4444');
        expect(controller.filter.customerPhone, '1133334444');
        await Future.delayed(const Duration(milliseconds: 250));

        controller.filterTable('  77  ');
        expect(controller.filter.deviceId, 77);
        await Future.delayed(const Duration(milliseconds: 250));

        controller.filterTable('   ');
        expect(controller.filter.searchQuery, isNull);
        expect(controller.filter.deviceId, isNull);
        await Future.delayed(const Duration(milliseconds: 250));
      },
    );
  });
}
