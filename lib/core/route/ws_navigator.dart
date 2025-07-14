import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register_page.dart';
import 'package:flutter_workshop_front/pages/device_customer/customer_device_page.dart';
import 'package:flutter_workshop_front/pages/device/device_register_page.dart';
import 'package:flutter_workshop_front/pages/home/home.dart';
import 'package:go_router/go_router.dart';

class WsNavigator {
  static void pushHome(BuildContext context) {
    context.goNamed(HomePage.route);
  }

  static void pushCustomers(BuildContext context) {
    context.pushNamed(AllCustomersPage.route);
  }

  static void pushCustomerDetail(BuildContext context, int customerId) {
    context.pushNamed(CustomerDetailPage.route,
        pathParameters: {'id': customerId.toString()});
  }

  static void pushCustomerRegister(BuildContext context) {
    context.pushNamed(CustomerRegisterPage.route);
  }

  static void pushDevice(BuildContext context, int deviceId) {
    context.pushNamed(CustomerDevicePage.route,
        pathParameters: {'id': deviceId.toString()});
  }

  static void pushDeviceRegister(
      BuildContext context, int customerId, String customerName) {
    context.pushNamed(DeviceRegisterPage.route, pathParameters: {
      'customerId': customerId.toString(),
      'customerName': customerName,
    });
  }
}
