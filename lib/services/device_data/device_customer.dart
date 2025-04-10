import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';

class DeviceCustomerService {
  final Dio dio = Dio();

  Future<DeviceCustomer> getCustomerDeviceById(int id) async {
    Response result = await dio.get('http://localhost:8080/v1/device/$id',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ));

    return DeviceCustomer.fromJson(result.data);
  }

  Future<DeviceCustomer> updateDeviceCustomer(
      DeviceCustomer deviceCustomer) async {
    var json = deviceCustomer.toJson();
    Response result = await dio.put(
      'http://localhost:8080/v1/device/update',
      options: Options(
        headers: {
          'Accept': 'application/json',
        },
      ),
      data: json,
    );
    return DeviceCustomer.fromJson(result.data);
  }
}
