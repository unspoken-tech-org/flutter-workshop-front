import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/device/device_query.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';

import '../../support/fakes/fake_catalog_repository.dart';
import '../../support/fakes/fake_device_repository.dart';
import '../../support/fixtures/page_fixture.dart';

DeviceDataTable _device(int id, String name) => DeviceDataTable(
  deviceId: id,
  customerId: id,
  customerName: name,
  type: 'Notebook',
  brand: 'Dell',
  model: 'Inspiron',
  status: StatusEnum.newDevice,
  problem: 'Sem imagem',
  hasUrgency: false,
  hasRevision: false,
  entryDate: DateTime(2026, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AllDevicesController', () {
    test('filterTable queries with the classified search text', () async {
      final repo = FakeDeviceRepository(
        queryDevicesResult: Ok(makePage<DeviceDataTable>(const [])),
      );
      final controller = AllDevicesController(
        repo,
        FakeCatalogRepository(),
        debounce: Duration.zero,
      );
      await Future<void>.delayed(Duration.zero);

      controller.filterTable('  Maria da Conceição  ');
      expect(controller.query.searchQuery, 'Maria da Conceição');

      controller.filterTable('529.982.247-25');
      expect(controller.query.customerCpf, '52998224725');
      expect(controller.query.searchQuery, isNull);
      await Future<void>.delayed(Duration.zero);

      expect(repo.recordedDeviceQueries.last.$1.customerCpf, '52998224725');
      expect(repo.recordedDeviceQueries.last.$2, 0);
    });

    test(
      'old device response arriving after the new filter is discarded',
      () async {
        final pending =
            <(DeviceQuery, int, Completer<Result<Page<DeviceDataTable>>>)>[];
        final repo = FakeDeviceRepository(
          onQueryDevices: (query, page) {
            final completer = Completer<Result<Page<DeviceDataTable>>>();
            pending.add((query, page, completer));
            return completer.future;
          },
        );
        final controller = AllDevicesController(
          repo,
          FakeCatalogRepository(),
          debounce: Duration.zero,
        );
        expect(pending, hasLength(1));

        controller.addRemoveStatus(StatusEnum.ready);
        expect(pending, hasLength(2));
        expect(pending[1].$1.status, [StatusEnum.ready]);

        pending[1].$3.complete(
          Ok(makePage([_device(2, 'Pronto')], last: false)),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.devices.map((d) => d.customerName), ['Pronto']);

        pending[0].$3.complete(Ok(makePage([_device(1, 'Antigo')])));
        await Future<void>.delayed(Duration.zero);
        expect(controller.devices.map((d) => d.customerName), ['Pronto']);

        // A loadMore in flight is dropped when a new search starts.
        final loadMore = controller.loadMore();
        expect(pending[2].$2, 1);
        controller.filterTable('Cliente Final');
        pending[3].$3.complete(Ok(makePage([_device(4, 'Cliente Final')])));
        await Future<void>.delayed(Duration.zero);
        pending[2].$3.complete(
          Ok(makePage([_device(3, 'PaginaVelha')], number: 1)),
        );
        await loadMore;

        expect(controller.devices.map((d) => d.customerName), [
          'Cliente Final',
        ]);
      },
    );

    test('failed new search clears list and totals', () async {
      final repo = FakeDeviceRepository(
        onQueryDevices: (query, page) async => query.status.isEmpty
            ? Ok(makePage([_device(1, 'Ana'), _device(2, 'Bia')], last: false))
            : const Err(NetworkFailure()),
      );
      final controller = AllDevicesController(
        repo,
        FakeCatalogRepository(),
        debounce: Duration.zero,
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.totalElements, 2);

      controller.addRemoveStatus(StatusEnum.ready);
      await Future<void>.delayed(Duration.zero);

      expect(controller.devices, isEmpty);
      expect(controller.totalElements, 0);
      expect(controller.hasMore, isFalse);
      expect(controller.isLoading, isFalse);
    });
  });
}
