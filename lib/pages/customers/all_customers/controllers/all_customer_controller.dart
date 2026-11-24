import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
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
      final result = await _customerRepository.searchCustomers(filter);
      if (generation != _requestGeneration) return;
      switch (result) {
        case Ok(:final value):
          _customers = value.content;
          _currentPage = value.number;
          _totalElements = value.totalElements;
          _hasMore = !value.last;
        case Err():
          // Mantém a mensagem fixa de hoje, também para erros da API.
          SnackBarUtil().showError('Erro ao buscar clientes. Tente novamente.');
          _customers = [];
          _hasMore = false;
      }
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

      final result = await _customerRepository.searchCustomers(filter);
      if (generation != _requestGeneration) return;
      switch (result) {
        case Ok(:final value):
          _customers.addAll(value.content);
          _totalElements = value.totalElements;
          _hasMore = !value.last;
        case Err(:final failure):
          _currentPage--;
          _loadMoreFailed = true;
          SnackBarUtil().showError(
            failure.messageOr('Erro ao buscar mais clientes'),
          );
      }
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
