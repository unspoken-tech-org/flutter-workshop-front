import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_remote_data_source.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class AllCustomerController extends ChangeNotifier {
  static const int _pageSize = 10;

  final CustomerRepository _customerRepository;

  CustomerSearchFilter? filter;
  List<MinifiedCustomerModel> _customers = [];
  List<MinifiedCustomerModel> get customers => _customers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  int _totalElements = 0;
  int get totalElements => _totalElements;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _loadMoreFailed = false;
  bool get loadMoreFailed => _loadMoreFailed;

  int _requestGeneration = 0;

  AllCustomerController({CustomerRepository? customerRepository})
    : _customerRepository = customerRepository ?? CustomerRemoteDataSource() {
    unawaited(searchCustomers(null));
  }

  Future<void> searchCustomers(String? searchTerm) async {
    final generation = ++_requestGeneration;
    _currentPage = 0;
    _hasMore = true;
    _loadMoreFailed = false;
    _isLoadingMore = false;

    filter =
        CustomerSearchFilter.getCustomerSearchFilter(
          searchTerm,
          page: _currentPage,
          size: _pageSize,
        ) ??
        CustomerSearchFilter(page: _currentPage, size: _pageSize);

    _isLoading = true;
    notifyListeners();

    try {
      final page = await _customerRepository.searchCustomers(filter);
      if (generation != _requestGeneration) return;
      _customers = page.content;
      _currentPage = page.number;
      _totalElements = page.totalElements;
      _hasMore = !page.last;
    } catch (e) {
      if (generation != _requestGeneration) return;
      SnackBarUtil().showError('Erro ao buscar clientes. Tente novamente.');
      _customers = [];
      _hasMore = false;
    } finally {
      if (generation == _requestGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _loadMoreFailed) return;

    final generation = _requestGeneration;
    try {
      _isLoadingMore = true;
      _loadMoreFailed = false;
      notifyListeners();

      _currentPage++;
      filter = (filter ?? CustomerSearchFilter(size: _pageSize)).copyWith(
        page: _currentPage,
      );

      final Page<MinifiedCustomerModel> result = await _customerRepository
          .searchCustomers(filter);
      if (generation != _requestGeneration) return;
      _customers.addAll(result.content);
      _totalElements = result.totalElements;
      _hasMore = !result.last;
    } on RequisitionException catch (e) {
      if (generation != _requestGeneration) return;
      _currentPage--;
      _loadMoreFailed = true;
      SnackBarUtil().showError(e.message);
    } on Exception catch (_) {
      if (generation != _requestGeneration) return;
      _currentPage--;
      _loadMoreFailed = true;
      SnackBarUtil().showError("Erro ao buscar mais clientes");
    } finally {
      if (generation == _requestGeneration) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryLoadMore() {
    _loadMoreFailed = false;
    notifyListeners();
    return loadMore();
  }
}
