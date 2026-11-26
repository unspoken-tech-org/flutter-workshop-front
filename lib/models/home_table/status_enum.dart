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
  unknown(displayName: 'Desconhecido', dbName: 'DESCONHECIDO');

  final String dbName;
  final String displayName;

  const StatusEnum({required this.dbName, required this.displayName});

  /// OS encerrada (`ENTREGUE`/`DESCARTADO`): a API passa a recusar urgência,
  /// revisão e contatos nela, então o app já os bloqueia (plano §4.3).
  bool get isClosed => this == delivered || this == disposed;

  static List<StatusEnum> get selectableValues =>
      values.where((s) => s != unknown).toList(growable: false);

  static StatusEnum fromDbName(String? dbName) {
    if (dbName == null) {
      debugPrint('Unknown device status: null');
      return StatusEnum.unknown;
    }
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
        debugPrint('Unknown device status: $dbName');
        return StatusEnum.unknown;
    }
  }
}

extension StatusEnumExtension on StatusEnum {
  (Color backgroundColor, Color borderColor, Color textColor) get colors =>
      switch (this) {
        StatusEnum.newDevice => (
          Colors.green.shade100,
          Colors.green.shade200,
          Colors.green.shade800,
        ),
        StatusEnum.inProgress => (
          Colors.blue.shade100,
          Colors.blue.shade200,
          Colors.indigo.shade800,
        ),
        StatusEnum.delivered => (
          Colors.lime.shade100,
          Colors.lime.shade200,
          Colors.lime.shade800,
        ),
        StatusEnum.waitingApproval => (
          Colors.yellow.shade100,
          Colors.yellow.shade200,
          Colors.yellow.shade800,
        ),
        StatusEnum.disposed => (
          Colors.red.shade50,
          Colors.red.shade100,
          Colors.red.shade800,
        ),
        StatusEnum.ready => (
          Colors.green.shade100,
          Colors.green.shade200,
          Colors.green.shade800,
        ),
        StatusEnum.approved => (
          Colors.green.shade100,
          Colors.green.shade200,
          Colors.green.shade800,
        ),
        StatusEnum.notApproved => (
          Colors.red.shade100,
          Colors.red.shade200,
          Colors.red.shade800,
        ),
        StatusEnum.unknown => (
          Colors.grey.shade100,
          Colors.grey.shade300,
          Colors.grey.shade800,
        ),
      };
}
