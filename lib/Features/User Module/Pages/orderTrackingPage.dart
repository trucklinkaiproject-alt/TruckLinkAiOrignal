import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';

class OrderTrackingPage extends StatefulWidget {
  final Map<String, dynamic> orderStatusDetail;
  const OrderTrackingPage({super.key, required this.orderStatusDetail});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final MapController _mapController = MapController();
  bool _showMap = true;

  @override
  Widget build(BuildContext context) {
    final initialData = widget.orderStatusDetail;
    final String orderId = (initialData["orderId"] ?? initialData["id"] ?? initialData["orderNo"] ?? "").toString();
    final String orderNo = (initialData["orderNo"] ?? orderId).toString();
    final String userUid = (initialData["userUid"] ?? initialData["user_uid"] ?? "").toString();
    final String brokerId = (initialData["brokerId"] ?? initialData["broker_id"] ?? "").toString();
    final String assignedDriverId = (initialData["assigned_driver_id"] ?? initialData["driver_id"] ?? "").toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          // Listen in real-time to Order updates
          stream: orderId.isNotEmpty
              ? FirebaseFirestore.instance.collection("Orders").doc(orderId).snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            Map<String, dynamic> order = Map.from(initialData);
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists && snapshot.data!.data() != null) {
              order.addAll(snapshot.data!.data() as Map<String, dynamic>);
            }

            final String rawStatus = (order["status"] ?? "pending").toString().toLowerCase();
            final String pickupCity = (order["pickupCity"] ?? order["pickup_city"] ?? "Pickup").toString();
            final String dropCity = (order["dropCity"] ?? order["drop_city"] ?? "Drop").toString();
            final String pickupComp = (order["pickupComp"] ?? order["pickup_comp"] ?? "").toString();
            final String dropComp = (order["dropComp"] ?? order["drop_comp"] ?? "").toString();
            final String itemType = (order["itemType"] ?? order["item_type"] ?? "Cargo").toString();
            final String driverName = (order["assigned_driver_name"] ?? order["driver_name"] ?? "Assigned Driver").toString();
            final String driverPhone = (order["assigned_driver_phone"] ?? order["driver_phone"] ?? "N/A").toString();

            final num? rawLat = order["driver_latitude"] ?? order["latitude"];
            final num? rawLng = order["driver_longitude"] ?? order["longitude"];
            final double? driverLat = rawLat?.toDouble();
            final double? driverLng = rawLng?.toDouble();
            final bool hasDriverGps = driverLat != null && driverLng != null && (driverLat != 0.0 || driverLng != 0.0);

            // Pickup & Drop coordinates if available, otherwise fallback to reasonable regional defaults
            final double pLat = (order["pickup_lat"] ?? order["pickupLatitude"] as num?)?.toDouble() ?? 33.6844;
            final double pLng = (order["pickup_lng"] ?? order["pickupLongitude"] as num?)?.toDouble() ?? 73.0479;
            final double dLat = (order["drop_lat"] ?? order["dropLatitude"] as num?)?.toDouble() ?? 31.5204;
            final double dLng = (order["drop_lng"] ?? order["dropLongitude"] as num?)?.toDouble() ?? 74.3587;

            final LatLng driverLocation = hasDriverGps ? LatLng(driverLat, driverLng) : LatLng(pLat, pLng);
            final LatLng pickupLocation = LatLng(pLat, pLng);
            final LatLng dropLocation = LatLng(dLat, dLng);

