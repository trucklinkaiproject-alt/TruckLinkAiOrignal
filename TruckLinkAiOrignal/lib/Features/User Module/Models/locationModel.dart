class LocationModel {
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final String displayName;
  final String? road;
  final String? neighbourhood;
  final String? suburb;
  final String? district;
  final String? state;
  final String? postcode;
  final String? country;
  final String? placeType;
  final String? building;
  final String? amenity;

  LocationModel({
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.displayName = '',
    this.road,
    this.neighbourhood,
    this.suburb,
    this.district,
    this.state,
    this.postcode,
    this.country,
    this.placeType,
    this.building,
    this.amenity,
  });

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'lat': latitude,
      'lng': longitude,
      'display_name': displayName.isNotEmpty ? displayName : address,
      'road': road,
      'neighbourhood': neighbourhood,
      'suburb': suburb,
      'district': district,
      'state': state,
      'postcode': postcode,
      'country': country,
      'place_type': placeType,
      'building': building,
      'amenity': amenity,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    final num? rawLat = map['latitude'] ?? map['lat'] ?? map['pickup_lat'] ?? map['drop_lat'];
    final num? rawLng = map['longitude'] ?? map['lng'] ?? map['lon'] ?? map['pickup_lng'] ?? map['drop_lng'];

    return LocationModel(
      city: (map['city'] ?? map['town'] ?? map['village'] ?? '').toString(),
      address: (map['address'] ?? map['display_name'] ?? '').toString(),
      latitude: rawLat?.toDouble() ?? 0.0,
      longitude: rawLng?.toDouble() ?? 0.0,
      displayName: (map['display_name'] ?? map['displayName'] ?? '').toString(),
      road: map['road']?.toString(),
      neighbourhood: map['neighbourhood']?.toString(),
      suburb: map['suburb']?.toString(),
      district: map['district']?.toString(),
      state: map['state']?.toString(),
      postcode: map['postcode']?.toString(),
      country: map['country']?.toString(),
      placeType: map['place_type']?.toString(),
      building: map['building']?.toString(),
      amenity: map['amenity']?.toString(),
    );
  }

  @override
  String toString() {
    return 'LocationModel(city: $city, address: $address, lat: ${latitude.toStringAsFixed(6)}, lng: ${longitude.toStringAsFixed(6)})';
  }
}