import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/http/response_validation.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';

class ColorService {
  Future<List<ColorModel>> getColors() async {
    final response = await CustomDio.dioInstance().get<List<dynamic>>(
      '/v1/colors',
    );
    response.ensureSuccess();
    return response.data!
        .map((e) => ColorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
