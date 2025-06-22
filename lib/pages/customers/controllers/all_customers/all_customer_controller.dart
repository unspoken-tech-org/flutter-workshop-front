import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/debouncer.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_remote_data_source.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/utils/filter_utils.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class AllCustomerController extends ChangeNotifier {
  final CustomerRepository _customerRepository = CustomerRemoteDataSource();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  List<MinifiedCustomerModel> _customers = [];
  List<MinifiedCustomerModel> get customers => _customers;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AllCustomerController() {
    searchCustomers(null);
  }

  Future<void> searchCustomers(String? searchTerm) async {
    CustomerSearchFilter? filter = getCustomerSearchFilter(searchTerm);

    _debouncer.run(() async {
      _isLoading = true;
      notifyListeners();

      try {
        _customers = await _customerRepository.searchCustomers(filter);
      } catch (e) {
        SnackBarUtil().showError('Erro ao buscar clientes. Tente novamente.');
        _customers = [];
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }
}

CustomerSearchFilter? getCustomerSearchFilter(String? searchTerm) {
  FilterUtils filterUtils = FilterUtils(searchTerm ?? '');

  if (filterUtils.isId) {
    return CustomerSearchFilter(id: int.parse(searchTerm ?? ''));
  } else if (filterUtils.isName) {
    return CustomerSearchFilter(name: searchTerm);
  } else if (filterUtils.isCpf) {
    return CustomerSearchFilter(cpf: searchTerm);
  } else if (filterUtils.isPhoneOrCellPhone) {
    return CustomerSearchFilter(phone: searchTerm);
  }

  return null;
}
