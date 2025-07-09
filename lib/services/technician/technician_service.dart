import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';

class TechnicianService {
  final Dio dio = CustomDio.dioInstance();

  Future<List<Technician>> getTechnicians() async {
    Response result = await dio.get('/v1/technician/list');
    return (result.data as List).map((e) => Technician.fromJson(e)).toList();
  }
}
