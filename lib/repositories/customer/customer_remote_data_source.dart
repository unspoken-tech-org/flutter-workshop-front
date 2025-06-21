import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/services/customer/customer_service.dart';

class CustomerRemoteDataSource implements CustomerRepository {
  final CustomerService _customerService = CustomerService();
  @override
  Future<CustomerModel> saveCustomer(InputCustomer customer) async {
    final response = await _customerService.saveCustomer(customer);
    return response;
  }

  @override
  Future<CustomerModel> getCustomer(int customerId) async {
    final response = await _customerService.getCustomer(customerId);
    return response;
  }

  @override
  Future<CustomerModel> updateCustomer(
      int customerId, InputCustomer customer) async {
    final response =
        await _customerService.updateCustomer(customerId, customer);
    return response;
  }

  @override
  Future<List<MinifiedCustomerModel>> searchCustomers(
      CustomerSearchFilter? filter) async {
    final response = await _customerService.searchCustomers(filter);
    return response;
  }
}
