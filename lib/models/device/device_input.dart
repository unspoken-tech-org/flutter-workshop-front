import 'package:flutter_workshop_front/models/types_brands_models/type_brand_model_input.dart';

class DeviceInput {
  final int? customerId;
  final int? technicianId;
  final String? problem;
  final String? observation;
  final double? budgetValue;
  final bool hasUrgency;
  final TypeBrandModelInput? typeBrandModel;
  final List<String>? colors;

  DeviceInput({
    this.customerId,
    this.problem,
    this.observation,
    this.typeBrandModel,
    this.colors,
    this.budgetValue,
    this.technicianId,
    this.hasUrgency = false,
  });

  factory DeviceInput.empty() => DeviceInput(
        typeBrandModel: TypeBrandModelInput.empty(),
      );

  DeviceInput copyWith({
    int? customerId,
    int? technicianId,
    String? problem,
    String? observation,
    TypeBrandModelInput? typeBrandModel,
    List<String>? colors,
    double? budgetValue,
    bool? hasUrgency,
  }) =>
      DeviceInput(
        customerId: customerId ?? this.customerId,
        technicianId: technicianId ?? this.technicianId,
        problem: problem ?? this.problem,
        observation: observation ?? this.observation,
        typeBrandModel: typeBrandModel ?? this.typeBrandModel,
        colors: colors ?? this.colors,
        budgetValue: budgetValue ?? this.budgetValue,
        hasUrgency: hasUrgency ?? this.hasUrgency,
      );

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'problem': problem,
      'observation': observation,
      'budgetValue': budgetValue,
      'hasUrgency': hasUrgency,
      'technicianId': technicianId,
      'typeBrandModel': typeBrandModel?.toJson(),
      'colors': colors,
    };
  }
}
