class CreateDeviceCustomerResponse {
  final int deviceId;

  CreateDeviceCustomerResponse({required this.deviceId});

  factory CreateDeviceCustomerResponse.fromJson(Map<String, dynamic> json) {
    return CreateDeviceCustomerResponse(deviceId: json['deviceId']);
  }
}
