import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WsNavigator {
  static void pushHome(BuildContext context) {
    context.goNamed('home');
  }

  static void pushCustomers(BuildContext context) {
    context.goNamed('customers');
  }

  static void pushCustomerDetail(BuildContext context, int customerId) {
    context.goNamed('customer_detail',
        pathParameters: {'id': customerId.toString()});
  }

  static void pushCustomerRegister(BuildContext context) {
    context.goNamed('customer_register');
  }

  static void pushDevice(BuildContext context, int deviceId) {
    context.goNamed('device', pathParameters: {'id': deviceId.toString()});
  }
}
