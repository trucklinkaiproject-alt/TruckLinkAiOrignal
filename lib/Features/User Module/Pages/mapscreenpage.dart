import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/locationModel.dart';


class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController mapController = MapController();

  final TextEditingController searchController =
      TextEditingController();

  LatLng selectedLocation =
      const LatLng(34.1688, 73.2215);

  String address = "Tap on map";

  bool loading = false;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) return;

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      Position position =
          await Geolocator.getCurrentPosition();

      LatLng current = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        selectedLocation = current;
      });

      mapController.move(current, 16);

      await reverseGeocode(current);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> reverseGeocode(
    LatLng point,
  ) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      Placemark place = placemarks.first;

      setState(() {
        address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}";
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> searchLocation() async {
    if (searchController.text.trim().isEmpty) {
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final response = await http.get(
        Uri.parse(
          "https://nominatim.openstreetmap.org/search?q=${searchController.text}&format=json&limit=1",
        ),
        headers: {
          "User-Agent": "TruckLinkAI",
        },
      );

      final data = jsonDecode(response.body);

      if (data.isNotEmpty) {
        double lat =
            double.parse(data[0]["lat"]);

        double lon =
            double.parse(data[0]["lon"]);

        LatLng point = LatLng(lat, lon);

        setState(() {
          selectedLocation = point;
        });

        mapController.move(point, 16);

        await reverseGeocode(point);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> confirmLocation() async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(
      selectedLocation.latitude,
      selectedLocation.longitude,
    );

    Placemark place = placemarks.first;

    Navigator.pop(
      context,
      LocationModel(
        city:
            "${place.locality}, ${place.administrativeArea}",
        address: address,
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
      ),

      body: Stack(
        children: [
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

                userAgentPackageName:
                    "com.trucklinkai.app",

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

          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                            searchController,
                        decoration:
                            const InputDecoration(
                          hintText:
                              "Search location...",
                          border:
                              InputBorder.none,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: searchLocation,
                      icon: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.search,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: 15,
            bottom: 180,
            child: FloatingActionButton(
              onPressed: getCurrentLocation,
              child:
                  const Icon(Icons.my_location),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Card(
              elevation: 5,
              child: Padding(
                padding:
                    const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Text(
                      address,
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    ContinueButton(text: "Conferm Location", clr: Appcolors.primaryBlue, onTap:confirmLocation)
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