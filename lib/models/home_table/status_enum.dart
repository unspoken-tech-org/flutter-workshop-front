import 'package:flutter/material.dart';

enum StatusEnum {
  newDevice(displayName: 'Novo', dbName: 'novo'),
  inProgress(displayName: 'Em andamento', dbName: 'em_andamento'),
  delivered(displayName: 'Entregue', dbName: 'entregue'),
  waitingApproval(displayName: 'Aguardando Aprovação', dbName: 'aguardando'),
  disposed(displayName: 'Descartado', dbName: 'descartado'),
  ready(displayName: 'Pronto', dbName: 'pronto'),
  ;

  final String dbName;
  final String displayName;

  const StatusEnum({
    required this.dbName,
    required this.displayName,
  });

  static StatusEnum fromDbName(String dbName) {
    switch (dbName) {
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

extension StatusEnumExtension on StatusEnum {
  (Color backgroundColor, Color textColor) get colors => switch (this) {
        StatusEnum.newDevice => (Colors.green.shade100, Colors.green),
        StatusEnum.inProgress => (Colors.blue.shade100, Colors.blue),
        StatusEnum.delivered => (
            Colors.yellow.shade100,
            Colors.yellow.shade800
          ),
        StatusEnum.waitingApproval => (
            Colors.lime.shade100,
            Colors.lime.shade700
          ),
        StatusEnum.disposed => (Colors.red.shade100, Colors.red),
        StatusEnum.ready => (Colors.purple.shade100, Colors.purple),
      };
}
