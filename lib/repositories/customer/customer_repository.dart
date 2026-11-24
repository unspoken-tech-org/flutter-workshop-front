import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

abstract class CustomerRepository {
  Future<Result<CustomerModel>> createCustomer(InputCustomer customer);
  Future<Result<CustomerModel>> getCustomer(int customerId);
  Future<Result<CustomerModel>> updateCustomer(
    int customerId,
    InputCustomer customer,
  );
  Future<Result<Page<MinifiedCustomerModel>>> searchCustomers(
    CustomerSearchFilter? filter,
  );
}
