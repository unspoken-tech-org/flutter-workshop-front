import 'package:collection/collection.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/utils/filter_utils.dart';

enum OrderBy {
  name('Nome'),
  entryDate('Data de entrada'),
  status('Status');

  final String displayName;

  const OrderBy(this.displayName);
}

enum OrderDirection { asc, desc }

const Object _unset = Object();

const Map<OrderBy, OrderDirection?> _defaultOrderBy = {
  OrderBy.name: null,
  OrderBy.entryDate: OrderDirection.desc,
  OrderBy.status: null,
};

/// Immutable description of a device listing (search text, filters and
/// ordering). The page number is not part of the query: it is passed
/// separately when the query is sent.
///
/// `copyWith` leaves a field untouched when it is omitted and clears it when
/// `null` is passed explicitly.
class DeviceQuery {
  const DeviceQuery({
    this.searchQuery,
    this.deviceId,
    this.customerPhone,
    this.customerCpf,
    this.status = const [],
    this.deviceTypes = const [],
    this.deviceBrands = const [],
    this.initialEntryDate,
    this.finalEntryDate,
    this.hasUrgency,
    this.hasRevision,
    this.orderBy = _defaultOrderBy,
    this.size = defaultSize,
  });

  static const int defaultSize = 15;

  final String? searchQuery;
  final int? deviceId;
  final String? customerPhone;
  final String? customerCpf;
  final List<StatusEnum> status;
  final List<DeviceType> deviceTypes;
  final List<DeviceBrand> deviceBrands;
  final DateTime? initialEntryDate;
  final DateTime? finalEntryDate;
  final bool? hasUrgency;
  final bool? hasRevision;
  final Map<OrderBy, OrderDirection?> orderBy;
  final int size;

  int get filtersApplied {
    final hasRevisionUrgencyFilters =
        (hasRevision ?? false) || (hasUrgency ?? false);

    return [
      status.isNotEmpty,
      deviceTypes.isNotEmpty,
      deviceBrands.isNotEmpty,
      initialEntryDate != null || finalEntryDate != null,
      hasRevisionUrgencyFilters,
    ].where((filter) => filter).length;
  }

  /// Type and brand filters only exist on the structured filter endpoint;
  /// every other query goes to the full-text search endpoint.
  bool get usesStructuredFilter =>
      deviceTypes.isNotEmpty || deviceBrands.isNotEmpty;

  DeviceQuery copyWith({
    Object? searchQuery = _unset,
    Object? deviceId = _unset,
    Object? customerPhone = _unset,
    Object? customerCpf = _unset,
    List<StatusEnum>? status,
    List<DeviceType>? deviceTypes,
    List<DeviceBrand>? deviceBrands,
    Object? initialEntryDate = _unset,
    Object? finalEntryDate = _unset,
    Object? hasUrgency = _unset,
    Object? hasRevision = _unset,
    Map<OrderBy, OrderDirection?>? orderBy,
    int? size,
  }) {
    return DeviceQuery(
      searchQuery: identical(searchQuery, _unset)
          ? this.searchQuery
          : searchQuery as String?,
      deviceId: identical(deviceId, _unset) ? this.deviceId : deviceId as int?,
      customerPhone: identical(customerPhone, _unset)
          ? this.customerPhone
          : customerPhone as String?,
      customerCpf: identical(customerCpf, _unset)
          ? this.customerCpf
          : customerCpf as String?,
      status: status ?? this.status,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      deviceBrands: deviceBrands ?? this.deviceBrands,
      initialEntryDate: identical(initialEntryDate, _unset)
          ? this.initialEntryDate
          : initialEntryDate as DateTime?,
      finalEntryDate: identical(finalEntryDate, _unset)
          ? this.finalEntryDate
          : finalEntryDate as DateTime?,
      hasUrgency: identical(hasUrgency, _unset)
          ? this.hasUrgency
          : hasUrgency as bool?,
      hasRevision: identical(hasRevision, _unset)
          ? this.hasRevision
          : hasRevision as bool?,
      orderBy: orderBy ?? this.orderBy,
      size: size ?? this.size,
    );
  }

