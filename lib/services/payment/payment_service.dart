import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';

class PaymentService {
  PaymentService(this._api);

  final ApiClient _api;

  Future<Result<void>> createPayment(InputPayment payment) {
    return _api.send(
      (dio) => dio.post<dynamic>('/v1/payment', data: {...payment.toJson()}),
      expectedStatus: {200, 201, 204},
      decode: (_) {},
    );
  }
}
