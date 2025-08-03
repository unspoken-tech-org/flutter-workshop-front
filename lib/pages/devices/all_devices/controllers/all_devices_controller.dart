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
    fetchAllDevicesFiltering();
    fetchFilterOptions();
  }

  List<DeviceDataTable> devices = [];
  List<DeviceType> deviceTypes = [];
  List<DeviceBrand> deviceBrands = [];
  late DeviceFilter filter;

  bool isLoading = true;
  bool isFiltering = false;
  bool isFiltersLoading = true;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _currentPage = 0;
  int _totalElements = 0;
  int get totalElements => _totalElements;
  int _totalPages = 0;
  int get totalPages => _totalPages;

  Future<void> fetchAllDevicesFiltering() async {
    try {
      isLoading = true;
      _currentPage = 0;
      filter.page = _currentPage;
      devices = [];
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));
      final Page<DeviceDataTable> result =
          await _allDevicesRepository.getAllDevicesFiltering(filter);
      devices = result.content;
      _totalElements = result.totalElements;
      _totalPages = result.totalPages;
      _hasMore = !result.last;
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } on Exception catch (_) {
      SnackBarUtil().showError("Erro ao buscar aparelhos");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFilterOptions() async {
    try {
      isFiltersLoading = true;
      notifyListeners();
      final (resultTypes, resultBrands) = await (
        _allDevicesRepository.getAllDeviceTypes(),
        _allDevicesRepository.getAllDeviceBrands()
      ).wait;
      deviceTypes = resultTypes;
      deviceBrands = resultBrands;
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
    filter.clearTypedFilters();

    var search = FilterUtils(searchTerm);
    if (search.isName) {
      filter.customerName = search.term;
    } else if (search.isCpf) {
      filter.customerCpf = search.term.replaceAll('.', '').replaceAll('-', '');
    } else if (search.isPhoneOrCellPhone) {
      filter.customerPhone = search.term;
    } else if (search.isId) {
      filter.deviceId = int.parse(search.term);
    }
    fetchAllDevicesFiltering();
  }

  void addRemoveDeviceType(DeviceType deviceType) {
    filter = filter.withToggledType(deviceType);
    notifyListeners();
    fetchAllDevicesFiltering();
  }

  void addRemoveDeviceBrand(DeviceBrand deviceBrand) {
    filter = filter.withToggledBrand(deviceBrand);
    notifyListeners();
    fetchAllDevicesFiltering();
  }

  void addRemoveStatus(StatusEnum status) {
    filter = filter.withToggledStatus(status);
    notifyListeners();
    fetchAllDevicesFiltering();
  }

  void toggleUrgency() {
    filter = filter.withToggledUrgency();
    notifyListeners();
    fetchAllDevicesFiltering();
  }

  void toggleRevision() {
    filter = filter.withToggledRevision();
    notifyListeners();
    fetchAllDevicesFiltering();
  }

  void addRemoveEnterRangeDate(DateTime? initialDate, DateTime? endDate) {
    filter = filter.withRangeDate(initialDate, endDate);
    notifyListeners();
    fetchAllDevicesFiltering();
  }

  void toggleOrderBy(OrderBy orderBy) {
    filter = filter.withToggledOrderBy(orderBy);
    notifyListeners();
    fetchAllDevicesFiltering();
  }

  void clearOrderBy() {
    filter = filter.clearOrderBy();
    notifyListeners();
    fetchAllDevicesFiltering();
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
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      _currentPage++;
      filter.page = _currentPage;

      final Page<DeviceDataTable> result =
          await _allDevicesRepository.getAllDevicesFiltering(filter);
      devices.addAll(result.content);
      _totalPages = result.totalPages;
      _hasMore = !result.last;
    } on RequisitionException catch (e) {
      _currentPage--;
      SnackBarUtil().showError(e.message);
    } on Exception catch (_) {
      _currentPage--;
      SnackBarUtil().showError("Erro ao buscar mais aparelhos");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
