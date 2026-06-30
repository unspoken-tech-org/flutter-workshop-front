import 'package:flutter_workshop_front/models/types_brands_models/type_brand_model_input.dart';

class DeviceInput {
  final int? customerId;
  final int? technicianId;
  final String? problem;
  final String? observation;
  final double? budgetFee;
  final bool hasUrgency;
  final TypeBrandModelInput? typeBrandModel;
  final List<String>? colors;

  DeviceInput({
    this.customerId,
    this.problem,
    this.observation,
    this.typeBrandModel,
    this.colors,
    this.budgetFee,
    this.technicianId,
    this.hasUrgency = false,
  });

  factory DeviceInput.empty() =>
      DeviceInput(typeBrandModel: TypeBrandModelInput.empty());

  DeviceInput copyWith({
    int? customerId,
    int? technicianId,
    String? problem,
    String? observation,
    TypeBrandModelInput? typeBrandModel,
    List<String>? colors,
    double? budgetFee,
    bool? hasUrgency,
  }) => DeviceInput(
    customerId: customerId ?? this.customerId,
    technicianId: technicianId ?? this.technicianId,
    problem: problem ?? this.problem,
    observation: observation ?? this.observation,
    typeBrandModel: typeBrandModel ?? this.typeBrandModel,
    colors: colors ?? this.colors,
    budgetFee: budgetFee ?? this.budgetFee,
    hasUrgency: hasUrgency ?? this.hasUrgency,
  );

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'problem': problem,
      'observation': observation,
      'budgetFee': budgetFee,
      'hasUrgency': hasUrgency,
      'technicianId': technicianId,
      'typeBrandModel': typeBrandModel?.toJson(),
      'colors': colors,
    };
  }
}
