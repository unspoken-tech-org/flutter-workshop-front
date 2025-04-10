import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class DeviceTabsWidget extends StatelessWidget {
  final double width;
  const DeviceTabsWidget({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width * 0.7,
      height: 100,
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width * 0.27,
              child: TabBar(
                tabs: const [
                  Tab(text: 'Contatos'),
                  Tab(text: 'Outros Aparelhos'),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                dividerHeight: 0,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                indicatorPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: WsTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: WsTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(
                children: [
                  Center(child: Text('Conteúdo da aba Informações')),
                  Center(child: Text('Conteúdo da aba Histórico')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
