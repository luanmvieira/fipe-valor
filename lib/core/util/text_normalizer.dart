String normalizeText(String input) {
  const accented = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const plain = 'aaaaaeeeeiiiiooooouuuucn';

  var result = input.toLowerCase().trim();
  for (var i = 0; i < accented.length; i++) {
    result = result.replaceAll(accented[i], plain[i]);
  }
  return result.replaceAll(RegExp(r'\s+'), ' ');
}
