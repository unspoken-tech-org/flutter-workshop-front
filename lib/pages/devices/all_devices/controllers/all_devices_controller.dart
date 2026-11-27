import 'dart:async';

import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/paged_list_controller.dart';
import 'package:flutter_workshop_front/models/device/device_query.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';

/// Single device listing (search, filters, ordering and pagination).
class AllDevicesController
    extends PagedListController<DeviceDataTable, DeviceQuery> {
  AllDevicesController(
    DeviceRepository deviceRepository,
    this._catalogRepository, {
    DeviceQuery? query,
    super.debounce = const Duration(milliseconds: 200),
  }) : super(
         initialQuery: query ?? const DeviceQuery(),
         fetch: deviceRepository.queryDevices,
         failureMessage: (failure, {required loadingMore}) => failure.messageOr(
           loadingMore
               ? 'Erro ao buscar mais aparelhos'
               : 'Erro ao buscar aparelhos',
         ),
       ) {
    unawaited(fetchFilterOptions());
  }

  final CatalogRepository _catalogRepository;

  List<DeviceType> deviceTypes = [];
  List<DeviceBrand> deviceBrands = [];

  bool isFiltering = false;
  bool isFiltersLoading = false;

  List<DeviceDataTable> get devices => items;

  Future<void> fetchFilterOptions() async {
    if (isFiltersLoading) return;
    try {
      isFiltersLoading = true;
      notifyListeners();
      final (resultTypes, resultBrands) = await (
        _catalogRepository.getAllDeviceTypes(),
        _catalogRepository.getAllDeviceBrands(),
      ).wait;
      final failure = switch ((resultTypes, resultBrands)) {
        (Err(:final failure), _) => failure,
        (_, Err(:final failure)) => failure,
        _ => null,
      };
      if (failure != null) {
        emitFailure(failure, 'Erro ao carregar filtros');
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
    unawaited(updateQuery(query.withSearchText(searchTerm)));
  }

  void addRemoveDeviceType(DeviceType deviceType) {
    unawaited(updateQuery(query.withToggledType(deviceType)));
  }

  void addRemoveDeviceBrand(DeviceBrand deviceBrand) {
    unawaited(updateQuery(query.withToggledBrand(deviceBrand)));
  }

  void addRemoveStatus(StatusEnum status) {
    unawaited(updateQuery(query.withToggledStatus(status)));
  }

  void toggleUrgency() {
    unawaited(updateQuery(query.withToggledUrgency()));
  }

  void toggleRevision() {
    unawaited(updateQuery(query.withToggledRevision()));
  }

  void addRemoveEnterRangeDate(DateTime? initialDate, DateTime? endDate) {
    unawaited(updateQuery(query.withRangeDate(initialDate, endDate)));
  }

  void toggleOrderBy(OrderBy orderBy) {
    unawaited(updateQuery(query.withToggledOrderBy(orderBy)));
  }

  void clearOrderBy() {
    unawaited(updateQuery(query.clearOrderBy()));
  }

  Future<void> clearSearch() => updateQuery(query.clearSearch());

  Future<void> clearFilters() => updateQuery(query.clearSelectableFilters());
}
