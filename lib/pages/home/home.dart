import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/ws_table/ws_data_table.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeController controller = HomeController();

  @override
  void initState() {
    controller.getTableData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WsScaffold(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ValueListenableBuilder(
          valueListenable: controller.loadingState,
          builder: (context, value, _) {
            if (controller.loadingState.value.isTableLoading) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return WsDataTable(data: controller.tableData.value);
          },
        ),
      ],
    ));
  }
}
