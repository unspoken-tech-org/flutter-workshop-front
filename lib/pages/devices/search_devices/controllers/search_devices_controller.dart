import 'package:flutter/material.dart' hide Page;
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart'
    show OrderBy;
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';
import 'package:flutter_workshop_front/utils/filter_utils.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class SearchDevicesController extends ChangeNotifier {
  final AllDevicesRepository _allDevicesRepository;

  SearchDevicesController(this._allDevicesRepository,
      {DeviceSearchFilter? filter}) {
    this.filter = filter ?? DeviceSearchFilter();
    searchDevices();
  }

  List<DeviceDataTable> devices = [];
  late DeviceSearchFilter filter;

  bool isLoading = false;
  bool isFiltering = false;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _currentPage = 0;
  int _totalElements = 0;
  int get totalElements => _totalElements;
  int _totalPages = 0;
  int get totalPages => _totalPages;

  Future<void> searchDevices() async {
    if (isLoading) return;
    try {
      isLoading = true;
      _currentPage = 0;
      filter.page = _currentPage;
      devices = [];
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));
      final Page<DeviceDataTable> result =
          await _allDevicesRepository.searchDevices(filter);
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

  void toggleFiltering() {
    isFiltering = !isFiltering;
    notifyListeners();
  }

  void filterTable(String searchTerm) {
    filter = filter.clearSearchQuery();
    filter.customerCpf = null;
    filter.customerPhone = null;
    filter.deviceId = null;

    if (searchTerm.isEmpty) {
      searchDevices();
      return;
    }

    var search = FilterUtils(searchTerm);
    if (search.isCpf) {
      filter.customerCpf = search.term;
    } else if (search.isPhoneOrCellPhone) {
      filter.customerPhone = search.term;
    } else if (search.isId) {
      filter.deviceId = int.parse(search.term);
    } else {
      filter = filter.withSearchQuery(searchTerm);
    }
    searchDevices();
  }

  void addRemoveStatus(StatusEnum status) {
    filter = filter.withToggledStatus(status);
    notifyListeners();
    searchDevices();
  }

  void toggleUrgency() {
    filter = filter.withToggledUrgency();
    notifyListeners();
    searchDevices();
  }

  void toggleRevision() {
    filter = filter.withToggledRevision();
    notifyListeners();
    searchDevices();
  }

  void addRemoveEnterRangeDate(DateTime? initialDate, DateTime? endDate) {
    filter = filter.withRangeDate(initialDate, endDate);
    notifyListeners();
    searchDevices();
  }

  void toggleOrderBy(OrderBy orderBy) {
    filter = filter.withToggledOrderBy(orderBy);
    notifyListeners();
    searchDevices();
  }

  void clearOrderBy() {
    filter = filter.clearOrderBy();
    notifyListeners();
    searchDevices();
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
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      _currentPage++;
      filter.page = _currentPage;

      final Page<DeviceDataTable> result =
          await _allDevicesRepository.searchDevices(filter);
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
