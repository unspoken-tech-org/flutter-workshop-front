import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';

import '../../../support/fakes/fake_device_repository.dart';
import '../../../support/fixtures/device_statistics_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeController', () {
    test('starts with null statistics, no error, and isLoading=false', () {
      final controller = HomeController(FakeDeviceRepository());

      expect(controller.deviceStatistics, isNull);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test(
      'getDeviceStatistics updates statistics and clears loading on Ok',
      () async {
        final stats = makeDeviceStatistics(
          novo: StatisticsCount(total: 4, lastMonth: 2),
        );
        final repo = FakeDeviceRepository(deviceStatisticsResult: Ok(stats));
        final controller = HomeController(repo);
        final loadingStates = <bool>[];
        controller.addListener(() => loadingStates.add(controller.isLoading));

        await controller.getDeviceStatistics();

        expect(repo.getDeviceStatisticsCalls, 1);
        expect(controller.deviceStatistics, same(stats));
        expect(controller.errorMessage, isNull);
        expect(controller.isLoading, isFalse);
        expect(loadingStates, [true, false]);
      },
    );

    test('getDeviceStatistics records failure message on Err', () async {
      final repo = FakeDeviceRepository(
        deviceStatisticsResult: const Err(
          ValidationFailure(
            message: 'Serviço indisponível',
            code: '503',
            statusCode: 503,
          ),
        ),
      );
      final controller = HomeController(repo);

      await controller.getDeviceStatistics();

      expect(controller.deviceStatistics, isNull);
      expect(controller.errorMessage, 'Serviço indisponível');
      expect(controller.isLoading, isFalse);
    });

    test(
      'getDeviceStatistics uses fallback message when failure has no message',
      () async {
        final repo = FakeDeviceRepository(
          deviceStatisticsResult: const Err(NetworkFailure()),
        );
        final controller = HomeController(repo);

        await controller.getDeviceStatistics();

        expect(
          controller.errorMessage,
          'Erro ao carregar estatísticas. Tente novamente.',
        );
        expect(controller.isLoading, isFalse);
      },
    );

    test(
      'getDeviceStatistics ignores concurrent calls while isLoading=true',
      () async {
        final repo = FakeDeviceRepository(
          deviceStatisticsResult: Ok(makeDeviceStatistics()),
        );
        final controller = HomeController(repo)..isLoading = true;

        await controller.getDeviceStatistics();

        expect(repo.getDeviceStatisticsCalls, 0);
        expect(controller.isLoading, isTrue);
      },
    );
  });
}
