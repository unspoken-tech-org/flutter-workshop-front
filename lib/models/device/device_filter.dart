import 'package:collection/collection.dart';
import 'package:flutter_workshop_front/core/nullable.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

enum OrderBy {
  name('Nome'),
  entryDate('Data de entrada'),
  status('Status');

  final String displayName;

  const OrderBy(this.displayName);
}

enum OrderDirection { asc, desc }

class DeviceFilter {
  String? customerName;
  int? deviceId;
  String? customerPhone;
  String? customerCpf;

  List<StatusEnum> status = [];
  List<DeviceType> deviceTypes = [];
  List<DeviceBrand> deviceBrands = [];

  DateTime? initialEntryDate;
  DateTime? finalEntryDate;

  Map<OrderBy, OrderDirection?> orderBy = const {};

  bool hasUrgency = false;
  bool hasRevision = false;

  int page = 0;

  DeviceFilter({
    this.customerName,
    this.deviceId,
    this.customerPhone,
    this.customerCpf,
    this.status = const [],
    this.deviceTypes = const [],
    this.deviceBrands = const [],
    this.initialEntryDate,
    this.finalEntryDate,
    this.hasUrgency = false,
    this.hasRevision = false,
    this.orderBy = const {
      OrderBy.name: null,
      OrderBy.entryDate: OrderDirection.desc,
      OrderBy.status: null,
    },
    this.page = 0,
  });

  int get filtersApplied {
    final hasStatusFilters = status.isNotEmpty;
    final hasTypeFilters = deviceTypes.isNotEmpty;
    final hasBrandFilters = deviceBrands.isNotEmpty;
    final hasDateFilters = initialEntryDate != null || finalEntryDate != null;
    final hasRevisionUrgencyFilters = hasRevision || hasUrgency;

    return [
      hasStatusFilters,
      hasTypeFilters,
      hasBrandFilters,
      hasDateFilters,
      hasRevisionUrgencyFilters
    ].where((filter) => filter).length;
  }

  DeviceFilter copyWith({
    String? customerName,
    int? deviceId,
    String? customerPhone,
    String? customerCpf,
    List<StatusEnum>? status,
    List<DeviceType>? deviceTypes,
    List<DeviceBrand>? deviceBrands,
    Nullable<DateTime>? initialEntryDate,
    Nullable<DateTime>? finalEntryDate,
    Map<OrderBy, OrderDirection?>? orderBy,
    bool? hasUrgency,
    bool? hasRevision,
    int? page,
  }) {
    return DeviceFilter(
      customerName: customerName ?? this.customerName,
      deviceId: deviceId ?? this.deviceId,
      customerPhone: customerPhone ?? this.customerPhone,
      customerCpf: customerCpf ?? this.customerCpf,
      status: status ?? this.status,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      deviceBrands: deviceBrands ?? this.deviceBrands,
      initialEntryDate: initialEntryDate == null
          ? this.initialEntryDate
          : initialEntryDate.value,
      finalEntryDate:
          finalEntryDate == null ? this.finalEntryDate : finalEntryDate.value,
      orderBy: orderBy ?? this.orderBy,
      hasUrgency: hasUrgency ?? this.hasUrgency,
      hasRevision: hasRevision ?? this.hasRevision,
      page: page ?? this.page,
    );
  }

  DeviceFilter withToggledStatus(StatusEnum status) {
    final newList = List<StatusEnum>.from(this.status);
    if (newList.contains(status)) {
      newList.remove(status);
    } else {
      newList.add(status);
    }
    return copyWith(status: newList);
  }

  DeviceFilter withToggledType(DeviceType deviceType) {
    final newList = List<DeviceType>.from(deviceTypes);
    if (newList.contains(deviceType)) {
      newList.remove(deviceType);
    } else {
      newList.add(deviceType);
    }
    return copyWith(deviceTypes: newList);
  }

  DeviceFilter withToggledBrand(DeviceBrand deviceBrand) {
    final newList = List<DeviceBrand>.from(deviceBrands);
    if (newList.contains(deviceBrand)) {
      newList.remove(deviceBrand);
    } else {
      newList.add(deviceBrand);
    }
    return copyWith(deviceBrands: newList);
  }

  DeviceFilter withToggledUrgency() {
    final urgency = !hasUrgency;
    return copyWith(
      hasUrgency: urgency,
      hasRevision: urgency ? false : hasRevision,
    );
  }

  DeviceFilter withToggledRevision() {
    final revision = !hasRevision;
    return copyWith(
      hasRevision: revision,
      hasUrgency: revision ? false : hasUrgency,
    );
  }

  DeviceFilter withRangeDate(DateTime? initialDate, DateTime? endDate) {
    return copyWith(
      initialEntryDate: Nullable.of(initialDate),
      finalEntryDate: Nullable.of(endDate),
    );
  }

  DeviceFilter clearTypedFilters() {
    return copyWith(
      customerName: null,
      deviceId: null,
      customerPhone: null,
      customerCpf: null,
    );
  }

  DeviceFilter withToggledOrderBy(
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

  DeviceFilter clearOrderBy() {
    return copyWith(
      orderBy: const {
        OrderBy.name: null,
        OrderBy.entryDate: OrderDirection.desc,
        OrderBy.status: null,
      },
    );
  }

  DeviceFilter clearSelectableFilters() {
    return copyWith(
      status: [],
      deviceTypes: [],
      deviceBrands: [],
      initialEntryDate: null,
      finalEntryDate: null,
      hasUrgency: false,
      hasRevision: false,
      page: 0,
    );
  }

  Map<String, dynamic> toJson() {
    final orderEntry = orderBy.entries.firstWhereOrNull((e) => e.value != null);

    return {
      if (customerName != null) 'customerName': customerName,
      if (deviceId != null) 'deviceId': deviceId,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerCpf != null) 'customerCpf': customerCpf,
      if (status.isNotEmpty) 'status': status.map((e) => e.dbName).toList(),
      if (deviceTypes.isNotEmpty)
        'deviceTypes': deviceTypes.map((e) => e.idType).toList(),
      if (deviceBrands.isNotEmpty)
        'deviceBrands': deviceBrands.map((e) => e.idBrand).toList(),
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
    };
  }
}
