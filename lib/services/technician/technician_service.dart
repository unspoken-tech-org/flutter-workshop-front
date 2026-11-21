import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/http/response_validation.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';

class TechnicianService {
  final Dio dio = CustomDio.dioInstance();

  Future<List<Technician>> getTechnicians() async {
    final Response<List<dynamic>> result = await dio.get<List<dynamic>>(
      '/v1/technician',
    );
    result.ensureSuccess();
    return result.data!
        .map((e) => Technician.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
