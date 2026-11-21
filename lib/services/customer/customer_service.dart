import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

class CustomerService {
  final Dio _dio = CustomDio.dioInstance();

  Future<CustomerModel> createCustomer(InputCustomer customer) async {
    final json = customer.toJson();

    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/customer',
      data: json,
    );

    if ([200, 201].contains(response.statusCode)) {
      return CustomerModel.fromJson(response.data!);
    } else {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }
  }

  Future<CustomerModel> getCustomer(int customerId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/customer/$customerId',
    );

    if ([200].contains(response.statusCode)) {
      return CustomerModel.fromJson(response.data!);
    } else {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }
  }

  Future<CustomerModel> updateCustomer(
    int customerId,
    InputCustomer customer,
  ) async {
    final json = customer.toJson();

    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/customer/$customerId',
      data: json,
    );

    if ([200].contains(response.statusCode)) {
      return CustomerModel.fromJson(response.data!);
    } else {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }
  }

  Future<Page<MinifiedCustomerModel>> searchCustomers(
    CustomerSearchFilter? filter,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/customer/search',
      data: filter?.toJson() ?? <String, dynamic>{},
    );

    if ([200].contains(response.statusCode)) {
      return Page.fromJson(
        response.data!,
        (customer) =>
            MinifiedCustomerModel.fromJson(customer as Map<String, dynamic>),
      );
    } else {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }
  }
}
