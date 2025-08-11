import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';

class CustomerContactService {
  final Dio _dio = CustomDio.dioInstance();

  Future<void> createCustomerContact(
    InputCustomerContact customerContact,
  ) async {
    final json = customerContact.toJson();

    final response = await _dio.post(
      '/v1/customer-contact',
      data: json,
    );
    return response.data;
  }
}
