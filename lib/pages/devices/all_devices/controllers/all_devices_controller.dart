import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';
import 'package:flutter_workshop_front/utils/filter_utils.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class AllDevicesController extends ChangeNotifier {
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
      final Page<DeviceDataTable> result = await _allDevicesRepository
          .getAllDevicesFiltering(filter);
      if (generation != _requestGeneration) return;
      devices = result.content;
      _totalElements = result.totalElements;
      _totalPages = result.totalPages;
      _hasMore = !result.last;
    } on RequisitionException catch (e) {
      if (generation != _requestGeneration) return;
      SnackBarUtil().showError(e.message);
    } on Exception catch (_) {
      if (generation != _requestGeneration) return;
      SnackBarUtil().showError("Erro ao buscar aparelhos");
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
      deviceTypes = resultTypes;
      deviceBrands = resultBrands;
    } on ParallelWaitError<
      (List<DeviceType>?, List<DeviceBrand>?),
      (AsyncError?, AsyncError?)
    > catch (e) {
      final error = e.errors.$1?.error ?? e.errors.$2?.error;
      SnackBarUtil().showError(
        error is RequisitionException
            ? error.message
            : "Erro ao carregar filtros",
      );
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } on Exception catch (_) {
      SnackBarUtil().showError("Erro ao carregar filtros");
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

      final Page<DeviceDataTable> result = await _allDevicesRepository
          .getAllDevicesFiltering(filter);
      if (generation != _requestGeneration) return;
      devices.addAll(result.content);
      _totalPages = result.totalPages;
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
      SnackBarUtil().showError("Erro ao buscar mais aparelhos");
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
