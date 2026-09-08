import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/locationModel.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialTitle;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
    this.initialTitle,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  // Safe zoom limits: Country/regional view as minimum zoom (4.5), building level as maximum (18.0)
  static const double kMinSafeZoom = 4.5;
  static const double kMaxSafeZoom = 18.0;

  // Authoritative coordinate double
  late LatLng selectedLocation;
  String addressTitle = "Tap on map or move pin";
  String addressSubtitle = "Locating...";
  LocationModel? currentLocationData;

  bool loadingSearch = false;
  bool isReverseGeocoding = false;
  List<_NominatimSearchResult> searchResults = [];
  bool showSearchResults = false;
  Timer? _debounceTimer;
  Timer? _cameraIdleTimer;
  int _geocodeRequestId = 0;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation ?? const LatLng(34.1688, 73.2215);
    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      addressTitle = widget.initialTitle!;
    }
    
    // If no initial location passed, try fetching current GPS position
    if (widget.initialLocation == null) {
      getCurrentLocation();
    } else {
      reverseGeocode(selectedLocation);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cameraIdleTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Parse Nominatim Address details into specific title & descriptive subtitle
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> _parseNominatimAddress(Map<String, dynamic> data) {
    final addr = (data['address'] as Map<String, dynamic>?) ?? {};

    final String displayName = (data['display_name'] as String?) ?? '';
    final String amenity = (addr['amenity'] as String?) ?? '';
    final String building = (addr['building'] as String?) ?? '';
    final String shop = (addr['shop'] as String?) ?? '';
    final String office = (addr['office'] as String?) ?? '';
    final String tourism = (addr['tourism'] as String?) ?? '';
    final String road = (addr['road'] as String?) ?? (addr['street'] as String?) ?? '';
    final String neighbourhood = (addr['neighbourhood'] as String?) ?? (addr['suburb'] as String?) ?? '';
    final String city = (addr['city'] as String?) ??
        (addr['town'] as String?) ??
        (addr['village'] as String?) ??
        (addr['municipality'] as String?) ??
        '';
    final String district = (addr['district'] as String?) ?? (addr['county'] as String?) ?? '';
    final String state = (addr['state'] as String?) ?? (addr['province'] as String?) ?? '';
    final String postcode = (addr['postcode'] as String?) ?? '';
    final String country = (addr['country'] as String?) ?? '';
    final String type = (data['type'] as String?) ?? (data['class'] as String?) ?? '';

    // Determine the most specific place name
    String title = '';
    if (data['name'] != null && (data['name'] as String).isNotEmpty) {
      title = data['name'];
    } else if (amenity.isNotEmpty) {
      title = amenity;
    } else if (building.isNotEmpty) {
      title = building;
    } else if (shop.isNotEmpty) {
      title = shop;
    } else if (office.isNotEmpty) {
      title = office;
    } else if (tourism.isNotEmpty) {
      title = tourism;
    } else if (road.isNotEmpty) {
      title = road;
    } else if (neighbourhood.isNotEmpty) {
      title = neighbourhood;
    } else if (city.isNotEmpty) {
      title = city;
    } else if (district.isNotEmpty) {
      title = district;
    } else {
      title = displayName.split(',').first.trim();
    }

    // Build subtitle from supporting locality components
    final List<String> subtitleParts = [];
    if (road.isNotEmpty && title != road) subtitleParts.add(road);
    if (neighbourhood.isNotEmpty && title != neighbourhood) subtitleParts.add(neighbourhood);
    if (city.isNotEmpty && title != city) subtitleParts.add(city);
    if (district.isNotEmpty && title != district && city != district) subtitleParts.add(district);
    if (state.isNotEmpty && title != state) subtitleParts.add(state);

    String subtitle = subtitleParts.join(', ');
    if (subtitle.isEmpty) {
      subtitle = displayName;
    }

    return {
      'title': title,
      'subtitle': subtitle,
      'display_name': displayName,
      'road': road,
      'neighbourhood': neighbourhood,
      'city': city.isNotEmpty ? city : (district.isNotEmpty ? district : state),
      'district': district,
      'state': state,
      'postcode': postcode,
      'country': country,
      'place_type': type,
      'building': building,
      'amenity': amenity,
    };
  }

  // ---------------------------------------------------------------------------
  // Reverse Geocoding with stale-response protection & full precision preservation
  // ---------------------------------------------------------------------------
  Future<void> reverseGeocode(LatLng point) async {
    final int currentRequestId = ++_geocodeRequestId;
    if (!mounted) return;
    setState(() {
      isReverseGeocoding = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "https://nominatim.openstreetmap.org/reverse"
          "?lat=${point.latitude}&lon=${point.longitude}&format=jsonv2&addressdetails=1",
        ),
        headers: {
          "User-Agent": "TruckLinkAI-LocationPicker/1.0",
          "Accept-Language": "en",
        },
      ).timeout(const Duration(seconds: 8));

      // Discard stale response if user tapped again while this request was flying
      if (currentRequestId != _geocodeRequestId) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = _parseNominatimAddress(data);

        final String finalTitle = parsed['title'] ?? 'Selected Point';
        final String finalSubtitle = parsed['subtitle'] ?? '';
        final String finalCity = parsed['city'] ?? '';
        final String combinedAddress = finalSubtitle.isNotEmpty
            ? "$finalTitle, $finalSubtitle"
            : (parsed['display_name'] ?? finalTitle);

        currentLocationData = LocationModel(
          city: finalCity.isNotEmpty ? finalCity : "Unknown",
          address: combinedAddress,
          latitude: point.latitude,
          longitude: point.longitude,
          displayName: parsed['display_name'] ?? combinedAddress,
          road: parsed['road'],
          neighbourhood: parsed['neighbourhood'],
          district: parsed['district'],
          state: parsed['state'],
          postcode: parsed['postcode'],
          country: parsed['country'],
          placeType: parsed['place_type'],
          building: parsed['building'],
          amenity: parsed['amenity'],
        );

        if (mounted && currentRequestId == _geocodeRequestId) {
          setState(() {
            addressTitle = finalTitle;
            addressSubtitle = finalSubtitle.isNotEmpty ? finalSubtitle : combinedAddress;
          });
        }
      } else {
        if (currentRequestId == _geocodeRequestId) {
          _setFallbackLocation(point);
        }
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
      if (currentRequestId == _geocodeRequestId) {
        _setFallbackLocation(point);
      }
    } finally {
      if (mounted && currentRequestId == _geocodeRequestId) {
        setState(() {
          isReverseGeocoding = false;
        });
      }
    }
  }

  void _setFallbackLocation(LatLng point) {
    final String fallbackAddress = "Lat: ${point.latitude.toStringAsFixed(6)}, Lng: ${point.longitude.toStringAsFixed(6)}";
    currentLocationData = LocationModel(
      city: "Selected Location",
      address: fallbackAddress,
      latitude: point.latitude,
      longitude: point.longitude,
      displayName: fallbackAddress,
    );
    if (mounted) {
      setState(() {
        addressTitle = "Custom Map Location";
        addressSubtitle = fallbackAddress;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Device GPS Location
  // ---------------------------------------------------------------------------
  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location services are disabled on your device.")),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are permanently denied.")),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      final current = LatLng(position.latitude, position.longitude);

      setState(() {
        selectedLocation = current;
      });

      mapController.move(current, 16.0);
      await reverseGeocode(current);
    } catch (e) {
      debugPrint("getCurrentLocation error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Multi-Result OpenStreetMap / Nominatim Search
  // ---------------------------------------------------------------------------
  void onSearchTextChanged(String text) {
    _debounceTimer?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        searchResults = [];
        showSearchResults = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      executeSearch(text.trim());
    });
  }

  Future<void> executeSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      loadingSearch = true;
      showSearchResults = true;
    });

    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search"
        "?q=${Uri.encodeComponent(query)}"
        "&format=jsonv2"
        "&addressdetails=1"
        "&countrycodes=pk"
        "&limit=10",
      );

      final response = await http.get(
        url,
        headers: {
          "User-Agent": "TruckLinkAI-LocationPicker/1.0",
          "Accept-Language": "en",
        },
      ).timeout(const Duration(seconds: 9));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<_NominatimSearchResult> results = [];

        for (var item in data) {
          final double? lat = double.tryParse(item['lat'].toString());
          final double? lon = double.tryParse(item['lon'].toString());
          if (lat == null || lon == null) continue;

          final parsed = _parseNominatimAddress(item as Map<String, dynamic>);
          final String type = (item['type'] ?? item['class'] ?? 'place').toString();

          results.add(_NominatimSearchResult(
            title: parsed['title'],
            subtitle: parsed['subtitle'],
            displayName: parsed['display_name'],
            latLng: LatLng(lat, lon),
            placeType: type,
            parsedData: parsed,
          ));
        }

        // Rank results: specific POIs/roads/neighbourhoods first, administrative boundaries last
        results.sort((a, b) {
          int scoreA = _getTypePriority(a.placeType);
          int scoreB = _getTypePriority(b.placeType);
          return scoreA.compareTo(scoreB);
        });

        setState(() {
          searchResults = results;
        });
      } else {
        setState(() {
          searchResults = [];
        });
      }
    } catch (e) {
      debugPrint("Search location error: $e");
      if (mounted) {
        setState(() {
          searchResults = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loadingSearch = false;
        });
      }
    }
  }

  int _getTypePriority(String type) {
    final t = type.toLowerCase();
    if (t.contains('university') || t.contains('college') || t.contains('school') || t.contains('hospital')) return 1;
    if (t.contains('building') || t.contains('shop') || t.contains('amenity') || t.contains('commercial')) return 2;
    if (t.contains('road') || t.contains('street') || t.contains('highway') || t.contains('chowk')) return 3;
    if (t.contains('neighbourhood') || t.contains('suburb') || t.contains('village') || t.contains('town')) return 4;
    if (t.contains('city') || t.contains('district')) return 5;
    if (t.contains('state') || t.contains('province') || t.contains('country')) return 6;
    return 7;
  }

  // ---------------------------------------------------------------------------
  // Select a search result
  // ---------------------------------------------------------------------------
  void selectSearchResult(_NominatimSearchResult result) {
    FocusScope.of(context).unfocus();
    searchController.text = result.title;

    final LatLng point = result.latLng;
    setState(() {
      selectedLocation = point;
      addressTitle = result.title;
      addressSubtitle = result.subtitle;
      showSearchResults = false;
    });

    mapController.move(point, 16.0);
    reverseGeocode(point);
  }

  // ---------------------------------------------------------------------------
  // Confirm Location and Return LocationModel
  // ---------------------------------------------------------------------------
  void confirmLocation() {
    final String city = currentLocationData?.city ?? "Selected Location";
    final String finalAddress = addressSubtitle.isNotEmpty
        ? "$addressTitle, $addressSubtitle"
        : addressTitle;

    final LocationModel resultModel = LocationModel(
      city: city,
      address: finalAddress,
      latitude: selectedLocation.latitude,
      longitude: selectedLocation.longitude,
      displayName: currentLocationData?.displayName ?? finalAddress,
      road: currentLocationData?.road,
      neighbourhood: currentLocationData?.neighbourhood,
      district: currentLocationData?.district,
      state: currentLocationData?.state,
      postcode: currentLocationData?.postcode,
      country: currentLocationData?.country,
      placeType: currentLocationData?.placeType,
      building: currentLocationData?.building,
      amenity: currentLocationData?.amenity,
    );

    Navigator.pop(context, resultModel);
  }

  // ---------------------------------------------------------------------------
  // UI Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Interactive Flutter Map with Safe Zoom Limits & Optimized Tile Layer ──────────
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: selectedLocation,
                initialZoom: 15.0,
                minZoom: kMinSafeZoom,
                maxZoom: kMaxSafeZoom,
                cameraConstraint: const CameraConstraint.unconstrained(),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (tapPosition, point) {
                  // Marker placement on explicit user tap with reverse geocoding
                  setState(() {
                    selectedLocation = point;
                    showSearchResults = false;
                  });
                  final double safeCurrentZoom = mapController.camera.zoom.clamp(kMinSafeZoom, kMaxSafeZoom);
                  mapController.move(point, safeCurrentZoom);
                  reverseGeocode(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: "com.trucklinkai.app",
                  maxZoom: 19,
                  minZoom: 4,
                  keepBuffer: 1,
                  panBuffer: 0,
                  errorTileCallback: (tile, error, stackTrace) {
                    debugPrint("Tile loading issue at ${tile.coordinates}: $error");
                  },
                ),
                const SimpleAttributionWidget(
                  source: Text('© OpenStreetMap contributors'),
                ),
                // ── Interactive Place Marker Layer ────────────────────────
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation,
                      width: 50,
                      height: 50,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        size: 50,
                        color: Appcolors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Search Bar & Back Navigation ───────────────────────────────
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              Icon(
                                Icons.search_rounded,
                                size: 21,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Search college, hospital, road, POI...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                  onChanged: onSearchTextChanged,
                                  onSubmitted: (val) => executeSearch(val.trim()),
                                ),
                              ),
                              if (searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchResults = [];
                                      showSearchResults = false;
                                    });
                                  },
                                ),
                              if (loadingSearch)
                                const Padding(
                                  padding: EdgeInsets.only(right: 14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Appcolors.primaryBlue),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Search Suggestions List Card ───────────────────────────
                  if (showSearchResults && searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          separatorBuilder: (ctx, i) => Divider(
                            height: 1,
                            thickness: 0.8,
                            color: Colors.grey[200],
                          ),
                          itemBuilder: (context, index) {
                            final item = searchResults[index];
                            return ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Appcolors.primaryBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconForType(item.placeType),
                                  size: 18,
                                  color: Appcolors.primaryBlue,
                                ),
                              ),
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_outward_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onTap: () => selectSearchResult(item),
                            );
                          },
                        ),
                      ),
                    ),

                  if (showSearchResults && !loadingSearch && searchResults.isEmpty && searchController.text.trim().length >= 2)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber[800], size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "No exact match in OSM. You can move the pin on the map manually to pick your exact spot.",
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Map Floating Action Controls (Zoom & My Location) ──────────
            Positioned(
              right: 16,
              bottom: 230,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: "map_zoom_in_fab",
                    backgroundColor: Colors.white,
                    foregroundColor: Appcolors.primaryBlue,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () {
                      final currentZoom = mapController.camera.zoom;
                      if (currentZoom < kMaxSafeZoom) {
                        mapController.move(mapController.camera.center, (currentZoom + 1.0).clamp(kMinSafeZoom, kMaxSafeZoom));
                      }
                    },
                    child: const Icon(Icons.add, size: 20),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: "map_zoom_out_fab",
                    backgroundColor: Colors.white,
                    foregroundColor: Appcolors.primaryBlue,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () {
                      final currentZoom = mapController.camera.zoom;
                      if (currentZoom > kMinSafeZoom) {
                        mapController.move(mapController.camera.center, (currentZoom - 1.0).clamp(kMinSafeZoom, kMaxSafeZoom));
                      }
                    },
                    child: const Icon(Icons.remove, size: 20),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: "map_my_location_fab",
                    backgroundColor: Colors.white,
                    foregroundColor: Appcolors.primaryBlue,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: getCurrentLocation,
                    child: const Icon(Icons.my_location_rounded, size: 24),
                  ),
                ],
              ),
            ),

            // ── Confirmation & High Precision Location Card ────────────────
            Positioned(
              bottom: 18,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location title and icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Appcolors.primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Appcolors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                addressTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                addressSubtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Exact 6-decimal coordinates preview badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed, size: 14, color: Appcolors.secondaryPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Lat: ${selectedLocation.latitude.toStringAsFixed(6)}   •   Lng: ${selectedLocation.longitude.toStringAsFixed(6)}",
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Appcolors.secondaryPurple,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolors.primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        onPressed: confirmLocation,
                        child: const Text(
                          "Confirm Location",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('university') || t.contains('college') || t.contains('school')) {
      return Icons.school_rounded;
    }
    if (t.contains('hospital') || t.contains('clinic') || t.contains('pharmacy')) {
      return Icons.local_hospital_rounded;
    }
    if (t.contains('road') || t.contains('street') || t.contains('highway')) {
      return Icons.alt_route_rounded;
    }
    if (t.contains('shop') || t.contains('market') || t.contains('mall')) {
      return Icons.storefront_rounded;
    }
    if (t.contains('building') || t.contains('office') || t.contains('commercial')) {
      return Icons.business_rounded;
    }
    return Icons.place_rounded;
  }
}

class _NominatimSearchResult {
  final String title;
  final String subtitle;
  final String displayName;
  final LatLng latLng;
  final String placeType;
  final Map<String, dynamic> parsedData;

  _NominatimSearchResult({
    required this.title,
    required this.subtitle,
    required this.displayName,
    required this.latLng,
    required this.placeType,
    required this.parsedData,
  });
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 21),
      ),
    );
  }
}