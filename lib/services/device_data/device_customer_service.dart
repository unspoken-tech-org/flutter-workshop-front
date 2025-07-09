import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/customer_device/create_device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';

class DeviceCustomerService {
  final Dio dio = CustomDio.dioInstance();

  Future<DeviceCustomer> getCustomerDeviceById(int id) async {
    Response result = await dio.get('/v1/device/$id');

    if (result.statusCode != 200) {
      throw Exception('Erro ao buscar dispositivo');
    }

    return DeviceCustomer.fromJson(result.data);
  }

  Future<DeviceCustomer> updateDeviceCustomer(
      DeviceCustomer deviceCustomer) async {
    var json = deviceCustomer.toJson();

    Response result = await dio.put('/v1/device/update', data: json);
    return DeviceCustomer.fromJson(result.data);
  }

  Future<CreateDeviceCustomerResponse> createDeviceCustomer(
      DeviceInput device) async {
    var json = device.toJson();

    Response result = await dio.post('/v1/device/create', data: json);

    if (result.statusCode != 201) {
      throw Exception('Erro ao criar dispositivo');
    }
    return CreateDeviceCustomerResponse.fromJson(result.data);
  }
}
