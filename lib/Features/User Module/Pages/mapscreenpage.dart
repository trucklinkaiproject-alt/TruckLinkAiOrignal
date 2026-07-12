// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/Models/locationModel.dart';


// class MapPickerScreen extends StatefulWidget {
//   const MapPickerScreen({super.key});

//   @override
//   State<MapPickerScreen> createState() => _MapPickerScreenState();
// }

// class _MapPickerScreenState extends State<MapPickerScreen> {
//   final MapController mapController = MapController();

//   final TextEditingController searchController =
//       TextEditingController();

//   LatLng selectedLocation =
//       const LatLng(34.1688, 73.2215);

//   String address = "Tap on map";

//   bool loading = false;

//   @override
//   void initState() {
//     super.initState();
//     getCurrentLocation();
//   }

//   Future<void> getCurrentLocation() async {
//     try {
//       bool serviceEnabled =
//           await Geolocator.isLocationServiceEnabled();

//       if (!serviceEnabled) return;

//       LocationPermission permission =
//           await Geolocator.checkPermission();

//       if (permission == LocationPermission.denied) {
//         permission =
//             await Geolocator.requestPermission();
//       }

//       Position position =
//           await Geolocator.getCurrentPosition();

//       LatLng current = LatLng(
//         position.latitude,
//         position.longitude,
//       );

//       setState(() {
//         selectedLocation = current;
//       });

//       mapController.move(current, 16);

//       await reverseGeocode(current);
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//   }

//   Future<void> reverseGeocode(
//     LatLng point,
//   ) async {
//     try {
//       List<Placemark> placemarks =
//           await placemarkFromCoordinates(
//         point.latitude,
//         point.longitude,
//       );

//       Placemark place = placemarks.first;

//       setState(() {
//         address =
//             "${place.street}, ${place.locality}, ${place.administrativeArea}";
//       });
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//   }

//   Future<void> searchLocation() async {
//     if (searchController.text.trim().isEmpty) {
//       return;
//     }

//     try {
//       setState(() {
//         loading = true;
//       });

//       final response = await http.get(
//         Uri.parse(
//           "https://nominatim.openstreetmap.org/search?q=${searchController.text}&format=json&limit=1",
//         ),
//         headers: {
//           "User-Agent": "TruckLinkAI",
//         },
//       );

//       final data = jsonDecode(response.body);

//       if (data.isNotEmpty) {
//         double lat =
//             double.parse(data[0]["lat"]);

//         double lon =
//             double.parse(data[0]["lon"]);

//         LatLng point = LatLng(lat, lon);

//         setState(() {
//           selectedLocation = point;
//         });

//         mapController.move(point, 16);

//         await reverseGeocode(point);
//       }
//     } catch (e) {
//       debugPrint(e.toString());
//     }

//     setState(() {
//       loading = false;
//     });
//   }

//   Future<void> confirmLocation() async {
//     List<Placemark> placemarks =
//         await placemarkFromCoordinates(
//       selectedLocation.latitude,
//       selectedLocation.longitude,
//     );

//     Placemark place = placemarks.first;

//     Navigator.pop(
//       context,
//       LocationModel(
//         city:
//             "${place.locality}, ${place.administrativeArea}",
//         address: address,
//         latitude: selectedLocation.latitude,
//         longitude: selectedLocation.longitude,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Select Location"),
//       ),

//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: mapController,

//             options: MapOptions(
//               initialCenter: selectedLocation,
//               initialZoom: 15,

//               onTap: (tapPosition, point) async {
//                 setState(() {
//                   selectedLocation = point;
//                 });

//                 await reverseGeocode(point);
//               },
//             ),

//             children: [
//               TileLayer(
//                 urlTemplate:
//                      'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',

//                 userAgentPackageName:
//                     "com.trucklinkai.app",

//                 maxZoom: 19,
//               ),

