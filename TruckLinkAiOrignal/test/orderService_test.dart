import 'package:flutter_test/flutter_test.dart';
import 'package:trucklinkai_orignal/Core/Services/orderService.dart';

void main() {
  group('OrderService.isValidTransition', () {
    test('allows idempotent transitions (same status to same status)', () {
      expect(OrderService.isValidTransition('pending', 'pending'), isTrue);
      expect(OrderService.isValidTransition('in_transit', 'in_transit'), isTrue);
      expect(OrderService.isValidTransition('completed', 'completed'), isTrue);
    });

    test('allows valid linear forward lifecycle transitions', () {
      expect(OrderService.isValidTransition('pending', 'fare_offered'), isTrue);
      expect(OrderService.isValidTransition('pending', 'accepted'), isTrue);
      expect(OrderService.isValidTransition('pending', 'rejected'), isTrue);
      expect(OrderService.isValidTransition('pending', 'cancelled'), isTrue);

      expect(OrderService.isValidTransition('fare_offered', 'accepted'), isTrue);
      expect(OrderService.isValidTransition('fare_offered', 'rejected'), isTrue);
      expect(OrderService.isValidTransition('fare_offered', 'cancelled'), isTrue);

      expect(OrderService.isValidTransition('accepted', 'driver_offer_sent'), isTrue);
      expect(OrderService.isValidTransition('accepted', 'cancelled'), isTrue);

      expect(OrderService.isValidTransition('driver_offer_sent', 'accepted_by_driver'), isTrue);
      expect(OrderService.isValidTransition('driver_offer_sent', 'rejected_by_driver'), isTrue);
      expect(OrderService.isValidTransition('driver_offer_sent', 'accepted'), isTrue); // reset

      expect(OrderService.isValidTransition('accepted_by_driver', 'in_transit'), isTrue);

      expect(OrderService.isValidTransition('in_transit', 'arrived_at_pickup'), isTrue);
      expect(OrderService.isValidTransition('in_transit', 'heading_to_drop'), isTrue);
      expect(OrderService.isValidTransition('in_transit', 'completed'), isTrue);

      expect(OrderService.isValidTransition('arrived_at_pickup', 'heading_to_drop'), isTrue);
      expect(OrderService.isValidTransition('heading_to_drop', 'completed'), isTrue);
    });

    test('rejects invalid or backwards transitions', () {
      // Completed orders cannot be changed
      expect(OrderService.isValidTransition('completed', 'pending'), isFalse);
      expect(OrderService.isValidTransition('completed', 'in_transit'), isFalse);
      expect(OrderService.isValidTransition('completed', 'cancelled'), isFalse);

      // Cancelled orders cannot be resurrected
      expect(OrderService.isValidTransition('cancelled', 'in_transit'), isFalse);
      expect(OrderService.isValidTransition('cancelled', 'accepted'), isFalse);

      // Jumping directly from pending to in_transit without driver assignment is blocked
      expect(OrderService.isValidTransition('pending', 'in_transit'), isFalse);
      expect(OrderService.isValidTransition('pending', 'completed'), isFalse);

      // Backwards from in_transit to pending is blocked
      expect(OrderService.isValidTransition('in_transit', 'pending'), isFalse);
    });

    test('is case-insensitive and trims whitespace properly', () {
      expect(OrderService.isValidTransition(' PENDING ', 'ACCEPTED '), isTrue);
      expect(OrderService.isValidTransition('In_Transit', 'Completed'), isTrue);
    });
  });
}
