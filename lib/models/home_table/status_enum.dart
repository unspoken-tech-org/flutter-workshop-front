import 'package:flutter/material.dart';

enum StatusEnum {
  newDevice(name: 'Novo', value: 'novo', color: Colors.green),
  inProgress(name: 'Em andamento', value: 'em_andamento', color: Colors.blue),
  waitingApproval(
    name: 'Aguardando Aprovação',
    value: 'aguardando',
    color: Color.fromARGB(214, 140, 127, 8),
  ),
  delivered(name: 'Entregue', value: 'entregue', color: Colors.lime),
  disposed(name: 'Descartado', value: 'descartado', color: Colors.red),
  ;

  final String value;
  final String name;
  final Color color;

  const StatusEnum({
    required this.value,
    required this.name,
    required this.color,
  });

  static StatusEnum fromString(String value) {
    switch (value) {
      case 'em_andamento':
        return StatusEnum.inProgress;
      case 'aguardando':
        return StatusEnum.waitingApproval;
      case 'novo':
        return StatusEnum.newDevice;
      case 'descartado':
        return StatusEnum.disposed;
      case 'entregue':
        return StatusEnum.delivered;
      default:
        throw Exception('Status not found');
    }
  }
}
