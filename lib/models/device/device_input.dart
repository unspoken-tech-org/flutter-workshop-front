import 'package:flutter_workshop_front/models/types_brands_models/type_brand_model_input.dart';

class DeviceInput {
  final int customerId;
  final int? technicianId;
  final String problem;
  final String observation;
  final double? budgetValue;
  final bool hasUrgency;
  final TypeBrandModelInput typeBrandModel;
  final List<String> colors;

  DeviceInput({
    required this.customerId,
    required this.problem,
    required this.observation,
    required this.typeBrandModel,
    required this.colors,
    this.budgetValue,
    this.technicianId,
    this.hasUrgency = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'problem': problem,
      'observation': observation,
      'budgetValue': budgetValue,
      'hasUrgency': hasUrgency,
      'typeBrandModel': typeBrandModel.toJson(),
      'colors': colors,
    };
  }
}
