import 'package:flutter_test/flutter_test.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerCubit.dart';

void main() {
  group('GetBrokerCubit.matchesVehicleType', () {
    test('matches exact strings identically', () {
      expect(GetBrokerCubit.matchesVehicleType('Trailer', 'Trailer'), isTrue);
      expect(GetBrokerCubit.matchesVehicleType('Truck', 'Truck'), isTrue);
      expect(GetBrokerCubit.matchesVehicleType('Container', 'Container'), isTrue);
      expect(GetBrokerCubit.matchesVehicleType('Shahzore', 'Shahzore'), isTrue);
    });

    test('matches case-insensitively with varying spaces and hyphens', () {
      expect(GetBrokerCubit.matchesVehicleType('trailer', 'Trailer'), isTrue);
      expect(GetBrokerCubit.matchesVehicleType('PICKUP TRUCK', 'PickUp Truck'), isTrue);
      expect(GetBrokerCubit.matchesVehicleType('pickup-truck', 'PickUp Truck'), isTrue);
      expect(GetBrokerCubit.matchesVehicleType('loader_rickshaw', 'Loader Rickshaw'), isTrue);
    });

    test('matches compound vehicle types like Trailer Truck to Trailer', () {
      expect(GetBrokerCubit.matchesVehicleType('Trailer Truck', 'Trailer'), isTrue);
      expect(GetBrokerCubit.matchesVehicleType('Container Truck', 'Container'), isTrue);
    });

    test('rejects mismatched vehicle types', () {
      expect(GetBrokerCubit.matchesVehicleType('Truck', 'Trailer'), isFalse);
      expect(GetBrokerCubit.matchesVehicleType('Loader Rickshaw', 'Shahzore'), isFalse);
      expect(GetBrokerCubit.matchesVehicleType('Van', 'Container'), isFalse);
    });

    test('handles null, empty, or whitespace safely without throwing', () {
      expect(GetBrokerCubit.matchesVehicleType(null, 'Trailer'), isFalse);
      expect(GetBrokerCubit.matchesVehicleType('', 'Trailer'), isFalse);
      expect(GetBrokerCubit.matchesVehicleType('   ', 'Trailer'), isFalse);
    });
  });
}
