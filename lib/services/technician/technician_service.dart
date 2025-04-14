import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';

class TechnicianService {
  final Dio dio = Dio();

  Future<List<Technician>> getTechnicians() async {
    Response result = await dio.get('http://localhost:8080/v1/technician/list');
    return (result.data as List).map((e) => Technician.fromJson(e)).toList();
  }
}
