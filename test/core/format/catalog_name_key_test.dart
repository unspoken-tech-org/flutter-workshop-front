import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/format/catalog_name_key.dart';

void main() {
  group('CatalogNameKey.of', () {
    test('variações de escrita do mesmo nome geram a mesma chave', () {
      for (final name in ['Micro-ondas', 'microondas', '  MICRO ONDAS ']) {
        expect(CatalogNameKey.of(name), 'microondas', reason: name);
      }
    });

    test('remove acentos e mantém dígitos', () {
      expect(CatalogNameKey.of('Ação 100'), 'acao100');
      expect(CatalogNameKey.of('Çãõ ÉÈÊ ÜÑ'), 'caoeeeun');
      expect(CatalogNameKey.of('Galaxy S23 Ultra'), 'galaxys23ultra');
    });

    test('aplica as substituições especiais da API', () {
      expect(CatalogNameKey.of('Straße'), 'strasse');
      expect(CatalogNameKey.of('Æon'), 'aeon');
      expect(CatalogNameKey.of('Cœur'), 'coeur');
      expect(CatalogNameKey.of('Ørsted'), 'orsted');
      expect(CatalogNameKey.of('Đà Lat'), 'dalat');
      expect(CatalogNameKey.of('Łódź'), 'lodz');
    });

    test('aceita diacríticos combinantes já decompostos', () {
      expect(CatalogNameKey.of('Acaõ'), 'acao');
      expect(CatalogNameKey.of('a̧'), 'a');
    });

    test('descarta o que não é [a-z0-9] e devolve vazio sem alfanumérico', () {
      expect(CatalogNameKey.of('A/C - 12.000 BTU\'s'), 'ac12000btus');
      expect(CatalogNameKey.of('  -- '), '');
      expect(CatalogNameKey.of(''), '');
    });
  });
}