  /// Replaces the typed search with [term], classifying it as CPF, phone,
  /// device id or free text.
  DeviceQuery withSearchText(String term) {
    final cleared = clearSearch();
    final trimmed = term.trim();
    if (trimmed.isEmpty) return cleared;

    final search = FilterUtils(trimmed);
    if (search.isCpf) {
      return cleared.copyWith(customerCpf: search.digits);
    }
    if (search.isPhoneOrCellPhone) {
      return cleared.copyWith(customerPhone: search.digits);
    }
    if (search.isId) {
      return cleared.copyWith(deviceId: int.parse(search.digits));
    }
    return cleared.copyWith(searchQuery: search.text);
  }

  DeviceQuery clearSearch() => copyWith(
    searchQuery: null,
    deviceId: null,
    customerPhone: null,
    customerCpf: null,
  );

  DeviceQuery withToggledStatus(StatusEnum value) =>
      copyWith(status: _toggled(status, value));

  DeviceQuery withToggledType(DeviceType value) =>
      copyWith(deviceTypes: _toggled(deviceTypes, value));

  DeviceQuery withToggledBrand(DeviceBrand value) =>
      copyWith(deviceBrands: _toggled(deviceBrands, value));

  DeviceQuery withToggledUrgency() =>
      copyWith(hasUrgency: hasUrgency == true ? null : true);

  DeviceQuery withToggledRevision() =>
      copyWith(hasRevision: hasRevision == true ? null : true);

  DeviceQuery withRangeDate(DateTime? initialDate, DateTime? endDate) =>
      copyWith(initialEntryDate: initialDate, finalEntryDate: endDate);

  DeviceQuery withToggledOrderBy(OrderBy target) {
    final newMap = orderBy.map((key, value) {
      if (key != target) return MapEntry(key, null);
      return switch (value) {
        null => MapEntry(key, OrderDirection.desc),
        OrderDirection.asc => MapEntry(key, null),
        OrderDirection.desc => MapEntry(key, OrderDirection.asc),
      };
    });
    return copyWith(orderBy: newMap);
  }

  DeviceQuery clearOrderBy() => copyWith(orderBy: _defaultOrderBy);

  /// Resets status, type, brand, date, urgency and revision filters, keeping
  /// the typed search and the ordering.
  DeviceQuery clearSelectableFilters() => copyWith(
    status: const [],
    deviceTypes: const [],
    deviceBrands: const [],
    initialEntryDate: null,
    finalEntryDate: null,
    hasUrgency: null,
    hasRevision: null,
  );

  /// Body for `POST /v1/device/search` (full-text search).
  Map<String, dynamic> toSearchJson(int page) {
    return {
      if (searchQuery != null && searchQuery!.isNotEmpty)
        'searchQuery': searchQuery,
      ..._commonJson(),
      'page': page,
      'size': size,
    };
  }

  /// Body for `POST /v1/device/filter` (structured filter, with type/brand).
  /// The typed text goes in `customerName`.
  Map<String, dynamic> toFilterJson(int page) {
    return {
      if (searchQuery != null && searchQuery!.isNotEmpty)
        'customerName': searchQuery,
      ..._commonJson(),
      if (deviceTypes.isNotEmpty)
        'deviceTypes': deviceTypes.map((e) => e.idType).toList(),
      if (deviceBrands.isNotEmpty)
        'deviceBrands': deviceBrands.map((e) => e.idBrand).toList(),
      'page': page,
    };
  }

  Map<String, dynamic> _commonJson() {
    final orderEntry = orderBy.entries.firstWhereOrNull((e) => e.value != null);
    return {
      if (deviceId != null) 'deviceId': deviceId,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerCpf != null) 'customerCpf': customerCpf,
      if (status.isNotEmpty) 'status': status.map((e) => e.dbName).toList(),
      if (initialEntryDate != null)
        'initialEntryDate': initialEntryDate?.toString(),
      if (finalEntryDate != null) 'finalEntryDate': finalEntryDate?.toString(),
      'urgency': hasUrgency,
      'revision': hasRevision,
      if (orderEntry != null)
        'ordenation': {
          'orderByField': orderEntry.key.name,
          'orderByDirection': orderEntry.value?.name.toUpperCase(),
        },
    };
  }

  static List<E> _toggled<E>(List<E> list, E value) {
    final result = List<E>.of(list);
    if (!result.remove(value)) result.add(value);
    return List.unmodifiable(result);
  }
}
