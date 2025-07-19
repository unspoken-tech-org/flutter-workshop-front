import 'package:flutter_workshop_front/core/nullable.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

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

  bool hasUrgency = false;
  bool hasRevision = false;

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
  });

  int get filtersApplied {
    final hasStatusFilters = status.isNotEmpty;
    final hasTypeFilters = deviceTypes.isNotEmpty;
    final hasBrandFilters = deviceBrands.isNotEmpty;
    final hasDateFilters = initialEntryDate != null || finalEntryDate != null;

    return [hasStatusFilters, hasTypeFilters, hasBrandFilters, hasDateFilters]
        .where((filter) => filter)
        .length;
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
    bool? hasUrgency,
    bool? hasRevision,
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
      hasUrgency: hasUrgency ?? this.hasUrgency,
      hasRevision: hasRevision ?? this.hasRevision,
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
    return copyWith(hasUrgency: !hasUrgency);
  }

  DeviceFilter withToggledRevision() {
    return copyWith(hasRevision: !hasRevision);
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

  DeviceFilter clearSelectableFilters() {
    return copyWith(
      status: [],
      deviceTypes: [],
      deviceBrands: [],
      initialEntryDate: null,
      finalEntryDate: null,
      hasUrgency: false,
      hasRevision: false,
    );
  }

  Map<String, dynamic> toJson() {
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
    };
  }
}
