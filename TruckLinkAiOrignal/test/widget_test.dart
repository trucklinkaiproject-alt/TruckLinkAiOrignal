import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/locationModel.dart';

void main() {
  test('LocationModel and LatLng instantiation smoke test', () {
    const latLng = LatLng(34.1688, 73.2215);
    expect(latLng.latitude, 34.1688);
    expect(latLng.longitude, 73.2215);

    final loc = LocationModel(
      city: 'Islamabad',
      address: 'Islamabad, Pakistan',
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    expect(loc.city, 'Islamabad');
    expect(loc.latitude, 34.1688);
  });
}
