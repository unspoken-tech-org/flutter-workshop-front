class TypeBrandModelInput {
  final String type;
  final String brand;
  final String model;

  TypeBrandModelInput({
    required this.type,
    required this.brand,
    required this.model,
  });

  factory TypeBrandModelInput.empty() => TypeBrandModelInput(
        type: '',
        brand: '',
        model: '',
      );

  TypeBrandModelInput copyWith({
    String? type,
    String? brand,
    String? model,
  }) =>
      TypeBrandModelInput(
        type: type ?? this.type,
        brand: brand ?? this.brand,
        model: model ?? this.model,
      );

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'brand': brand,
      'model': model,
    };
  }
}
