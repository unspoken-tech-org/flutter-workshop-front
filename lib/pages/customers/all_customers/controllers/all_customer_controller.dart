import 'package:flutter/material.dart' hide Page;
import 'package:flutter_workshop_front/core/debouncer.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_remote_data_source.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class AllCustomerController extends ChangeNotifier {
  final CustomerRepository _customerRepository = CustomerRemoteDataSource();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  CustomerSearchFilter? filter;
  List<MinifiedCustomerModel> _customers = [];
  List<MinifiedCustomerModel> get customers => _customers;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  int _totalElements = 0;
  int get totalElements => _totalElements;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  AllCustomerController() {
    searchCustomers(null);
  }

  Future<void> searchCustomers(String? searchTerm) async {
    _currentPage = 0;
    _hasMore = true;

    filter = CustomerSearchFilter.getCustomerSearchFilter(
      searchTerm,
      page: _currentPage,
      size: 10,
    );

    _debouncer.run(() async {
      _isLoading = true;
      notifyListeners();

      try {
        final page = await _customerRepository.searchCustomers(filter);
        _customers = page.content;
        _currentPage = page.number;
        _totalElements = page.totalElements;
        _hasMore = !page.last;
      } catch (e) {
        SnackBarUtil().showError('Erro ao buscar clientes. Tente novamente.');
        _customers = [];
        _hasMore = false;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      _currentPage++;
      filter = filter?.copyWith(page: _currentPage);

      final Page<MinifiedCustomerModel> result =
          await _customerRepository.searchCustomers(filter);
      _customers.addAll(result.content);
      _totalElements = result.totalElements;
      _hasMore = !result.last;
    } on RequisitionException catch (e) {
      _currentPage--;
      SnackBarUtil().showError(e.message);
    } on Exception catch (_) {
      _currentPage--;
      SnackBarUtil().showError("Erro ao buscar mais clientes");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
