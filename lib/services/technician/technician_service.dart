import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';

class TechnicianService {
  TechnicianService({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  Future<Result<List<Technician>>> getTechnicians() {
    return _api.send(
      (dio) => dio.get<dynamic>('/v1/technician'),
      decode: (data) => parseList(data, Technician.fromJson),
    );
  }
}
