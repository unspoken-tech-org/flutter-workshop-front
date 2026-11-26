import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart'
    as tbm;
import 'package:flutter_workshop_front/pages/customers/all_customers/controllers/all_customer_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/type_brand_model_autocomplete_form_field.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/searchable_dropdown_form_field.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';

import '../../support/fakes/fake_catalog_repository.dart';
import '../../support/fakes/fake_customer_repository.dart';
import '../../support/fakes/fake_device_repository.dart';

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

MinifiedCustomerModel _customer(int id, String name) => MinifiedCustomerModel(
  customerId: id,
  name: name,
  createdAt: DateTime(2026, 1, 1),
  cpf: '00000000000',
  mainPhone: '11999999999',
  email: null,
  gender: 'OTHER',
);

Page<T> _page<T>(List<T> content, {required int number, required bool last}) =>
    Page<T>(
      content: content,
      last: last,
      totalPages: last ? number + 1 : number + 2,
      totalElements: content.length,
      size: 10,
      number: number,
      numberOfElements: content.length,
      first: number == 0,
      empty: content.isEmpty,
    );

(
  FakeCustomerRepository,
  List<(CustomerSearchFilter?, Completer<Result<Page<MinifiedCustomerModel>>>)>,
)
_pendingCustomerRepo() {
  final pending =
      <
        (CustomerSearchFilter?, Completer<Result<Page<MinifiedCustomerModel>>>)
      >[];
  final repo = FakeCustomerRepository(
    onSearchCustomers: (filter) {
      final completer = Completer<Result<Page<MinifiedCustomerModel>>>();
      pending.add((filter, completer));
      return completer.future;
    },
  );
  return (repo, pending);
}

(
  FakeDeviceRepository,
  List<(DeviceFilter?, Completer<Result<Page<DeviceDataTable>>>)>,
  List<(DeviceSearchFilter?, Completer<Result<Page<DeviceDataTable>>>)>,
)
_pendingDeviceRepo() {
  final pendingAll =
      <(DeviceFilter?, Completer<Result<Page<DeviceDataTable>>>)>[];
  final pendingSearch =
      <(DeviceSearchFilter?, Completer<Result<Page<DeviceDataTable>>>)>[];
  final repo = FakeDeviceRepository(
    onGetAllDevicesFiltering: (filter) {
      final completer = Completer<Result<Page<DeviceDataTable>>>();
      pendingAll.add((filter, completer));
      return completer.future;
    },
    onSearchDevices: (filter) {
      final completer = Completer<Result<Page<DeviceDataTable>>>();
      pendingSearch.add((filter, completer));
      return completer.future;
    },
  );
  return (repo, pendingAll, pendingSearch);
}

