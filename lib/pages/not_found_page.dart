import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WsScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/not_found.png'),
            const SizedBox(height: 16),
            Text(
              'Página não encontrada',
              style: WsTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              'O conteúdo que você está procurando não existe.',
              style: WsTextStyles.body1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
