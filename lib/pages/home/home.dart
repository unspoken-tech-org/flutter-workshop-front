import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';

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
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ],
    ));
  }
}

class WsDataTable extends StatelessWidget {
  final List<DeviceDataTable> data;
  const WsDataTable({super.key, this.data = const []});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      width: 1300,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: DataTable(
            showBottomBorder: true,
            columns: _generateColumns(),
            rows: _genereteRows(data),
          ),
        ),
      ]),
    );
  }

  List<DataColumn> _generateColumns() {
    return [
      const DataColumn(
        label: Expanded(
          child: Text('Id'),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text('Cliente'),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text('Tipo'),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text('Marca'),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text('Modelo'),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text('Status'),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text('Urgencia'),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Text('Entrada'),
        ),
      ),
    ];
  }

  List<DataRow> _genereteRows(List<DeviceDataTable> data) {
    return data.map((e) {
      return DataRow(
        onLongPress: () {
          print('Long press');
        },
        cells: [
          DataCell(Text(e.deviceId.toString())),
          DataCell(Text(e.customerName)),
          DataCell(Text(e.type)),
          DataCell(Text(e.brand)),
          DataCell(Text(e.model)),
          DataCell(StatusCell(status: e.status)),
          DataCell(Text(e.hasUrgency ? 'Sim' : 'Não')),
          DataCell(Text(e.entryDate)),
        ],
      );
    }).toList();
  }
}

class StatusCell extends StatelessWidget {
  final StatusEnum status;
  const StatusCell({super.key, required this.status});

  Color _getColor(StatusEnum status) {
    switch (status) {
      case StatusEnum.inProgress:
        return Colors.blue;
      case StatusEnum.waitingApproval:
        return const Color.fromARGB(214, 140, 127, 8);
      case StatusEnum.newDevice:
        return Colors.green;
      case StatusEnum.disposed:
        return Colors.red;
      case StatusEnum.delivered:
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getColor(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}

var dataMock = [
  DeviceDataTable(
    deviceId: 1,
    customerId: 1,
    customerName: 'João',
    type: 'Celular',
    brand: 'Samsung',
    model: 'Galaxy S10',
    status: StatusEnum.newDevice,
    problem: 'Tela quebrada',
    hasUrgency: true,
    entryDate: '2021-10-10',
  ),
  DeviceDataTable(
    deviceId: 2,
    customerId: 2,
    customerName: 'Maria',
    type: 'Notebook',
    brand: 'Dell',
    model: 'Inspiron 15',
    status: StatusEnum.inProgress,
    problem: 'Não liga',
    hasUrgency: false,
    entryDate: '2021-10-10',
  ),
  DeviceDataTable(
    deviceId: 3,
    customerId: 3,
    customerName: 'José',
    type: 'Tablet',
    brand: 'Apple',
    model: 'iPad',
    status: StatusEnum.disposed,
    problem: 'Tela quebrada',
    hasUrgency: true,
    entryDate: '2021-10-10',
  ),
];
