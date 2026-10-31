import 'package:flutter_test/flutter_test.dart';
import 'package:trucklinkai_orignal/Core/Services/brokerStatsService.dart';

void main() {
  group('BrokerStatsService.computeRates', () {
    test('computes correct rates for valid positive counts', () {
      final rates = BrokerStatsService.computeRates(
        total: 10,
        accepted: 8,
        cancelled: 2,
        completed: 6,
      );

      expect(rates['total_requests'], 10);
      expect(rates['accepted_requests'], 8);
      expect(rates['cancelled_requests'], 2);
      expect(rates['completed_requests'], 6);

      // acceptance_rate = 8 / 10 = 80.0%
      expect(rates['acceptance_rate'], 80.0);
      // cancellation_rate = 2 / 10 = 20.0%
      expect(rates['cancellation_rate'], 20.0);
      // completion_rate = 6 / 8 = 75.0%
      expect(rates['completion_rate'], 75.0);
    });

    test('handles zero total requests safely without NaN or Infinity', () {
      final rates = BrokerStatsService.computeRates(
        total: 0,
        accepted: 0,
        cancelled: 0,
        completed: 0,
      );

      expect(rates['acceptance_rate'], 0.0);
      expect(rates['cancellation_rate'], 0.0);
      expect(rates['completion_rate'], 0.0);
    });

    test('handles 100% completion rate when all accepted requests are completed', () {
      final rates = BrokerStatsService.computeRates(
        total: 5,
        accepted: 5,
        cancelled: 0,
        completed: 5,
      );

      expect(rates['acceptance_rate'], 100.0);
      expect(rates['cancellation_rate'], 0.0);
      expect(rates['completion_rate'], 100.0);
    });

    test('rounds fractional percentages to one decimal place accurately', () {
      final rates = BrokerStatsService.computeRates(
        total: 3,
        accepted: 1,
        cancelled: 1,
        completed: 1,
      );

      // 1 / 3 = 33.3333...% -> 33.3%
      expect(rates['acceptance_rate'], 33.3);
      expect(rates['cancellation_rate'], 33.3);
      expect(rates['completion_rate'], 100.0);
    });
  });
}
