import 'dart:async';

import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/state/paged_list_controller.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

/// Customer listing; the query is the typed search term (`null` = no search).
class AllCustomerController
    extends PagedListController<MinifiedCustomerModel, String?> {
  static const int _pageSize = 10;

  AllCustomerController({required CustomerRepository customerRepository})
    : super(
        initialQuery: null,
        fetch: (searchTerm, page) => customerRepository.searchCustomers(
          CustomerSearchFilter.getCustomerSearchFilter(
                searchTerm,
                page: page,
                size: _pageSize,
              ) ??
              CustomerSearchFilter(page: page, size: _pageSize),
        ),
        onFailure: (failure, {required loadingMore}) {
          // Mantém a mensagem fixa de hoje na primeira página, também para
          // erros da API.
          SnackBarUtil().showError(
            loadingMore
                ? failure.messageOr('Erro ao buscar mais clientes')
                : 'Erro ao buscar clientes. Tente novamente.',
          );
        },
      );

  List<MinifiedCustomerModel> get customers => items;

  Future<void> searchCustomers(String? searchTerm) => updateQuery(searchTerm);
}
