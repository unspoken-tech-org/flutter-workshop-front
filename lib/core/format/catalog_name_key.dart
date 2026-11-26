/// Chave de comparação de nomes do catálogo (tipo, marca, modelo).
///
/// Espelha `CatalogName.nameKey` da API (e o SQL
/// `regexp_replace(lower(unaccent(nome)), '[^a-z0-9]', '', 'g')`): a API
/// não expõe `name_key`, então o app calcula a mesma chave para detectar que
/// um nome digitado "já existe" ("Micro-ondas" == "microondas").
///
/// Passos: minúsculas → `ß→ss`, `æ→ae`, `œ→oe`, `ø→o`, `đ→d`, `ł→l` →
/// remoção de acentos → só `[a-z0-9]`.
///
/// Limite: o Dart não traz normalização NFD. A remoção de acentos usa uma
/// tabela das letras latinas com decomposição NFD de Latin-1 e Latin
/// Extended-A (cobre português, espanhol, francês, alemão, etc.), mais os
/// diacríticos combinantes U+0300–U+036F já soltos no texto. Letras fora
/// dessa tabela (ex.: vietnamita com duplo acento) caem na regra final e
/// são descartadas, como qualquer caractere que não seja `[a-z0-9]`.
abstract final class CatalogNameKey {
  static const _special = {
    'ß': 'ss',
    'æ': 'ae',
    'œ': 'oe',
    'ø': 'o',
    'đ': 'd',
    'ł': 'l',
  };

  // Letras base -> variantes minúsculas que o NFD decompõe nela.
  static const _accented = {
    'a': 'àáâãäåāăąǎ',
    'c': 'çćĉċč',
    'd': 'ď',
    'e': 'èéêëēĕėęě',
    'g': 'ĝğġģ',
    'h': 'ĥ',
    'i': 'ìíîïĩīĭįǐi̇',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ĺļľ',
    'n': 'ñńņňǹ',
    'o': 'òóôõöōŏőǒ',
    'r': 'ŕŗř',
    's': 'śŝşš',
    't': 'ţť',
    'u': 'ùúûüũūŭůűųǔ',
    'w': 'ŵ',
    'y': 'ýÿŷ',
    'z': 'źżž',
  };

  static final Map<String, String> _fold = {
    ..._special,
    for (final entry in _accented.entries)
      for (final rune in entry.value.runes)
        String.fromCharCode(rune): entry.key,
  };

  static final RegExp _combiningMarks = RegExp('[̀-ͯ]');
  static final RegExp _nonAlnum = RegExp('[^a-z0-9]');

  /// Chave de [name]; vazia se não sobrar nenhum `[a-z0-9]`.
  static String of(String name) {
    final buffer = StringBuffer();
    for (final rune in name.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_fold[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(_combiningMarks, '')
        .replaceAll(_nonAlnum, '');
  }
}
