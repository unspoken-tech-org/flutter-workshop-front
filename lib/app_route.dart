import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/pages/bootstrap_error/bootstrap_error_page.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/all_customers_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/customer_detail_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/customer_register_page.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/all_devices_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/device_details_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/device_register_page.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/search_devices_page.dart';
import 'package:flutter_workshop_front/pages/home/home_page.dart';
import 'package:flutter_workshop_front/pages/setup/setup_page.dart';
import 'package:flutter_workshop_front/pages/not_found_page.dart';
import 'package:go_router/go_router.dart';

String? resolveAuthRedirect(AuthRouteState authState, String matchedLocation) {
  final isSetupRoute = matchedLocation == SetupPage.route;
  final isBootstrapErrorRoute = matchedLocation == BootstrapErrorPage.route;

  switch (authState) {
    case AuthRouteState.restoring:
      return null;
    case AuthRouteState.needsSetup:
      return isSetupRoute ? null : SetupPage.route;
    case AuthRouteState.offline:
    case AuthRouteState.storageError:
      return isBootstrapErrorRoute ? null : BootstrapErrorPage.route;
    case AuthRouteState.authenticated:
      if (isSetupRoute || isBootstrapErrorRoute) {
        return HomePage.route;
      }
      return null;
  }
}

GoRouter buildRouter(
  AuthNotifier authNotifier, {
  @visibleForTesting List<RouteBase>? routesOverride,
}) {
  return GoRouter(
    navigatorKey: SnackBarUtil().navigatorKey,
    initialLocation: HomePage.route,
    routes: routesOverride ?? _routes,
    refreshListenable: authNotifier,
    redirect: (context, state) =>
        resolveAuthRedirect(authNotifier.state, state.matchedLocation),
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}

List<RouteBase> _routes = [
  GoRoute(
    path: HomePage.route,
    name: HomePage.route,
    builder: (context, state) {
      return const HomePage();
    },
  ),
  GoRoute(
    path: SetupPage.route,
    name: SetupPage.route,
    builder: (context, state) {
      return const SetupPage();
    },
  ),
  GoRoute(
    path: BootstrapErrorPage.route,
    name: BootstrapErrorPage.route,
    builder: (context, state) {
      return const BootstrapErrorPage();
    },
  ),
  GoRoute(
    path: '/customer/all',
    name: AllCustomersPage.route,
    builder: (context, state) {
      return const AllCustomersPage();
    },
  ),
  GoRoute(
    path: '/customer/register',
    name: CustomerRegisterPage.route,
    builder: (context, state) {
      return const CustomerRegisterPage();
    },
  ),
  GoRoute(
    path: '/customer/:id',
    name: CustomerDetailPage.route,
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
      return CustomerDetailPage(customerId: id);
    },
  ),
  GoRoute(
    path: '/device/register',
    name: DeviceRegisterPage.route,
    builder: (context, state) {
      final customerId = int.tryParse(
        state.uri.queryParameters['customerId'] ?? '',
      );
      final customerName = state.uri.queryParameters['customerName'];

      return DeviceRegisterPage(
        customerId: customerId,
        customerName: customerName,
      );
    },
  ),
  GoRoute(
    path: '/device/all',
    name: AllDevicesPage.route,
    builder: (context, state) {
      final filter = state.extra as DeviceFilter?;
      return AllDevicesPage(filter: filter);
    },
  ),
  GoRoute(
    path: '/device/search',
    name: SearchDevicesPage.route,
    builder: (context, state) {
      final filter = state.extra as DeviceSearchFilter?;
      return SearchDevicesPage(filter: filter);
    },
  ),
  GoRoute(
    path: '/device/:id',
    name: DeviceDetailsPage.route,
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
      return DeviceDetailsPage(deviceId: id);
    },
  ),
];
