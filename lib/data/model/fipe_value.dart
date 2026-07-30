class FipeValue {
  final String price;
  final String brand;
  final String model;
  final int modelYear;
  final String fuel;
  final String fipeCode;
  final String referenceMonth;

  const FipeValue({
    required this.price,
    required this.brand,
    required this.model,
    required this.modelYear,
    required this.fuel,
    required this.fipeCode,
    required this.referenceMonth,
  });

  factory FipeValue.fromJson(Map<String, dynamic> json) {
    return FipeValue(
      price: json['Valor']?.toString() ?? '',
      brand: json['Marca']?.toString() ?? '',
      model: json['Modelo']?.toString() ?? '',
      modelYear: int.tryParse(json['AnoModelo']?.toString() ?? '') ?? 0,
      fuel: json['Combustivel']?.toString() ?? '',
      fipeCode: json['CodigoFipe']?.toString() ?? '',
      referenceMonth: json['MesReferencia']?.toString() ?? '',
    );
  }
}
