import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/widgets/shared/status_cell.dart';

class WsDataTable extends StatelessWidget {
  final List<DeviceDataTable> data;
  const WsDataTable({super.key, this.data = const []});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.8,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DataTable(
              showBottomBorder: true,
              dataRowMaxHeight: 60,
              columns: _generateColumns(),
              rows: _genereteRows(data, context),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _generateColumns() {
    return [
      'Id',
      'Cliente',
      'Tipo',
      'Marca',
      'Modelo',
      'Status',
      'Urgencia',
      'Entrada'
    ].map((e) => DataColumn(label: Expanded(child: Text(e)))).toList();
  }

  List<DataRow> _genereteRows(
      List<DeviceDataTable> data, BuildContext context) {
    return data.map((e) {
      return DataRow(
        cells: [
          DataCell(Text(e.deviceId.toString())),
          DataCell(
            Text(e.customerName),
            onTap: () {
              WsNavigator.pushDevice(context, e.deviceId);
            },
          ),
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
