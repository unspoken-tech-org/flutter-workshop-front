class HomeTableFilter {
  String? customerName;
  int? deviceId;
  String? customerPhone;
  String? customerCpf;

  HomeTableFilter({
    this.customerName,
    this.deviceId,
    this.customerPhone,
    this.customerCpf,
  });

  void clearTypedFilters() {
    customerName = null;
    deviceId = null;
    customerPhone = null;
    customerCpf = null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (customerName != null) 'customerName': customerName,
      if (deviceId != null) 'deviceId': deviceId,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerCpf != null) 'customerCpf': customerCpf,
    };
  }
}
