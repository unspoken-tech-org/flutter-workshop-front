enum StatusEnum {
  newDevice(name: 'Novo', value: 'novo'),
  inProgress(name: 'Em andamento', value: 'em_andamento'),
  waitingApproval(name: 'Aguardando Aprovação', value: 'aguardando'),
  delivered(name: 'Entregue', value: 'entregue'),
  disposed(name: 'Descartado', value: 'descartado'),
  ;

  final String value;
  final String name;

  const StatusEnum({required this.value, required this.name});

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
