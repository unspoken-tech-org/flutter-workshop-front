import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';

class ColorService {
  Future<List<ColorModel>> getColors() async {
    final response = await CustomDio.dioInstance().get('/v1/colors');
    return (response.data as List).map((e) => ColorModel.fromJson(e)).toList();
  }
}