//               MarkerLayer(
//                 markers: [
//                   Marker(
//                     point: selectedLocation,
//                     width: 50,
//                     height: 50,
//                     child: const Icon(
//                       Icons.location_pin,
//                       size: 50,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           Positioned(
//             top: 10,
//             left: 10,
//             right: 10,
//             child: Card(
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(
//                   horizontal: 10,
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller:
//                             searchController,
//                         decoration:
//                             const InputDecoration(
//                           hintText:
//                               "Search location...",
//                           border:
//                               InputBorder.none,
//                         ),
//                       ),
//                     ),

//                     IconButton(
//                       onPressed: searchLocation,
//                       icon: loading
//                           ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child:
//                                   CircularProgressIndicator(
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : const Icon(
//                               Icons.search,
//                             ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           Positioned(
//             right: 15,
//             bottom: 180,
//             child: FloatingActionButton(
//               onPressed: getCurrentLocation,
//               child:
//                   const Icon(Icons.my_location),
//             ),
//           ),

//           Positioned(
//             bottom: 20,
//             left: 15,
//             right: 15,
//             child: Card(
//               elevation: 5,
//               child: Padding(
//                 padding:
//                     const EdgeInsets.all(15),
//                 child: Column(
//                   mainAxisSize:
//                       MainAxisSize.min,
//                   children: [
//                     Text(
//                       address,
//                       textAlign:
//                           TextAlign.center,
//                     ),

//                     const SizedBox(
//                       height: 15,
//                     ),

//                     ContinueButton(text: "Conferm Location", clr: Appcolors.primaryBlue, onTap:confirmLocation)
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/locationModel.dart';

// NOTE: 'package:geocoding/geocoding.dart' has been removed — it does not
// support Flutter Web. All reverse-geocoding now goes through Nominatim HTTP
// API, which works on every platform (mobile, web, desktop).

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController mapController = MapController();

  final TextEditingController searchController = TextEditingController();

  LatLng selectedLocation = const LatLng(34.1688, 73.2215);

  String address = "Tap on map";

  bool loading = false;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  // ---------------------------------------------------------------------------
  // Core helper: reverse-geocode via Nominatim (works on web + mobile)
  // Returns a structured map with keys: display_name, city, state, street
  // Returns null on any error.
  // ---------------------------------------------------------------------------
  Future<Map<String, String>?> _reverseGeocodeNominatim(LatLng point) async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://nominatim.openstreetmap.org/reverse"
          "?lat=${point.latitude}&lon=${point.longitude}&format=json",
        ),
        headers: {"User-Agent": "TruckLinkAI"},
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final addr = (data["address"] as Map<String, dynamic>?) ?? {};

      final street = (addr["road"] as String?) ?? "";
      final city = (addr["city"] as String?) ??
          (addr["town"] as String?) ??
          (addr["village"] as String?) ??
          "";
      final state = (addr["state"] as String?) ?? "";
      final displayName = (data["display_name"] as String?) ?? "";

      return {
        "display_name": displayName,
        "city": city,
        "state": state,
        "street": street,
      };
    } catch (e) {
      debugPrint("Nominatim reverse geocode error: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Get the device's current GPS location and move the map to it
  // ---------------------------------------------------------------------------
 Future<void> getCurrentLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();

    if (!mounted) return; // <-- guard before setState

    final current = LatLng(position.latitude, position.longitude);

    setState(() {
      selectedLocation = current;
    });

    mapController.move(current, 16);

    await reverseGeocode(current);
  } catch (e) {
    debugPrint("getCurrentLocation error: $e");
  }
}

Future<void> reverseGeocode(LatLng point) async {
  final result = await _reverseGeocodeNominatim(point);

  if (!mounted) return; // <-- guard before setState
  if (result == null) return;

  final street = result["street"] ?? "";
  final city = result["city"] ?? "";
  final state = result["state"] ?? "";

  final parts = [street, city, state].where((s) => s.isNotEmpty).toList();

  setState(() {
    address = parts.isNotEmpty ? parts.join(", ") : result["display_name"] ?? "Unknown";
  });
}

Future<void> searchLocation() async {
  if (searchController.text.trim().isEmpty) return;

  try {
    if (!mounted) return;
    setState(() {
      loading = true;
    });

    final response = await http.get(
      Uri.parse(
        "https://nominatim.openstreetmap.org/search"
        "?q=${Uri.encodeComponent(searchController.text)}&format=json&limit=1",
      ),
      headers: {"User-Agent": "TruckLinkAI"},
    );

    if (!mounted) return; // <-- guard before parsing/setState

    final data = jsonDecode(response.body) as List<dynamic>;

    if (data.isNotEmpty) {
      final double lat = double.parse(data[0]["lat"] as String);
      final double lon = double.parse(data[0]["lon"] as String);

      final point = LatLng(lat, lon);

      setState(() {
        selectedLocation = point;
      });

      mapController.move(point, 16);

      await reverseGeocode(point);
    }
  } catch (e) {
    debugPrint("searchLocation error: $e");
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}

  // ---------------------------------------------------------------------------
  // Confirm the selected location and pop back with a LocationModel
  // ---------------------------------------------------------------------------
  Future<void> confirmLocation() async {
    final result = await _reverseGeocodeNominatim(selectedLocation);

    final city = result != null
        ? "${result['city']}, ${result['state']}"
        : "Unknown";

    Navigator.pop(
      context,
      LocationModel(
        city: city,
        address: address,
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
      ),

      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: mapController,

            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 15,

              onTap: (tapPosition, point) async {
                setState(() {
                  selectedLocation = point;
                });
                await reverseGeocode(point);
              },
            ),

            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: "com.trucklinkai.app",
                maxZoom: 19,
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Search bar ─────────────────────────────────────────────────────
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: "Search location...",
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => searchLocation(),
                      ),
                    ),

                    IconButton(
                      onPressed: searchLocation,
                      icon: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── My-location FAB ────────────────────────────────────────────────
          Positioned(
            right: 15,
            bottom: 180,
            child: FloatingActionButton(
              onPressed: getCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // ── Address card + confirm button ──────────────────────────────────
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      address,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 15),

                    ContinueButton(
                      text: "Confirm Location",
                      clr: Appcolors.primaryBlue,
                      onTap: confirmLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}