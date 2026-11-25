import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/services/customer/customer_service.dart';

class CustomerRepository {
  CustomerRepository(this._customerService);

  final CustomerService _customerService;

  Future<Result<CustomerModel>> createCustomer(InputCustomer customer) =>
      _customerService.createCustomer(customer);

  Future<Result<CustomerModel>> getCustomer(int customerId) =>
      _customerService.getCustomer(customerId);

  Future<Result<CustomerModel>> updateCustomer(
    int customerId,
    InputCustomer customer,
  ) => _customerService.updateCustomer(customerId, customer);

  Future<Result<Page<MinifiedCustomerModel>>> searchCustomers(
    CustomerSearchFilter? filter,
  ) => _customerService.searchCustomers(filter);
}