void main() {
  group('3.2 — StatusEnum desconhecido não derruba a lista', () {
    test(
      'fromDbName retorna StatusEnum.unknown para valores desconhecidos e null',
      () {
        expect(StatusEnum.fromDbName('STATUS_FUTURO'), StatusEnum.unknown);
        expect(StatusEnum.fromDbName(''), StatusEnum.unknown);
        expect(StatusEnum.fromDbName(null), StatusEnum.unknown);
      },
    );

    test('selectableValues não inclui StatusEnum.unknown', () {
      expect(StatusEnum.selectableValues, isNot(contains(StatusEnum.unknown)));
      expect(StatusEnum.selectableValues.length, StatusEnum.values.length - 1);
    });

    test('DeviceDataTable.fromJson aceita status desconhecido sem lançar', () {
      final model = DeviceDataTable.fromJson({
        'deviceId': 10,
        'customerId': 20,
        'customerName': 'Maria',
        'type': 'TV',
        'brand': 'LG',
        'model': 'OLED',
        'status': 'NOVO_STATUS_API',
        'problem': 'Não liga',
        'hasUrgency': false,
        'hasRevision': false,
        'entryDate': '2026-01-01T10:00:00',
      });

      expect(model.status, StatusEnum.unknown);
    });
  });

  group('AllCustomerController.refresh', () {
    test('recarrega a primeira página mantendo o termo de busca', () async {
      final (repo, pending) = _pendingCustomerRepo();
      final controller = AllCustomerController(customerRepository: repo);
      pending[0].$2.complete(Ok(_page([], number: 0, last: true)));

      final search = controller.searchCustomers('Maria');
      pending[1].$2.complete(
        Ok(_page([_customer(1, 'Maria')], number: 0, last: true)),
      );
      await search;

      final refresh = controller.refresh();
      expect(pending.length, 3);
      expect(pending[2].$1?.searchName, 'Maria');
      expect(pending[2].$1?.page, 0);
      pending[2].$2.complete(
        Ok(
          _page(
            [_customer(1, 'Maria'), _customer(2, 'Maria Nova')],
            number: 0,
            last: true,
          ),
        ),
      );
      await refresh;

      expect(controller.customers.map((c) => c.name), ['Maria', 'Maria Nova']);
    });
  });

  group('3.2 — AllCustomerController concorrência e paginação', () {
    test(
      'busca iniciada durante loading não é descartada e resposta antiga é ignorada',
      () async {
        final (repo, pending) = _pendingCustomerRepo();
        final controller = AllCustomerController(customerRepository: repo);

        expect(controller.isLoading, true);
        expect(pending.length, 1);

        // Segunda busca dispara enquanto a primeira ainda está em voo
        final secondFuture = controller.searchCustomers('Maria');
        expect(pending.length, 2);

        // Segunda busca responde primeiro
        pending[1].$2.complete(
          Ok(_page([_customer(2, 'Maria')], number: 0, last: true)),
        );
        await secondFuture;

        expect(controller.isLoading, false);
        expect(controller.customers.map((c) => c.name), ['Maria']);

        // Primeira busca responde atrasada: deve ser ignorada
        pending[0].$2.complete(
          Ok(_page([_customer(1, 'Antigo')], number: 0, last: true)),
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.customers.map((c) => c.name), ['Maria']);
      },
    );

    test(
      'loadMore em voo de busca antiga não entra nos resultados da nova busca',
      () async {
        final (repo, pending) = _pendingCustomerRepo();
        final controller = AllCustomerController(customerRepository: repo);

        pending[0].$2.complete(
          Ok(_page([_customer(1, 'Inicial')], number: 0, last: false)),
        );
        await Future<void>.delayed(Duration.zero);

        // Inicia loadMore da busca antiga
        final loadMoreFuture = controller.loadMore();
        expect(controller.isLoadingMore, true);
        expect(pending.length, 2);

        // Antes do loadMore responder, usuário faz nova busca
        final newSearchFuture = controller.searchCustomers('Novo');
        expect(controller.isLoadingMore, false);
        expect(pending.length, 3);

        pending[2].$2.complete(
          Ok(_page([_customer(99, 'Novo')], number: 0, last: true)),
        );
        await newSearchFuture;

        // Agora o loadMore antigo responde: deve ser ignorado
        pending[1].$2.complete(
          Ok(_page([_customer(2, 'PaginaAntiga')], number: 1, last: true)),
        );
        await loadMoreFuture;

        expect(controller.customers.map((c) => c.name), ['Novo']);
      },
    );
  });

  group('3.2 — AllDevicesController concorrência e paginação', () {
    test(
      'filtro alterado durante loading não é descartado e loadMore antigo não contamina nova busca',
      () async {
        final (repo, pendingAllDevices, _) = _pendingDeviceRepo();
        final controller = AllDevicesController(repo, FakeCatalogRepository());

        // Aguarda debounce inicial de 200ms
        await Future<void>.delayed(const Duration(milliseconds: 220));
        expect(pendingAllDevices.length, 1);

        // Usuário altera filtro enquanto a primeira requisição está em voo
        controller.addRemoveStatus(StatusEnum.ready);
        await Future<void>.delayed(const Duration(milliseconds: 220));
        expect(pendingAllDevices.length, 2);

        // Requisição mais nova (PRONTO) completa
        pendingAllDevices[1].$2.complete(
          Ok(_page([_device(2, 'Pronto')], number: 0, last: false)),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.devices.map((d) => d.customerName), ['Pronto']);
        expect(controller.isLoading, false);

        // Requisição inicial atrasada completa: deve ser ignorada
        pendingAllDevices[0].$2.complete(
          Ok(_page([_device(1, 'Antigo')], number: 0, last: true)),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.devices.map((d) => d.customerName), ['Pronto']);

        // Inicia loadMore e antes dele responder dispara nova busca
        final loadMoreFuture = controller.loadMore();
        expect(pendingAllDevices.length, 3);

        controller.filterTable('Cliente Final');
        await Future<void>.delayed(const Duration(milliseconds: 220));
        expect(pendingAllDevices.length, 4);

        pendingAllDevices[3].$2.complete(
          Ok(_page([_device(4, 'Cliente Final')], number: 0, last: true)),
        );
        await Future<void>.delayed(Duration.zero);

        pendingAllDevices[2].$2.complete(
          Ok(_page([_device(3, 'PaginaVelha')], number: 1, last: true)),
        );
        await loadMoreFuture;

        expect(controller.devices.map((d) => d.customerName), [
          'Cliente Final',
        ]);
      },
    );
  });

  group('AllDevicesController total em falha', () {
    test('zera o total quando a nova busca falha', () async {
      final (repo, pendingAllDevices, _) = _pendingDeviceRepo();
      final controller = AllDevicesController(repo, FakeCatalogRepository());

      await Future<void>.delayed(const Duration(milliseconds: 220));
      pendingAllDevices[0].$2.complete(
        Ok(
          _page([_device(1, 'Ana'), _device(2, 'Bia')], number: 0, last: false),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.totalElements, 2);

      controller.addRemoveStatus(StatusEnum.ready);
      await Future<void>.delayed(const Duration(milliseconds: 220));
      pendingAllDevices[1].$2.complete(const Err(NetworkFailure()));
      await Future<void>.delayed(Duration.zero);

      expect(controller.devices, isEmpty);
      expect(controller.totalElements, 0);
      expect(controller.totalPages, 0);
      expect(controller.hasMore, isFalse);
      expect(controller.isLoading, isFalse);
    });
  });

  group('3.2 — SearchDevicesController concorrência e paginação', () {
    test(
      'busca alterada durante loading não é descartada e loadMore antigo não contamina nova busca',
      () async {
        final (repo, _, pendingSearchDevices) = _pendingDeviceRepo();
        final controller = SearchDevicesController(repo);

        await Future<void>.delayed(const Duration(milliseconds: 220));
        expect(pendingSearchDevices.length, 1);

        controller.filterTable('Notebook');
        await Future<void>.delayed(const Duration(milliseconds: 220));
        expect(pendingSearchDevices.length, 2);

        pendingSearchDevices[1].$2.complete(
          Ok(_page([_device(2, 'Notebook')], number: 0, last: false)),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.devices.map((d) => d.customerName), ['Notebook']);
        expect(controller.isLoading, false);

        pendingSearchDevices[0].$2.complete(
          Ok(_page([_device(1, 'Antigo')], number: 0, last: true)),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.devices.map((d) => d.customerName), ['Notebook']);

        final loadMoreFuture = controller.loadMore();
        expect(pendingSearchDevices.length, 3);

        controller.filterTable('TV');
        await Future<void>.delayed(const Duration(milliseconds: 220));
        expect(pendingSearchDevices.length, 4);

        pendingSearchDevices[3].$2.complete(
          Ok(_page([_device(4, 'TV')], number: 0, last: true)),
        );
        await Future<void>.delayed(Duration.zero);

        pendingSearchDevices[2].$2.complete(
          Ok(_page([_device(3, 'PaginaVelha')], number: 1, last: true)),
        );
        await loadMoreFuture;

        expect(controller.devices.map((d) => d.customerName), ['TV']);
      },
    );
  });

  group('SearchDevicesController total em falha', () {
    test('limpa a lista e zera o total quando a nova busca falha', () async {
      final (repo, _, pendingSearchDevices) = _pendingDeviceRepo();
      final controller = SearchDevicesController(repo);

      await Future<void>.delayed(const Duration(milliseconds: 220));
      pendingSearchDevices[0].$2.complete(
        Ok(
          _page([_device(1, 'Ana'), _device(2, 'Bia')], number: 0, last: false),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.devices.length, 2);
      expect(controller.totalElements, 2);
      expect(controller.totalPages, 2);
      expect(controller.hasMore, isTrue);

      controller.filterTable('Notebook');
      await Future<void>.delayed(const Duration(milliseconds: 220));
      pendingSearchDevices[1].$2.complete(
        Err(UnexpectedFailure(cause: Exception('502 Bad Gateway'))),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.devices, isEmpty);
      expect(controller.totalElements, 0);
      expect(controller.totalPages, 0);
      expect(controller.hasMore, isFalse);
      expect(controller.isLoading, isFalse);
    });
  });

  group('3.2 — Autocomplete descarta sugestões de busca antiga', () {
    testWidgets(
      'TypeBrandModelAutocompleteFormField ignora resposta atrasada de query antiga',
      (tester) async {
        final pending = <String, Completer<List<tbm.Type>>>{};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 300,
                  height: 80,
                  child: TypeBrandModelAutocompleteFormField<tbm.Type>(
                    searchFn: (query) {
                      final completer = Completer<List<tbm.Type>>();
                      pending[query] = completer;
                      return completer.future;
                    },
                    createFn: (name) async => tbm.Type(idType: 99, type: name),
                    getName: (item) => item.getName(),
                    getId: (item) => item.getId(),
                    onAccept: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'sam');
        await tester.pump(const Duration(milliseconds: 350));
        expect(pending.containsKey('sam'), true);

        await tester.enterText(find.byType(TextFormField), 'lg');
        await tester.pump(const Duration(milliseconds: 350));
        expect(pending.containsKey('lg'), true);

        // Resposta mais nova chega primeiro
        pending['lg']!.complete([tbm.Type(idType: 2, type: 'LG OLED')]);
        await tester.pumpAndSettle();
        expect(find.text('LG OLED'), findsOneWidget);

        // Resposta antiga ('sam') chega atrasada: não deve sobrescrever 'LG OLED'
        pending['sam']!.complete([tbm.Type(idType: 1, type: 'Samsung Old')]);
        await tester.pumpAndSettle();

        expect(find.text('LG OLED'), findsOneWidget);
        expect(find.text('Samsung Old'), findsNothing);
      },
    );

    testWidgets(
      'SearchableDropdownFormField ignora resposta atrasada de query antiga',
      (tester) async {
        final pending = <String, Completer<List<tbm.Type>>>{};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 300,
                  height: 80,
                  child: SearchableDropdownFormField<tbm.Type>(
                    searchFn: (query) {
                      final completer = Completer<List<tbm.Type>>();
                      pending[query] = completer;
                      return completer.future;
                    },
                    getName: (item) => item.getName(),
                    getId: (item) => item.getId(),
                    onAccept: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'sam');
        await tester.pump(const Duration(milliseconds: 350));
        expect(pending.containsKey('sam'), true);

        await tester.enterText(find.byType(TextFormField), 'lg');
        await tester.pump(const Duration(milliseconds: 350));
        expect(pending.containsKey('lg'), true);

        pending['lg']!.complete([tbm.Type(idType: 2, type: 'LG OLED')]);
        await tester.pumpAndSettle();
        expect(find.text('LG OLED'), findsOneWidget);

        pending['sam']!.complete([tbm.Type(idType: 1, type: 'Samsung Old')]);
        await tester.pumpAndSettle();

        expect(find.text('LG OLED'), findsOneWidget);
        expect(find.text('Samsung Old'), findsNothing);
      },
    );
  });
}
