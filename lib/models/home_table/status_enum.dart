import 'package:flutter/material.dart';

enum StatusEnum {
  newDevice(name: 'Novo', value: 'novo', color: Colors.green),
  inProgress(name: 'Em andamento', value: 'em_andamento', color: Colors.blue),
  delivered(
    name: 'Entregue',
    value: 'entregue',
    color: Color.fromARGB(255, 192, 210, 36),
  ),
  waitingApproval(
    name: 'Aguardando Aprovação',
    value: 'aguardando',
    color: Color.fromARGB(214, 140, 127, 8),
  ),
  disposed(name: 'Descartado', value: 'descartado', color: Colors.red),
  ready(name: 'Pronto', value: 'pronto', color: Colors.purple),
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
      case 'pronto':
        return StatusEnum.ready;
      default:
        throw Exception('Status not found');
    }
  }
}
