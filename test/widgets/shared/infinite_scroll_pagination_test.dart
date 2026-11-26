import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/controllers/all_customer_controller.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/widgets/customers_list.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/all_devices_view.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/widgets/search_devices_view.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer_controller.dart';
import 'package:flutter_workshop_front/widgets/shared/infinite_scroll_listener.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';

import '../../support/fakes/fake_catalog_repository.dart';
import '../../support/fakes/fake_customer_repository.dart';
import '../../support/fakes/fake_device_repository.dart';

MinifiedCustomerModel _customer(int id) => MinifiedCustomerModel(
  customerId: id,
  name: 'Cliente $id',
  createdAt: DateTime(2026, 1, 1),
  cpf: '52998224725',
  mainPhone: '11999999999',
  email: 'cliente$id@test.com',
  gender: 'Masculino',
);

DeviceDataTable _device(int id) => DeviceDataTable(
  deviceId: id,
  customerId: 1,
  customerName: 'Cliente $id',
  type: 'Celular',
  brand: 'Samsung',
  model: 'Galaxy $id',
  status: StatusEnum.inProgress,
  problem: 'Não liga',
  hasUrgency: false,
  hasRevision: false,
  entryDate: DateTime(2026, 1, 1),
);

Widget _wrapWithRouter(Widget child) {
  final router = GoRouter(
    initialLocation: '/list',
    routes: [
      GoRoute(path: '/list', name: 'list', builder: (context, state) => child),
    ],
  );
  return ChangeNotifierProvider(
    create: (_) => WsDrawerController(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('InfiniteScrollListener and pagination views', () {
    testWidgets(
      'CustomersList auto-loads page 2 on high viewport without scrolling',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final requestedPages = <int>[];
        final repo = FakeCustomerRepository(
          onSearchCustomers: (filter) async {
            final page = filter?.page ?? 0;
            requestedPages.add(page);
            if (page == 0) {
              return Ok(
                Page(
                  content: [_customer(1), _customer(2)],
                  last: false,
                  totalPages: 2,
                  totalElements: 4,
                  size: 2,
                  number: 0,
                  numberOfElements: 2,
                  first: true,
                  empty: false,
                ),
              );
            }
            return Ok(
              Page(
                content: [_customer(3), _customer(4)],
                last: true,
                totalPages: 2,
                totalElements: 4,
                size: 2,
                number: 1,
                numberOfElements: 2,
                first: false,
                empty: false,
              ),
            );
          },
        );

        final controller = AllCustomerController(customerRepository: repo);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => CustomersList(
                  controller: controller,
                  customers: controller.customers,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(requestedPages, [0, 1]);
        expect(repo.recordedSearchFilters.map((f) => (f?.page, f?.size)), [
          (0, 10),
          (1, 10),
        ]);
        expect(controller.customers.length, 4);
        expect(controller.hasMore, isFalse);
      },
    );

    testWidgets(
      'InfiniteScrollListener triggers loadMore within 200px threshold before exact bottom',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        var loadMoreCalls = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 300,
                child: InfiniteScrollListener(
                  scrollController: scrollController,
                  hasMore: true,
                  isLoading: false,
                  isLoadingMore: false,
                  loadMoreFailed: false,
                  onLoadMore: () => loadMoreCalls++,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 20,
                    itemBuilder: (_, i) =>
                        SizedBox(height: 50, child: Text('Item $i')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(loadMoreCalls, 0);

        // maxScrollExtent = 20 * 50 - 300 = 700. Jump to 550 (within 200px threshold, not at 700)
        scrollController.jumpTo(550);
        await tester.pump();

        expect(loadMoreCalls, 1);
      },
    );

    testWidgets(
      'CustomersList does not loop when page 2 fails and allows manual retry',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final requestedPages = <int>[];
        var shouldFailPage1 = true;

        final repo = FakeCustomerRepository(
          onSearchCustomers: (filter) async {
            final page = filter?.page ?? 0;
            requestedPages.add(page);
            if (page == 0) {
              return Ok(
                Page(
                  content: [_customer(1), _customer(2)],
                  last: false,
                  totalPages: 2,
                  totalElements: 4,
                  size: 2,
                  number: 0,
                  numberOfElements: 2,
                  first: true,
                  empty: false,
                ),
              );
            }
            if (shouldFailPage1) {
              return const Err(
                ValidationFailure(
                  message: 'Falha na paginação',
                  code: '500',
                  statusCode: 400,
                ),
              );
            }
            return Ok(
              Page(
                content: [_customer(3)],
                last: true,
                totalPages: 2,
                totalElements: 3,
                size: 2,
                number: 1,
                numberOfElements: 1,
                first: false,
                empty: false,
              ),
            );
          },
        );

        final controller = AllCustomerController(customerRepository: repo);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => CustomersList(
                  controller: controller,
                  customers: controller.customers,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(requestedPages, [0, 1]);
        expect(controller.loadMoreFailed, isTrue);
        expect(find.text('Tentar novamente'), findsOneWidget);

        // Additional pumps must NOT trigger extra loadMore calls
        await tester.pump(const Duration(milliseconds: 200));
        expect(requestedPages, [0, 1]);

        // Manual retry recovers
        shouldFailPage1 = false;
        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();

        expect(requestedPages, [0, 1, 1]);
        expect(controller.loadMoreFailed, isFalse);
        expect(controller.customers.length, 3);
      },
    );

    testWidgets(
      'AllDevicesView auto-loads page 2 on high viewport and prevents error loop',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final requestedPages = <int>[];
        final repo = FakeDeviceRepository(
          onGetAllDevicesFiltering: (filter) async {
            final page = filter?.page ?? 0;
            requestedPages.add(page);
            if (page == 0) {
              return Ok(
                Page(
                  content: [_device(1)],
                  last: false,
                  totalPages: 2,
                  totalElements: 2,
                  size: 1,
                  number: 0,
                  numberOfElements: 1,
                  first: true,
                  empty: false,
                ),
              );
            }
            return const Err(NetworkFailure());
          },
        );

        final controller = AllDevicesController(repo, FakeCatalogRepository());
        await tester.pumpWidget(
          _wrapWithRouter(
            ChangeNotifierProvider.value(
              value: controller,
              child: const AllDevicesView(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(requestedPages, [0, 1]);
        expect(controller.loadMoreFailed, isTrue);
        expect(find.text('Tentar novamente'), findsOneWidget);

        // New search/filter resets loadMoreFailed
        controller.filterTable('Samsung');
        expect(controller.loadMoreFailed, isFalse);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'SearchDevicesView auto-loads page 2 on high viewport, prevents error loop, and retries',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final requestedPages = <int>[];
        var failPage1 = true;
        final repo = FakeDeviceRepository(
          onSearchDevices: (filter) async {
            final page = filter?.page ?? 0;
            requestedPages.add(page);
            if (page == 0) {
              return Ok(
                Page(
                  content: [_device(10)],
                  last: false,
                  totalPages: 2,
                  totalElements: 2,
                  size: 1,
                  number: 0,
                  numberOfElements: 1,
                  first: true,
                  empty: false,
                ),
              );
            }
            if (failPage1) {
              return const Err(
                ValidationFailure(
                  message: 'Falha na busca',
                  code: '500',
                  statusCode: 400,
                ),
              );
            }
            return Ok(
              Page(
                content: [_device(11)],
                last: true,
                totalPages: 2,
                totalElements: 2,
                size: 1,
                number: 1,
                numberOfElements: 1,
                first: false,
                empty: false,
              ),
            );
          },
        );

        final controller = SearchDevicesController(repo);
        await tester.pumpWidget(
          _wrapWithRouter(
            ChangeNotifierProvider.value(
              value: controller,
              child: const SearchDevicesView(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(requestedPages, [0, 1]);
        expect(controller.loadMoreFailed, isTrue);
        expect(find.text('Tentar novamente'), findsOneWidget);

        failPage1 = false;
        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();

        expect(requestedPages, [0, 1, 1]);
        expect(controller.devices.length, 2);
        expect(controller.hasMore, isFalse);
      },
    );

    testWidgets(
      'InfiniteScrollListener triggers loadMore when viewport resizes taller via ScrollMetricsNotification',
      (tester) async {
        tester.view.physicalSize = const Size(800, 300);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        var loadMoreCalls = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InfiniteScrollListener(
                scrollController: scrollController,
                hasMore: true,
                isLoading: false,
                isLoadingMore: false,
                loadMoreFailed: false,
                onLoadMore: () => loadMoreCalls++,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 8,
                  itemBuilder: (_, i) =>
                      SizedBox(height: 80, child: Text('Row $i')),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        // 8 * 80 = 640 > 300, maxScrollExtent = 340 > 200 -> should not fire yet
        expect(loadMoreCalls, 0);

        // Resize window taller than content (640 < 1000 -> maxScrollExtent == 0)
        tester.view.physicalSize = const Size(800, 1000);
        await tester.pumpAndSettle();

        expect(loadMoreCalls, 1);
      },
    );
  });
}
