import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';

/// Fake tipado de [CustomerRepository] para testes unitários e de widget.
class FakeCustomerRepository extends Fake implements CustomerRepository {
  FakeCustomerRepository({
    this.onCreateCustomer,
    this.createCustomerResult,
    this.onGetCustomer,
    this.getCustomerResult,
    this.onUpdateCustomer,
    this.updateCustomerResult,
    this.onSearchCustomers,
    this.searchCustomersResult,
  });

  Future<Result<CustomerModel>> Function(InputCustomer customer)?
  onCreateCustomer;
  Result<CustomerModel>? createCustomerResult;
  final List<InputCustomer> createdCustomers = [];
  int createCalls = 0;

  Future<Result<CustomerModel>> Function(int customerId)? onGetCustomer;
  Result<CustomerModel>? getCustomerResult;
  final List<int> requestedCustomerIds = [];
  int getCalls = 0;

  Future<Result<CustomerModel>> Function(
    int customerId,
    InputCustomer customer,
  )?
  onUpdateCustomer;
  Result<CustomerModel>? updateCustomerResult;
  int updateCalls = 0;

  Future<Result<Page<MinifiedCustomerModel>>> Function(
    CustomerSearchFilter? filter,
  )?
  onSearchCustomers;
  Result<Page<MinifiedCustomerModel>>? searchCustomersResult;
  final List<CustomerSearchFilter?> recordedSearchFilters = [];

  @override
  Future<Result<CustomerModel>> createCustomer(InputCustomer customer) async {
    createCalls++;
    createdCustomers.add(customer);
    if (onCreateCustomer != null) {
      return onCreateCustomer!(customer);
    }
    if (createCustomerResult != null) {
      return createCustomerResult!;
    }
    throw UnimplementedError(
      'FakeCustomerRepository.createCustomer not configured',
    );
  }

  @override
  Future<Result<CustomerModel>> getCustomer(int customerId) async {
    getCalls++;
    requestedCustomerIds.add(customerId);
    if (onGetCustomer != null) {
      return onGetCustomer!(customerId);
    }
    if (getCustomerResult != null) {
      return getCustomerResult!;
    }
    throw UnimplementedError(
      'FakeCustomerRepository.getCustomer not configured',
    );
  }

  @override
  Future<Result<CustomerModel>> updateCustomer(
    int customerId,
    InputCustomer customer,
  ) async {
    updateCalls++;
    if (onUpdateCustomer != null) {
      return onUpdateCustomer!(customerId, customer);
    }
    if (updateCustomerResult != null) {
      return updateCustomerResult!;
    }
    throw UnimplementedError(
      'FakeCustomerRepository.updateCustomer not configured',
    );
  }

  @override
  Future<Result<Page<MinifiedCustomerModel>>> searchCustomers(
    CustomerSearchFilter? filter,
  ) async {
    recordedSearchFilters.add(filter);
    if (onSearchCustomers != null) {
      return onSearchCustomers!(filter);
    }
    if (searchCustomersResult != null) {
      return searchCustomersResult!;
    }
    throw UnimplementedError(
      'FakeCustomerRepository.searchCustomers not configured',
    );
  }
}
