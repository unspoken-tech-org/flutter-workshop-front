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

  bool? hasUrgency;
  bool? hasRevision;

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
    this.hasUrgency,
    this.hasRevision,
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
    final hasRevisionUrgencyFilters =
        (hasRevision ?? false) || (hasUrgency ?? false);

    return [
      hasStatusFilters,
      hasTypeFilters,
      hasBrandFilters,
      hasDateFilters,
      hasRevisionUrgencyFilters
    ].where((filter) => filter).length;
  }

  DeviceFilter copyWith({
    Nullable<String>? customerName,
    Nullable<int>? deviceId,
    Nullable<String>? customerPhone,
    Nullable<String>? customerCpf,
    List<StatusEnum>? status,
    List<DeviceType>? deviceTypes,
    List<DeviceBrand>? deviceBrands,
    Nullable<DateTime>? initialEntryDate,
    Nullable<DateTime>? finalEntryDate,
    Map<OrderBy, OrderDirection?>? orderBy,
    Nullable<bool>? hasUrgency,
    Nullable<bool>? hasRevision,
    int? page,
  }) {
    return DeviceFilter(
      customerName:
          customerName == null ? this.customerName : customerName.value,
      deviceId: deviceId == null ? this.deviceId : deviceId.value,
      customerPhone:
          customerPhone == null ? this.customerPhone : customerPhone.value,
      customerCpf: customerCpf == null ? this.customerCpf : customerCpf.value,
      status: status ?? this.status,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      deviceBrands: deviceBrands ?? this.deviceBrands,
      initialEntryDate: initialEntryDate == null
          ? this.initialEntryDate
          : initialEntryDate.value,
      finalEntryDate:
          finalEntryDate == null ? this.finalEntryDate : finalEntryDate.value,
      orderBy: orderBy ?? this.orderBy,
      hasUrgency: hasUrgency == null ? this.hasUrgency : hasUrgency.value,
      hasRevision: hasRevision == null ? this.hasRevision : hasRevision.value,
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
    final urgency = hasUrgency == true ? null : true;
    return copyWith(
      hasUrgency: Nullable.of(urgency),
    );
  }

  DeviceFilter withToggledRevision() {
    final revision = hasRevision == true ? null : true;
    return copyWith(
      hasRevision: Nullable.of(revision),
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
      customerName: Nullable.empty(),
      deviceId: Nullable.empty(),
      customerPhone: Nullable.empty(),
      customerCpf: Nullable.empty(),
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
      hasUrgency: Nullable.empty(),
      hasRevision: Nullable.empty(),
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
