import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';

class PaymentService {
  final Dio _dio = CustomDio.dioInstance();

  Future<void> createPayment(
    InputPayment payment,
  ) async {
    final json = {
      ...payment.toJson(),
    };

    final response = await _dio.post('/v1/payment', data: json);
    return response.data;
  }
}
