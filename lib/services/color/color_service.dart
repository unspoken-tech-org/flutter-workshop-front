import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';

class ColorService {
  ColorService({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  Future<Result<List<ColorModel>>> getColors() {
    return _api.send(
      (dio) => dio.get<dynamic>('/v1/colors'),
      decode: (data) => parseList(data, ColorModel.fromJson),
    );
  }
}
