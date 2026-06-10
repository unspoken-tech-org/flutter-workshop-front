import 'package:collection/collection.dart';
import 'package:flutter_workshop_front/core/nullable.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class DeviceSearchFilter {
  String? searchQuery;
  int? deviceId;
  String? customerPhone;
  String? customerCpf;

  List<StatusEnum> status = [];

  DateTime? initialEntryDate;
  DateTime? finalEntryDate;

  Map<OrderBy, OrderDirection?> orderBy = const {};

  bool? hasUrgency;
  bool? hasRevision;

  int page = 0;
  int size = 15;

  DeviceSearchFilter({
    this.searchQuery,
    this.deviceId,
    this.customerPhone,
    this.customerCpf,
    this.status = const [],
    this.initialEntryDate,
    this.finalEntryDate,
    this.hasUrgency,
    this.hasRevision,
    this.orderBy = const {
      OrderBy.name: null,
      OrderBy.entryDate: OrderDirection.desc,
      OrderBy.status: null,
    },
    this.page = 0,
    this.size = 15,
  });

  int get filtersApplied {
    final hasSearchQuery = searchQuery != null && searchQuery!.isNotEmpty;
    final hasStatusFilters = status.isNotEmpty;
    final hasDateFilters = initialEntryDate != null || finalEntryDate != null;
    final hasRevisionUrgencyFilters =
        (hasRevision ?? false) || (hasUrgency ?? false);

    return [
      hasSearchQuery,
      hasStatusFilters,
      hasDateFilters,
      hasRevisionUrgencyFilters
    ].where((filter) => filter).length;
  }

  DeviceSearchFilter copyWith({
    Nullable<String>? searchQuery,
    Nullable<int>? deviceId,
    Nullable<String>? customerPhone,
    Nullable<String>? customerCpf,
    List<StatusEnum>? status,
    Nullable<DateTime>? initialEntryDate,
    Nullable<DateTime>? finalEntryDate,
    Map<OrderBy, OrderDirection?>? orderBy,
    Nullable<bool>? hasUrgency,
    Nullable<bool>? hasRevision,
    int? page,
    int? size,
  }) {
    return DeviceSearchFilter(
      searchQuery:
          searchQuery == null ? this.searchQuery : searchQuery.value,
      deviceId: deviceId == null ? this.deviceId : deviceId.value,
      customerPhone:
          customerPhone == null ? this.customerPhone : customerPhone.value,
      customerCpf: customerCpf == null ? this.customerCpf : customerCpf.value,
      status: status ?? this.status,
      initialEntryDate: initialEntryDate == null
          ? this.initialEntryDate
          : initialEntryDate.value,
      finalEntryDate:
          finalEntryDate == null ? this.finalEntryDate : finalEntryDate.value,
      orderBy: orderBy ?? this.orderBy,
      hasUrgency: hasUrgency == null ? this.hasUrgency : hasUrgency.value,
      hasRevision: hasRevision == null ? this.hasRevision : hasRevision.value,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  DeviceSearchFilter withSearchQuery(String? query) {
    return copyWith(
      searchQuery: Nullable.of(query),
    );
  }

  DeviceSearchFilter withToggledStatus(StatusEnum status) {
    final newList = List<StatusEnum>.from(this.status);
    if (newList.contains(status)) {
      newList.remove(status);
    } else {
      newList.add(status);
    }
    return copyWith(status: newList);
  }

  DeviceSearchFilter withToggledUrgency() {
    final urgency = hasUrgency == true ? null : true;
    return copyWith(
      hasUrgency: Nullable.of(urgency),
    );
  }

  DeviceSearchFilter withToggledRevision() {
    final revision = hasRevision == true ? null : true;
    return copyWith(
      hasRevision: Nullable.of(revision),
    );
  }

  DeviceSearchFilter withRangeDate(DateTime? initialDate, DateTime? endDate) {
    return copyWith(
      initialEntryDate: Nullable.of(initialDate),
      finalEntryDate: Nullable.of(endDate),
    );
  }

  DeviceSearchFilter clearSearchQuery() {
    return copyWith(
      searchQuery: Nullable.empty(),
    );
  }

  DeviceSearchFilter withToggledOrderBy(
    OrderBy orderBy,
  ) {
    final newMap = this.orderBy.map((key, value) {
      if (key == orderBy) {
        switch (value) {
          case null:
            return MapEntry(key, OrderDirection.desc);
          case OrderDirection.asc:
            return MapEntry(key, null);
          case OrderDirection.desc:
            return MapEntry(key, OrderDirection.asc);
        }
      }
      return MapEntry(key, null);
    });

    return copyWith(orderBy: newMap);
  }

  DeviceSearchFilter clearOrderBy() {
    return copyWith(
      orderBy: const {
        OrderBy.name: null,
        OrderBy.entryDate: OrderDirection.desc,
        OrderBy.status: null,
      },
    );
  }

  DeviceSearchFilter clearSelectableFilters() {
    return copyWith(
      searchQuery: Nullable.empty(),
      deviceId: Nullable.empty(),
      customerPhone: Nullable.empty(),
      customerCpf: Nullable.empty(),
      status: [],
      initialEntryDate: null,
      finalEntryDate: null,
      hasUrgency: Nullable.empty(),
      hasRevision: Nullable.empty(),
      page: 0,
    );
  }

  Map<String, dynamic> toJson() {
    final orderEntry = orderBy.entries.firstWhereOrNull((e) => e.value != null);

    return {
      if (searchQuery != null && searchQuery!.isNotEmpty)
        'searchQuery': searchQuery,
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
      'page': page,
      'size': size,
    };
  }
}
