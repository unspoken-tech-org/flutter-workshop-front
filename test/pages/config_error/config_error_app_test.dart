import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/pages/config_error/config_error_app.dart';

void main() {
  testWidgets('mostra a mensagem do AppConfigException', (tester) async {
    await tester.pumpWidget(
      const ConfigErrorApp(message: 'BASE_URL deve usar https://'),
    );

    expect(find.text('Configuração do aplicativo inválida'), findsOneWidget);
    expect(find.text('BASE_URL deve usar https://'), findsOneWidget);
  });
}
