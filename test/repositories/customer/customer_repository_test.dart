import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/services/customer/customer_service.dart';

import '../../support/fixtures/customer_fixture.dart';
import '../../support/fixtures/page_fixture.dart';

class _FakeCustomerService extends Fake implements CustomerService {
  InputCustomer? lastCreatedInput;
  int? lastRequestedId;
  (int, InputCustomer)? lastUpdateArgs;
  CustomerSearchFilter? lastSearchFilter;

  Result<CustomerModel> createResult = Ok(makeCustomerModel(customerId: 10));
  Result<CustomerModel> getResult = Ok(makeCustomerModel(customerId: 5));
  Result<CustomerModel> updateResult = Ok(
    makeCustomerModel(customerId: 5, name: 'Atualizado'),
  );
  Result<Page<MinifiedCustomerModel>> searchResult = Ok(
    makePage([makeMinifiedCustomer(customerId: 1)]),
  );

  @override
  Future<Result<CustomerModel>> createCustomer(InputCustomer customer) async {
    lastCreatedInput = customer;
    return createResult;
  }

  @override
  Future<Result<CustomerModel>> getCustomer(int customerId) async {
    lastRequestedId = customerId;
    return getResult;
  }

  @override
  Future<Result<CustomerModel>> updateCustomer(
    int customerId,
    InputCustomer customer,
  ) async {
    lastUpdateArgs = (customerId, customer);
    return updateResult;
  }

  @override
  Future<Result<Page<MinifiedCustomerModel>>> searchCustomers(
    CustomerSearchFilter? filter,
  ) async {
    lastSearchFilter = filter;
    return searchResult;
  }
}

void main() {
  late _FakeCustomerService service;
  late CustomerRepository repository;

  setUp(() {
    service = _FakeCustomerService();
    repository = CustomerRepository(service);
  });

  group('CustomerRepository', () {
    test('createCustomer delegates to service and returns Result', () async {
      final input = InputCustomer.empty();
      final result = await repository.createCustomer(input);

      expect(service.lastCreatedInput, same(input));
      expect(result.valueOrNull?.customerId, 10);
    });

    test('getCustomer forwards id and propagates Err', () async {
      service.getResult = const Err(NetworkFailure());
      final result = await repository.getCustomer(5);

      expect(service.lastRequestedId, 5);
      expect(result, isA<Err<CustomerModel>>());
    });

    test('updateCustomer forwards id and payload', () async {
      final input = InputCustomer.empty();
      final result = await repository.updateCustomer(5, input);

      expect(service.lastUpdateArgs, (5, input));
      expect(result.valueOrNull?.name, 'Atualizado');
    });

    test('searchCustomers forwards filter and returns Page', () async {
      final filter = CustomerSearchFilter(searchName: 'Maria', page: 1);
      final result = await repository.searchCustomers(filter);

      expect(service.lastSearchFilter, same(filter));
      expect(result.valueOrNull?.content.single.customerId, 1);
    });
  });
}
