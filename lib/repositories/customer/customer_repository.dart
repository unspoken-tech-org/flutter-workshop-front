import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';

abstract class CustomerRepository {
  Future<CustomerModel> saveCustomer(InputCustomer customer);
  Future<CustomerModel> getCustomer(int customerId);
  Future<CustomerModel> updateCustomer(int customerId, InputCustomer customer);
  Future<List<MinifiedCustomerModel>> searchCustomers(
      CustomerSearchFilter? filter);
}
