import 'package:flutter/material.dart';

enum StatusEnum {
  newDevice(displayName: 'Novo', dbName: 'NOVO'),
  inProgress(displayName: 'Em andamento', dbName: 'EM_ANDAMENTO'),
  delivered(displayName: 'Entregue', dbName: 'ENTREGUE'),
  waitingApproval(displayName: 'Aguardando Aprovação', dbName: 'AGUARDANDO'),
  approved(displayName: 'Aprovado', dbName: 'APROVADO'),
  notApproved(displayName: 'Não aprovado', dbName: 'NAO_APROVADO'),
  disposed(displayName: 'Descartado', dbName: 'DESCARTADO'),
  ready(displayName: 'Pronto', dbName: 'PRONTO'),
  ;

  final String dbName;
  final String displayName;

  const StatusEnum({
    required this.dbName,
    required this.displayName,
  });

  static StatusEnum fromDbName(String dbName) {
    switch (dbName.toUpperCase()) {
      case 'EM_ANDAMENTO':
        return StatusEnum.inProgress;
      case 'AGUARDANDO':
        return StatusEnum.waitingApproval;
      case 'NOVO':
        return StatusEnum.newDevice;
      case 'DESCARTADO':
        return StatusEnum.disposed;
      case 'ENTREGUE':
        return StatusEnum.delivered;
      case 'PRONTO':
        return StatusEnum.ready;
      case 'APROVADO':
        return StatusEnum.approved;
      case 'NAO_APROVADO':
        return StatusEnum.notApproved;
      default:
        throw Exception('Status not found');
    }
  }
}

extension StatusEnumExtension on StatusEnum {
  (Color backgroundColor, Color borderColor, Color textColor) get colors =>
      switch (this) {
        StatusEnum.newDevice => (
            Colors.green.shade100,
            Colors.green.shade200,
            Colors.green.shade800
          ),
        StatusEnum.inProgress => (
            Colors.blue.shade100,
            Colors.blue.shade200,
            Colors.indigo.shade800
          ),
        StatusEnum.delivered => (
            Colors.lime.shade100,
            Colors.lime.shade200,
            Colors.lime.shade800
          ),
        StatusEnum.waitingApproval => (
            Colors.yellow.shade100,
            Colors.yellow.shade200,
            Colors.yellow.shade800
          ),
        StatusEnum.disposed => (
            Colors.red.shade50,
            Colors.red.shade100,
            Colors.red.shade800
          ),
        StatusEnum.ready => (
            Colors.green.shade100,
            Colors.green.shade200,
            Colors.green.shade800
          ),
        StatusEnum.approved => (
            Colors.green.shade100,
            Colors.green.shade200,
            Colors.green.shade800
          ),
        StatusEnum.notApproved => (
            Colors.red.shade100,
            Colors.red.shade200,
            Colors.red.shade800
          ),
      };
}
