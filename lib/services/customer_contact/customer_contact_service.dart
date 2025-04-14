import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';

class CustomerContactService {
  final Dio _dio = Dio();

  Future<void> createCustomerContact(
      InputCustomerContact customerContact) async {
    final response = await _dio.post(
        'http://localhost:8080/v1/customer-contact',
        data: customerContact.toJson());
    return response.data;
  }
}
