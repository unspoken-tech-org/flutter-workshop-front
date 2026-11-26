import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/models/types_brands_models/type_brand_model_input.dart';

class DeviceInput {
  final int? customerId;
  final int? technicianId;
  final String? problem;
  final String? observation;
  final Money? budgetFee;
  final bool hasUrgency;
  final TypeBrandModelInput? typeBrandModel;
  final List<String>? colors;

  /// OS de origem de uma revisão (`originOrderId` + `revision`, plano §4.3).
  /// Só vão no JSON quando preenchidos; APIs que não os conhecem os ignoram.
  final int? originOrderId;
  final bool revision;

  DeviceInput({
    this.customerId,
    this.problem,
    this.observation,
    this.typeBrandModel,
    this.colors,
    this.budgetFee,
    this.technicianId,
    this.hasUrgency = false,
    this.originOrderId,
    this.revision = false,
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
    Money? budgetFee,
    bool? hasUrgency,
    int? originOrderId,
    bool? revision,
  }) => DeviceInput(
    customerId: customerId ?? this.customerId,
    technicianId: technicianId ?? this.technicianId,
    problem: problem ?? this.problem,
    observation: observation ?? this.observation,
    typeBrandModel: typeBrandModel ?? this.typeBrandModel,
    colors: colors ?? this.colors,
    budgetFee: budgetFee ?? this.budgetFee,
    hasUrgency: hasUrgency ?? this.hasUrgency,
    originOrderId: originOrderId ?? this.originOrderId,
    revision: revision ?? this.revision,
  );

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'problem': problem,
      'observation': observation,
      'budgetFee': budgetFee?.toJson(),
      'hasUrgency': hasUrgency,
      'technicianId': technicianId,
      'typeBrandModel': typeBrandModel?.toJson(),
      'colors': colors,
      if (originOrderId != null) 'originOrderId': originOrderId,
      if (revision) 'revision': true,
    };
  }
}
