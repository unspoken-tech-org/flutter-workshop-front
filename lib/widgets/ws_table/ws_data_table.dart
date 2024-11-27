import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class WsDataTable extends StatelessWidget {
  final List<DeviceDataTable> data;
  const WsDataTable({super.key, this.data = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
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
              rows: _genereteRows(data),
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

  List<DataRow> _genereteRows(List<DeviceDataTable> data) {
    return data.map((e) {
      return DataRow(
        cells: [
          DataCell(Text(e.deviceId.toString())),
          DataCell(
            Text(e.customerName),
            onDoubleTap: () {
              debugPrint('double tap');
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