            // Status stage checks
            final bool isPending = rawStatus == 'pending' || rawStatus == 'driver_offer_sent';
            final bool isAccepted = rawStatus == 'accepted_by_driver' || rawStatus == 'accepted';
            final bool isInTransit = rawStatus == 'in_transit' || rawStatus == 'in_progress' || rawStatus == 'arrived_at_pickup' || rawStatus == 'heading_to_drop';
            final bool isCompleted = rawStatus == 'completed' || rawStatus == 'delivered';

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isMobile = width < 600;
                final double horizontalPadding = isMobile ? 18 : width * 0.12;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- Header --------
                      Row(
                        children: [
                          BackArrowButton(onTap: () => Navigator.pop(context)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Live Order Tracking",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Order #$orderNo",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Appcolors.tertiaryGreen.withOpacity(0.12)
                                  : isInTransit
                                      ? Appcolors.primaryBlue.withOpacity(0.12)
                                      : Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rawStatus.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isCompleted
                                    ? Appcolors.tertiaryGreen
                                    : isInTransit
                                        ? Appcolors.primaryBlue
                                        : Colors.amber[800],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // -------- Real-Time Interactive Map View --------
                      Container(
                        height: isMobile ? 260 : 320,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: driverLocation,
                                initialZoom: 13,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: "com.trucklinkai.app",
                                  maxZoom: 19,
                                ),
                                const SimpleAttributionWidget(
                                  source: Text('© OpenStreetMap contributors'),
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: hasDriverGps
                                          ? [pickupLocation, driverLocation, dropLocation]
                                          : [pickupLocation, dropLocation],
                                      strokeWidth: 3.0,
                                      color: Appcolors.primaryBlue.withOpacity(0.65),
                                      pattern: const StrokePattern.dotted(),
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    // Pickup Marker
                                    Marker(
                                      point: pickupLocation,
                                      width: 44,
                                      height: 44,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Appcolors.tertiaryGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.store_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    // Drop Marker
                                    Marker(
                                      point: dropLocation,
                                      width: 44,
                                      height: 44,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    // Driver Live GPS Marker
                                    if (hasDriverGps && !isCompleted)
                                      Marker(
                                        point: driverLocation,
                                        width: 50,
                                        height: 50,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Appcolors.primaryBlue,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Appcolors.primaryBlue.withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.local_shipping,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            // Map Control Floating Button
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: FloatingActionButton.small(
                                heroTag: "recenter_btn",
                                backgroundColor: Colors.white,
                                foregroundColor: Appcolors.primaryBlue,
                                elevation: 4,
                                onPressed: () {
                                  _mapController.move(hasDriverGps && !isCompleted ? driverLocation : pickupLocation, 14);
                                },
                                child: const Icon(Icons.my_location_rounded),
                              ),
                            ),
                            // Real-time GPS status tag (hidden once completed)
                            if (!isCompleted)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: hasDriverGps ? Appcolors.tertiaryGreen : Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        hasDriverGps ? "Live GPS Active" : "Waiting for Driver Signal",
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: hasDriverGps ? Colors.black87 : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Map Legend for Marker Clarity
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.94),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Appcolors.tertiaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "Pickup",
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "Drop-off",
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                    if (hasDriverGps && !isCompleted) ...[
                                      const SizedBox(width: 10),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: Appcolors.primaryBlue,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            "Driver",
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // -------- Driver Info Card --------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Appcolors.tertiaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.badge_outlined,
                                color: Appcolors.tertiaryGreen,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Phone: $driverPhone",
                                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                                  ),
                                  if (hasDriverGps) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "Coords: ${driverLat.toStringAsFixed(4)}°, ${driverLng.toStringAsFixed(4)}°",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // -------- Shipment Progress Timeline --------
                      const Text(
                        "Shipment Progress",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _TimelineTile(
                        title: "Request Created & Pending",
                        subtitle: "Broker and driver assignment initiated",
                        isCompleted: true,
                        isLast: false,
                      ),
                      _TimelineTile(
                        title: "Driver Assigned & Accepted",
                        subtitle: "$driverName confirmed shipment assignment",
                        isCompleted: isAccepted || isInTransit || isCompleted,
                        isLast: false,
                        highlight: isAccepted,
                      ),
                      _TimelineTile(
                        title: "In Transit to Pickup",
                        subtitle: "Driver started ride towards $pickupCity",
                        isCompleted: isInTransit || isCompleted,
                        isLast: false,
                        highlight: isInTransit && order['ride_phase'] != 'heading_to_drop',
                      ),
                      _TimelineTile(
                        title: "Cargo Picked Up & On Route",
                        subtitle: "Travelling to $dropCity",
                        isCompleted: order['ride_phase'] == 'heading_to_drop' || isCompleted,
                        isLast: false,
                        highlight: order['ride_phase'] == 'heading_to_drop' && !isCompleted,
                      ),
                      _TimelineTile(
                        title: "Delivered & Completed",
                        subtitle: isCompleted ? "Delivery successfully confirmed" : "Awaiting destination drop completion",
                        isCompleted: isCompleted,
                        isLast: true,
                        highlight: isCompleted,
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isLast;
  final bool highlight;

  const _TimelineTile({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isLast,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Appcolors.primaryBlue;
    final Color inactiveColor = Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCompleted ? activeColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? activeColor : inactiveColor,
                    width: 2,
                  ),
                  boxShadow: highlight
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isCompleted ? activeColor : inactiveColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                      color: highlight
                          ? activeColor
                          : isCompleted
                              ? Colors.black87
                              : Colors.grey[500],
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}