import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

class CustomerService {
  CustomerService({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  Future<Result<CustomerModel>> createCustomer(InputCustomer customer) {
    return _api.send(
      (dio) => dio.post<dynamic>('/v1/customer', data: customer.toJson()),
      expectedStatus: {200, 201},
      decode: (data) => CustomerModel.fromJson(asJsonMap(data)),
    );
  }

  Future<Result<CustomerModel>> getCustomer(int customerId) {
    return _api.send(
      (dio) => dio.get<dynamic>('/v1/customer/$customerId'),
      decode: (data) => CustomerModel.fromJson(asJsonMap(data)),
    );
  }

  Future<Result<CustomerModel>> updateCustomer(
    int customerId,
    InputCustomer customer,
  ) {
    return _api.send(
      (dio) =>
          dio.put<dynamic>('/v1/customer/$customerId', data: customer.toJson()),
      decode: (data) => CustomerModel.fromJson(asJsonMap(data)),
    );
  }

  Future<Result<Page<MinifiedCustomerModel>>> searchCustomers(
    CustomerSearchFilter? filter,
  ) {
    return _api.send(
      (dio) => dio.post<dynamic>(
        '/v1/customer/search',
        data: filter?.toJson() ?? <String, dynamic>{},
      ),
      decode: (data) => Page.fromJson(
        asJsonMap(data),
        (customer) =>
            MinifiedCustomerModel.fromJson(customer as Map<String, dynamic>),
      ),
    );
  }
}
