import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/logging/windows_foreground.dart';

void main() {
  const path =
      r'C:\Users\Ana\AppData\Roaming\com.example\flutter_workshop_front\logs';

  group('WindowsForeground.titleMatches', () {
    test('matches the folder name', () {
      expect(WindowsForeground.titleMatches('logs', path), isTrue);
      expect(WindowsForeground.titleMatches('Logs', '$path\\'), isTrue);
    });

    test('matches the localized Explorer suffix', () {
      expect(
        WindowsForeground.titleMatches('logs - Explorador de Arquivos', path),
        isTrue,
      );
    });

    test('matches the full path title', () {
      expect(WindowsForeground.titleMatches(path, path), isTrue);
    });

    test('rejects other folders', () {
      expect(WindowsForeground.titleMatches('Downloads', path), isFalse);
      expect(WindowsForeground.titleMatches('logs-old', path), isFalse);
      expect(WindowsForeground.titleMatches('', path), isFalse);
    });
  });
}
