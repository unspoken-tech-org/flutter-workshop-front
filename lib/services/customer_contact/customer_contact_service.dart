import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';

class CustomerContactService {
  CustomerContactService({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  Future<Result<void>> createCustomerContact(
    InputCustomerContact customerContact,
  ) {
    return _api.send(
      (dio) => dio.post<dynamic>(
        '/v1/customer-contact',
        data: customerContact.toJson(),
      ),
      expectedStatus: {200, 201, 204},
      decode: (_) {},
    );
  }

  Future<Result<void>> updateCustomerContact(
    int id,
    InputCustomerContact customerContact,
  ) {
    return _api.send(
      (dio) => dio.put<dynamic>(
        '/v1/customer-contact/$id',
        data: customerContact.toJson(),
      ),
      expectedStatus: {200, 201, 204},
      decode: (_) {},
    );
  }
}
