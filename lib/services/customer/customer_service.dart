import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';

class CustomerService {
  final Dio _dio = CustomDio.dioInstance();

  Future<CustomerModel> createCustomer(InputCustomer customer) async {
    final json = customer.toJson();

    final response = await _dio.post(
      '/v1/customer',
      data: json,
    );

    if ([200, 201].contains(response.statusCode)) {
      return CustomerModel.fromJson(response.data);
    } else {
      throw RequisitionException.fromJson(response.data['error']);
    }
  }

  Future<CustomerModel> getCustomer(int customerId) async {
    final response = await _dio.get(
      '/v1/customer/$customerId',
    );

    if ([200].contains(response.statusCode)) {
      return CustomerModel.fromJson(response.data);
    } else {
      throw RequisitionException.fromJson(response.data['error']);
    }
  }

  Future<CustomerModel> updateCustomer(
      int customerId, InputCustomer customer) async {
    final json = customer.toJson();

    final response = await _dio.put(
      '/v1/customer/$customerId',
      data: json,
    );

    if ([200].contains(response.statusCode)) {
      return CustomerModel.fromJson(response.data);
    } else {
      throw RequisitionException.fromJson(response.data['error']);
    }
  }

  Future<List<MinifiedCustomerModel>> searchCustomers(
      CustomerSearchFilter? filter) async {
    final response = await _dio.post(
      '/v1/customer/search',
      data: filter?.toJson(),
    );

    if ([200].contains(response.statusCode)) {
      return (response.data as List)
          .map((customer) => MinifiedCustomerModel.fromJson(customer))
          .toList();
    } else {
      throw RequisitionException.fromJson(response.data['error']);
    }
  }
}
