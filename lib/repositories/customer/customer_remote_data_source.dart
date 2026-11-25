import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/services/customer/customer_service.dart';

class CustomerRemoteDataSource implements CustomerRepository {
  CustomerRemoteDataSource(this._customerService);

  final CustomerService _customerService;

  @override
  Future<Result<CustomerModel>> createCustomer(InputCustomer customer) {
    return _customerService.createCustomer(customer);
  }

  @override
  Future<Result<CustomerModel>> getCustomer(int customerId) {
    return _customerService.getCustomer(customerId);
  }

  @override
  Future<Result<CustomerModel>> updateCustomer(
    int customerId,
    InputCustomer customer,
  ) {
    return _customerService.updateCustomer(customerId, customer);
  }

  @override
  Future<Result<Page<MinifiedCustomerModel>>> searchCustomers(
    CustomerSearchFilter? filter,
  ) {
    return _customerService.searchCustomers(filter);
  }
}
