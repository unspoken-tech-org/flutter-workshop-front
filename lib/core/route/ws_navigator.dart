import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/all_customers_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/customer_detail_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/customer_register_page.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/all_devices_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/device_details_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/device_register_page.dart';
import 'package:flutter_workshop_front/pages/home/home.dart';
import 'package:go_router/go_router.dart';

class WsNavigator {
  static void pushHome(BuildContext context) {
    context.goNamed(HomePage.route);
  }

  static void pushCustomers(BuildContext context) {
    context.pushNamed(AllCustomersPage.route);
  }

  static void pushCustomerDetail(BuildContext context, int customerId,
      {bool replaced = false}) {
    if (replaced) {
      context.pushReplacementNamed(CustomerDetailPage.route,
          pathParameters: {'id': customerId.toString()});
    } else {
      context.pushNamed(CustomerDetailPage.route,
          pathParameters: {'id': customerId.toString()});
    }
  }

  static void pushCustomerRegister(BuildContext context) {
    context.pushNamed(CustomerRegisterPage.route);
  }

  static Future<void> pushDeviceDetails(BuildContext context, int deviceId,
      {bool replaced = false}) async {
    if (replaced) {
      context.pushReplacementNamed(DeviceDetailsPage.route,
          pathParameters: {'id': deviceId.toString()});
    } else {
      await context.pushNamed(DeviceDetailsPage.route,
          pathParameters: {'id': deviceId.toString()});
    }
  }

  static void pushAllDevices(BuildContext context,
      {bool replaced = false, DeviceFilter? filter}) {
    if (replaced) {
      context.pushReplacementNamed(AllDevicesPage.route, extra: filter);
    } else {
      context.pushNamed(AllDevicesPage.route, extra: filter);
    }
  }

  static void pushDeviceRegister(BuildContext context,
      {int? customerId, String? customerName}) {
    context.pushNamed(DeviceRegisterPage.route, queryParameters: {
      'customerId': customerId.toString(),
      'customerName': customerName,
    });
  }
}
