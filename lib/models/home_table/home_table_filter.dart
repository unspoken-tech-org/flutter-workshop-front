class HomeTableFilter {
  String? customerName;
  int? deviceId;
  String? customerPhone;
  String? customerCpf;

  List<String> status = [];
  List<int> deviceTypes = [];
  List<int> deviceBrands = [];

  HomeTableFilter({
    this.customerName,
    this.deviceId,
    this.customerPhone,
    this.customerCpf,
  });

  void toggleStatus(String name) {
    if (status.contains(name)) {
      status.remove(name);
    } else {
      status.add(name);
    }
  }

  void toggleTypes(int id) {
    if (deviceTypes.contains(id)) {
      deviceTypes.remove(id);
    } else {
      deviceTypes.add(id);
    }
  }

  void toggleBrands(int id) {
    if (deviceBrands.contains(id)) {
      deviceBrands.remove(id);
    } else {
      deviceBrands.add(id);
    }
  }

  void clearTypedFilters() {
    customerName = null;
    deviceId = null;
    customerPhone = null;
    customerCpf = null;
  }

  void clearSelectableFilters() {
    status.clear();
    deviceTypes.clear();
    deviceBrands.clear();
  }

  Map<String, dynamic> toJson() {
    return {
      if (customerName != null) 'customerName': customerName,
      if (deviceId != null) 'deviceId': deviceId,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerCpf != null) 'customerCpf': customerCpf,
      if (status.isNotEmpty) 'status': status,
      if (deviceTypes.isNotEmpty) 'deviceTypes': deviceTypes,
      if (deviceBrands.isNotEmpty) 'deviceBrands': deviceBrands,
    };
  }
}
