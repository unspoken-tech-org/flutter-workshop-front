import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
import 'package:flutter_workshop_front/services/device_statistics/device_statistics_service.dart';

class HomeController extends ChangeNotifier {
  final DeviceStatisticsService _deviceStatisticsService =
      DeviceStatisticsService();

  HomeController();

  DeviceStatistics? deviceStatistics;
  bool isLoading = true;

  Future<void> getDeviceStatistics() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));
    deviceStatistics = await _deviceStatisticsService.getDeviceStatistics();
    isLoading = false;
    notifyListeners();
  }
}
