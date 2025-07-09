import 'package:flutter_workshop_front/pages/device_customer/customer_device_page.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers_page.dart';
import 'package:flutter_workshop_front/pages/device/device_register_page.dart';
import 'package:flutter_workshop_front/pages/home/home.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register_page.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(initialLocation: '/', routes: _routes);

List<RouteBase> _routes = [
  GoRoute(
    path: '/',
    name: HomePage.route,
    builder: (context, state) {
      return const HomePage();
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
      var id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
      return CustomerDetailPage(customerId: id);
    },
  ),
  GoRoute(
    path: '/device/:id',
    name: CustomerDevicePage.route,
    builder: (context, state) {
      var id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
      return CustomerDevicePage(deviceId: id);
    },
  ),
];
