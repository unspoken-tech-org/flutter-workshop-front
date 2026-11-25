import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart'
    show OrderBy;
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';
import 'package:flutter_workshop_front/utils/filter_utils.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class SearchDevicesController extends ChangeNotifier {
  final AllDevicesRepository _allDevicesRepository;

  SearchDevicesController(
    this._allDevicesRepository, {
    DeviceSearchFilter? filter,
  }) {
    this.filter = filter ?? DeviceSearchFilter();
    unawaited(searchDevices());
  }

  List<DeviceDataTable> devices = [];
  late DeviceSearchFilter filter;

  bool isLoading = false;
  bool isFiltering = false;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  bool _loadMoreFailed = false;
  bool get loadMoreFailed => _loadMoreFailed;

  int _currentPage = 0;
  int _totalElements = 0;
  int get totalElements => _totalElements;
  int _totalPages = 0;
  int get totalPages => _totalPages;
  int _requestGeneration = 0;

  Future<void> searchDevices() async {
    final generation = ++_requestGeneration;
    try {
      isLoading = true;
      _isLoadingMore = false;
      _loadMoreFailed = false;
      _currentPage = 0;
      filter.page = _currentPage;
      devices = [];
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (generation != _requestGeneration) return;
      final result = await _allDevicesRepository.searchDevices(filter);
      if (generation != _requestGeneration) return;
      switch (result) {
        case Ok(:final value):
          devices = value.content;
          _totalElements = value.totalElements;
          _totalPages = value.totalPages;
          _hasMore = !value.last;
        case Err(:final failure):
          devices = [];
          _totalElements = 0;
          _totalPages = 0;
          _hasMore = false;
          SnackBarUtil().showError(
            failure.messageOr('Erro ao buscar aparelhos'),
          );
      }
    } finally {
      if (generation == _requestGeneration) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void toggleFiltering() {
    isFiltering = !isFiltering;
    notifyListeners();
  }

  void filterTable(String searchTerm) {
    filter = filter.clearSearchQuery();
    filter.customerCpf = null;
    filter.customerPhone = null;
    filter.deviceId = null;

    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      unawaited(searchDevices());
      return;
    }

    final search = FilterUtils(trimmed);
    if (search.isCpf) {
      filter.customerCpf = search.digits;
    } else if (search.isPhoneOrCellPhone) {
      filter.customerPhone = search.digits;
    } else if (search.isId) {
      filter.deviceId = int.parse(search.digits);
    } else {
      filter = filter.withSearchQuery(search.text);
    }
    unawaited(searchDevices());
  }

  void addRemoveStatus(StatusEnum status) {
    filter = filter.withToggledStatus(status);
    notifyListeners();
    unawaited(searchDevices());
  }

  void toggleUrgency() {
    filter = filter.withToggledUrgency();
    notifyListeners();
    unawaited(searchDevices());
  }

  void toggleRevision() {
    filter = filter.withToggledRevision();
    notifyListeners();
    unawaited(searchDevices());
  }

  void addRemoveEnterRangeDate(DateTime? initialDate, DateTime? endDate) {
    filter = filter.withRangeDate(initialDate, endDate);
    notifyListeners();
    unawaited(searchDevices());
  }

  void toggleOrderBy(OrderBy orderBy) {
    filter = filter.withToggledOrderBy(orderBy);
    notifyListeners();
    unawaited(searchDevices());
  }

  void clearOrderBy() {
    filter = filter.clearOrderBy();
    notifyListeners();
    unawaited(searchDevices());
  }

  Future<void> clearSearch() async {
    filter = filter.clearSearchQuery();
    filter.customerCpf = null;
    filter.customerPhone = null;
    filter.deviceId = null;
    await searchDevices();
  }

  Future<void> clearFilters() async {
    filter = filter.clearSelectableFilters();
    await searchDevices();
  }

  Future<void> loadMore() async {
    if (isLoading || _isLoadingMore || !_hasMore || _loadMoreFailed) return;

    final generation = _requestGeneration;
    try {
      _isLoadingMore = true;
      _loadMoreFailed = false;
      notifyListeners();

      _currentPage++;
      filter.page = _currentPage;

      final result = await _allDevicesRepository.searchDevices(filter);
      if (generation != _requestGeneration) return;
      switch (result) {
        case Ok(:final value):
          devices.addAll(value.content);
          _totalPages = value.totalPages;
          _hasMore = !value.last;
        case Err(:final failure):
          _currentPage--;
          _loadMoreFailed = true;
          SnackBarUtil().showError(
            failure.messageOr('Erro ao buscar mais aparelhos'),
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
