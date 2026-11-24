import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';
import 'package:flutter_workshop_front/utils/filter_utils.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class AllDevicesController extends ChangeNotifier with SafeChangeNotifierMixin {
  final AllDevicesRepository _allDevicesRepository;

  AllDevicesController(this._allDevicesRepository, {DeviceFilter? filter}) {
    this.filter = filter ?? DeviceFilter();
    unawaited(fetchAllDevicesFiltering());
    unawaited(fetchFilterOptions());
  }

  List<DeviceDataTable> devices = [];
  List<DeviceType> deviceTypes = [];
  List<DeviceBrand> deviceBrands = [];
  late DeviceFilter filter;

  bool isLoading = false;
  bool isFiltering = false;
  bool isFiltersLoading = false;
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

  Future<void> fetchAllDevicesFiltering() async {
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
      final result = await _allDevicesRepository.getAllDevicesFiltering(filter);
      if (generation != _requestGeneration) return;
      switch (result) {
        case Ok(:final value):
          devices = value.content;
          _totalElements = value.totalElements;
          _totalPages = value.totalPages;
          _hasMore = !value.last;
        case Err(:final failure):
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

  Future<void> fetchFilterOptions() async {
    if (isFiltersLoading) return;
    try {
      isFiltersLoading = true;
      notifyListeners();
      final (resultTypes, resultBrands) = await (
        _allDevicesRepository.getAllDeviceTypes(),
        _allDevicesRepository.getAllDeviceBrands(),
      ).wait;
      final failure = switch ((resultTypes, resultBrands)) {
        (Err(:final failure), _) => failure,
        (_, Err(:final failure)) => failure,
        _ => null,
      };
      if (failure != null) {
        SnackBarUtil().showError(failure.messageOr('Erro ao carregar filtros'));
      } else {
        deviceTypes = resultTypes.valueOrNull ?? deviceTypes;
        deviceBrands = resultBrands.valueOrNull ?? deviceBrands;
      }
    } finally {
      isFiltersLoading = false;
      notifyListeners();
    }
  }

  void toggleFiltering() {
    isFiltering = !isFiltering;
    notifyListeners();
  }

  void filterTable(String searchTerm) {
    filter = filter.clearTypedFilters();

    final search = FilterUtils(searchTerm);
    if (search.isName) {
      filter.customerName = search.text;
    } else if (search.isCpf) {
      filter.customerCpf = search.digits;
    } else if (search.isPhoneOrCellPhone) {
      filter.customerPhone = search.digits;
    } else if (search.isId) {
      filter.deviceId = int.parse(search.digits);
    }
    unawaited(fetchAllDevicesFiltering());
  }

  void addRemoveDeviceType(DeviceType deviceType) {
    filter = filter.withToggledType(deviceType);
    notifyListeners();
    unawaited(fetchAllDevicesFiltering());
  }

  void addRemoveDeviceBrand(DeviceBrand deviceBrand) {
    filter = filter.withToggledBrand(deviceBrand);
    notifyListeners();
    unawaited(fetchAllDevicesFiltering());
  }

  void addRemoveStatus(StatusEnum status) {
    filter = filter.withToggledStatus(status);
    notifyListeners();
    unawaited(fetchAllDevicesFiltering());
  }

  void toggleUrgency() {
    filter = filter.withToggledUrgency();
    notifyListeners();
    unawaited(fetchAllDevicesFiltering());
  }

  void toggleRevision() {
    filter = filter.withToggledRevision();
    notifyListeners();
    unawaited(fetchAllDevicesFiltering());
  }

  void addRemoveEnterRangeDate(DateTime? initialDate, DateTime? endDate) {
    filter = filter.withRangeDate(initialDate, endDate);
    notifyListeners();
    unawaited(fetchAllDevicesFiltering());
  }

  void toggleOrderBy(OrderBy orderBy) {
    filter = filter.withToggledOrderBy(orderBy);
    notifyListeners();
    unawaited(fetchAllDevicesFiltering());
  }

  void clearOrderBy() {
    filter = filter.clearOrderBy();
    notifyListeners();
    unawaited(fetchAllDevicesFiltering());
  }

  Future<void> clearSearch() async {
    filter = filter.clearTypedFilters();
    await fetchAllDevicesFiltering();
  }

  Future<void> clearFilters() async {
    filter = filter.clearSelectableFilters();
    await fetchAllDevicesFiltering();
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

      final result = await _allDevicesRepository.getAllDevicesFiltering(filter);
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
