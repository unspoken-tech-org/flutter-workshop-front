import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/services/update/update_service.dart';
import 'package:flutter_workshop_front/widgets/shared/update_dialog.dart';

Widget _wrapDialog(UpdateInfo info) {
  return MaterialApp(
    home: Scaffold(
      body: UpdateDialog(updateInfo: info, onDownload: () {}),
    ),
  );
}

void main() {
  group('UpdateDialog cumulative release notes', () {
    testWidgets('renders single-version update dialog without expand toggle', (
      tester,
    ) async {
      final info = UpdateInfo(
        latestVersion: '1.6.0',
        currentVersion: '1.5.0',
        downloadUrl: 'https://example.com/setup.exe',
        releaseNotes: '- Novo recurso único',
        publishedAt: DateTime(2026, 11, 22, 14, 30),
        releaseHistory: [
          ReleaseNoteEntry(
            version: '1.6.0',
            notes: '- Novo recurso único',
            publishedAt: DateTime(2026, 11, 22, 14, 30),
          ),
        ],
      );

      await tester.pumpWidget(_wrapDialog(info));

      expect(find.text('Atualização Disponível'), findsOneWidget);
      expect(find.text('Novidades'), findsOneWidget);
      expect(find.text('v1.6.0'), findsOneWidget);
      expect(find.text('22/11/2026'), findsOneWidget);
      expect(find.text('- Novo recurso único'), findsOneWidget);
      expect(find.text('Mais recente'), findsNothing);
      expect(find.textContaining('Ver mais'), findsNothing);
      expect(
        find.textContaining('Exibindo apenas as versões mais recentes'),
        findsNothing,
      );
    });

    testWidgets('falls back to releaseNotes when releaseHistory is empty', (
      tester,
    ) async {
      final info = UpdateInfo(
        latestVersion: '1.6.0',
        currentVersion: '1.5.0',
        downloadUrl: 'https://example.com/setup.exe',
        releaseNotes: 'Notas legadas',
        publishedAt: DateTime(2026, 11, 22),
      );

      await tester.pumpWidget(_wrapDialog(info));

      expect(find.text('Novidades'), findsOneWidget);
      expect(find.text('Notas legadas'), findsOneWidget);
    });

    testWidgets(
      'renders multi-version dialog with progressive disclosure for >3 versions',
      (tester) async {
        final entries = [
          ReleaseNoteEntry(
            version: '1.5.0',
            notes: 'Notas da 1.5.0',
            publishedAt: DateTime(2026, 11, 22),
          ),
          ReleaseNoteEntry(
            version: '1.4.0',
            notes: 'Notas da 1.4.0',
            publishedAt: DateTime(2026, 11, 20),
          ),
          ReleaseNoteEntry(
            version: '1.3.0',
            notes: 'Notas da 1.3.0',
            publishedAt: DateTime(2026, 11, 18),
          ),
          ReleaseNoteEntry(
            version: '1.2.0',
            notes: 'Notas da 1.2.0',
            publishedAt: DateTime(2026, 11, 16),
          ),
          ReleaseNoteEntry(
            version: '1.1.0',
            notes: 'Notas da 1.1.0',
            publishedAt: DateTime(2026, 11, 14),
          ),
        ];

        final info = UpdateInfo(
          latestVersion: '1.5.0',
          currentVersion: '1.0.0',
          downloadUrl: 'https://example.com/setup.exe',
          releaseNotes: entries.first.notes,
          publishedAt: entries.first.publishedAt,
          releaseHistory: entries,
        );

        await tester.pumpWidget(_wrapDialog(info));

        expect(find.text('Novidades (5 versões)'), findsOneWidget);
        expect(find.text('Mais recente'), findsOneWidget);
        expect(find.text('v1.5.0'), findsOneWidget);
        expect(find.text('v1.4.0'), findsOneWidget);
        expect(find.text('v1.3.0'), findsOneWidget);
        expect(find.text('v1.2.0'), findsNothing);
        expect(find.text('v1.1.0'), findsNothing);
        expect(find.text('Ver mais 2 versões anteriores'), findsOneWidget);

        final expandButton = find.text('Ver mais 2 versões anteriores');
        await tester.ensureVisible(expandButton);
        await tester.pumpAndSettle();
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        expect(find.text('v1.2.0'), findsOneWidget);
        expect(find.text('v1.1.0'), findsOneWidget);
        final collapseButton = find.text('Mostrar menos');
        expect(collapseButton, findsOneWidget);

        await tester.ensureVisible(collapseButton);
        await tester.pumpAndSettle();
        await tester.tap(collapseButton);
        await tester.pumpAndSettle();

        expect(find.text('v1.2.0'), findsNothing);
        expect(find.text('v1.1.0'), findsNothing);
        expect(find.text('Ver mais 2 versões anteriores'), findsOneWidget);
      },
    );

    testWidgets(
      'shows truncated history notice when hasTruncatedHistory is true',
      (tester) async {
        final info = UpdateInfo(
          latestVersion: '2.0.0',
          currentVersion: '1.0.0',
          downloadUrl: 'https://example.com/setup.exe',
          releaseNotes: 'Notas 2.0.0',
          publishedAt: DateTime(2026, 11, 22),
          releaseHistory: [
            ReleaseNoteEntry(
              version: '2.0.0',
              notes: 'Notas 2.0.0',
              publishedAt: DateTime(2026, 11, 22),
            ),
            ReleaseNoteEntry(
              version: '1.9.0',
              notes: 'Notas 1.9.0',
              publishedAt: DateTime(2026, 11, 20),
            ),
          ],
          hasTruncatedHistory: true,
        );

        await tester.pumpWidget(_wrapDialog(info));

        expect(
          find.text(
            'Exibindo apenas as versões mais recentes. Consulte o GitHub para o histórico completo.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders up-to-date dialog without release notes or download CTA',
      (tester) async {
        final info = UpdateInfo(
          latestVersion: '1.5.0',
          currentVersion: '1.5.0',
          downloadUrl: 'https://example.com/setup.exe',
          releaseNotes: 'Notas 1.5.0',
          publishedAt: DateTime(2026, 11, 22),
        );

        await tester.pumpWidget(_wrapDialog(info));

        expect(find.text('Você está atualizado'), findsOneWidget);
        expect(find.text('1.5.0'), findsOneWidget);
        expect(find.text('Novidades'), findsNothing);
        expect(find.text('Baixar Atualização'), findsNothing);
        expect(find.text('Atualizar Agora'), findsNothing);
        expect(find.text('Depois'), findsOneWidget);
      },
    );
  });
}
