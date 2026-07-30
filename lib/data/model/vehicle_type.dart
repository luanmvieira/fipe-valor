enum VehicleType {
  carros('carros', 'Carros'),
  motos('motos', 'Motos'),
  caminhoes('caminhoes', 'Caminhões');

  final String path;
  final String label;

  const VehicleType(this.path, this.label);
}
