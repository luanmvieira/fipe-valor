class FipeOption {
  final String code;
  final String name;

  const FipeOption({required this.code, required this.name});

  factory FipeOption.fromJson(Map<String, dynamic> json) {
    return FipeOption(code: json['codigo'].toString(), name: json['nome'].toString());
  }
}
