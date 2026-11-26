import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';
import 'package:flutter_workshop_front/core/ui/command.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';

class HomeController extends ChangeNotifier
    with SafeChangeNotifierMixin, UiMessageSource {
  final DeviceRepository _deviceRepository;

  HomeController(this._deviceRepository) {
    loadStatistics = Command<void, DeviceStatistics>((_) => _load())
      ..addListener(notifyListeners);
  }

  /// Carga das estatísticas (flag [Command.running] e último resultado).
  late final Command<void, DeviceStatistics> loadStatistics;

  DeviceStatistics? deviceStatistics;
  String? errorMessage;

  bool get isLoading => loadStatistics.running;

  Future<Result<DeviceStatistics>> _load() async {
    errorMessage = null;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final result = await _deviceRepository.getDeviceStatistics();
    switch (result) {
      case Ok(:final value):
        deviceStatistics = value;
      case Err(:final failure):
        final message = failure.messageOr(
          'Erro ao carregar estatísticas. Tente novamente.',
        );
        errorMessage = message;
        emitError(message);
        debugPrint(
          '[HomeController] Error getting device statistics: $failure',
        );
    }
    return result;
  }

  Future<void> getDeviceStatistics() async {
    await loadStatistics.execute(null);
  }

  @override
  void dispose() {
    loadStatistics.dispose();
    super.dispose();
  }
}
