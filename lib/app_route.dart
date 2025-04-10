import 'package:flutter_workshop_front/pages/device_customer/customer_device_page.dart';
import 'package:flutter_workshop_front/pages/customers/customers_page.dart';
import 'package:flutter_workshop_front/pages/home/home.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(initialLocation: '/', routes: _routes);

List<RouteBase> _routes = [
  GoRoute(
    path: '/',
    name: 'home',
    builder: (context, state) {
      return const HomePage();
    },
  ),
  GoRoute(
    path: '/customers',
    name: 'customers',
    builder: (context, state) {
      return const CustomersPage();
    },
  ),
  GoRoute(
    path: '/device/:id',
    name: 'device',
    builder: (context, state) {
      var id = int.parse(state.pathParameters['id'] ?? '0');
      return CustomerDevicePage(deviceId: id);
    },
  ),
];
