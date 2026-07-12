import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

/// Simple model for a driver in the broker's network.
/// Swap this out for your real model / cubit state whenever you wire this
/// page up to actual data — the UI below only depends on these fields.
class NetworkDriver {
  final String name;
  final String vehicleType;
  final String vehicleNumber;
  final String phone;
  final double rating;
  final int completedTrips;
  final DriverAvailability availability;

  const NetworkDriver({
    required this.name,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.phone,
    required this.rating,
    required this.completedTrips,
    required this.availability,
  });
}

enum DriverAvailability { available, onTrip, offline }

class BrokerDriversNetworkPage extends StatefulWidget {
  const BrokerDriversNetworkPage({super.key});

  @override
  State<BrokerDriversNetworkPage> createState() =>
      _BrokerDriversNetworkPageState();
}

class _BrokerDriversNetworkPageState extends State<BrokerDriversNetworkPage> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedFilter = 0; // 0=All, 1=Available, 2=On Trip, 3=Offline

  // -------- Mock data for now — replace with real data source --------
  final List<NetworkDriver> _drivers = const [
    NetworkDriver(
      name: "Ali Raza",
      vehicleType: "Container Truck",
      vehicleNumber: "LEA-2214",
      phone: "0301-2345678",
      rating: 4.8,
      completedTrips: 132,
      availability: DriverAvailability.available,
    ),
    NetworkDriver(
      name: "Hamza Sheikh",
      vehicleType: "Flatbed Trailer",
      vehicleNumber: "LES-9081",
      phone: "0322-1122334",
      rating: 4.6,
      completedTrips: 87,
      availability: DriverAvailability.onTrip,
    ),
    NetworkDriver(
      name: "Waqas Ahmed",
      vehicleType: "Mazda Shehzore",
      vehicleNumber: "KHI-4471",
      phone: "0345-6677889",
      rating: 4.9,
      completedTrips: 204,
      availability: DriverAvailability.available,
    ),
    NetworkDriver(
      name: "Imran Baig",
      vehicleType: "Container Truck",
      vehicleNumber: "ISB-3320",
      phone: "0333-9988776",
      rating: 4.3,
      completedTrips: 54,
      availability: DriverAvailability.offline,
    ),
    NetworkDriver(
      name: "Bilal Yousaf",
      vehicleType: "Refrigerated Truck",
      vehicleNumber: "FSD-6120",
      phone: "0312-4455667",
      rating: 4.7,
      completedTrips: 98,
      availability: DriverAvailability.available,
    ),
  ];

  List<NetworkDriver> get _filteredDrivers {
    final query = _searchController.text.trim().toLowerCase();

    return _drivers.where((d) {
      final matchesQuery =
          query.isEmpty ||
          d.name.toLowerCase().contains(query) ||
          d.vehicleNumber.toLowerCase().contains(query);

      final matchesFilter = switch (_selectedFilter) {
        1 => d.availability == DriverAvailability.available,
        2 => d.availability == DriverAvailability.onTrip,
        3 => d.availability == DriverAvailability.offline,
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddDriverSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddDriverSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final double horizontalPadding = isMobile ? 22 : width * 0.12;

            return Column(
              children: [
                // -------- Header --------
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    15,
                    horizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          
                          
                          const Expanded(
                            child: Text(
                              "My Drivers",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _openAddDriverSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Appcolors.secondaryPurple,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Add",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_drivers.length} drivers in your network",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // -------- Search --------
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                const SizedBox(height: 14),

                // -------- Filter chips --------
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    children: [
                      _FilterChip(
                        label: "All",
                        selected: _selectedFilter == 0,
                        color: Appcolors.secondaryPurple,
                        onTap: () => setState(() => _selectedFilter = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: "Available",
                        selected: _selectedFilter == 1,
                        color: Appcolors.tertiaryGreen,
                        onTap: () => setState(() => _selectedFilter = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: "On Trip",
                        selected: _selectedFilter == 2,
                        color: Colors.orange,
                        onTap: () => setState(() => _selectedFilter = 2),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: "Offline",
                        selected: _selectedFilter == 3,
                        color: Colors.grey,
                        onTap: () => setState(() => _selectedFilter = 3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // -------- Driver list --------
                Expanded(
                  child: _filteredDrivers.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            24,
                          ),
                          itemCount: _filteredDrivers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _DriverCard(driver: _filteredDrivers[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}



class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        hintText: "Search by name or vehicle number",
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Appcolors.secondaryPurple, width: 1.6),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final NetworkDriver driver;
  const _DriverCard({required this.driver});

  _AvailabilityStyle get _availabilityStyle {
    switch (driver.availability) {
      case DriverAvailability.available:
        return _AvailabilityStyle("Available", Appcolors.tertiaryGreen);
      case DriverAvailability.onTrip:
        return _AvailabilityStyle("On Trip", Colors.orange);
      case DriverAvailability.offline:
        return _AvailabilityStyle("Offline", Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _availabilityStyle;
    final initials = driver.name
        .trim()
        .split(RegExp(r"\s+"))
        .map((e) => e.isNotEmpty ? e[0] : "")
        .take(2)
        .join()
        .toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- Avatar --------
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Appcolors.secondaryPurple.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: Appcolors.secondaryPurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // -------- Details --------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          driver.name,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: style.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: style.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              style.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: style.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${driver.vehicleType} • ${driver.vehicleNumber}",
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: Colors.amber[600]),
                      const SizedBox(width: 3),
                      Text(
                        driver.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 15,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "${driver.completedTrips} trips",
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Icon(Icons.call_outlined, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text(
                        driver.phone,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityStyle {
  final String label;
  final Color color;
  _AvailabilityStyle(this.label, this.color);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Appcolors.secondaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_2_outlined,
                size: 38,
                color: Appcolors.secondaryPurple,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No drivers found",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Try a different search or filter, or add a new driver to your network.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Add Driver bottom sheet — UI only. Wire the "Add Driver" button's
// onPressed to your real cubit/API call whenever this is connected.
// =====================================================================

class _AddDriverSheet extends StatefulWidget {
  const _AddDriverSheet();

  @override
  State<_AddDriverSheet> createState() => _AddDriverSheetState();
}

class _AddDriverSheetState extends State<_AddDriverSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController vehicleTypeController = TextEditingController();
  final TextEditingController vehicleNumberController =
      TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    vehicleTypeController.dispose();
    vehicleNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Add New Driver",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Add a driver to your network by their details",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 22),

              _FieldLabel("Driver Name"),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: nameController,
                hintText: "e.g. Ali Raza",
              ),
              const SizedBox(height: 16),

              _FieldLabel("Phone Number"),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: phoneController,
                hintText: "03XXXXXXXXX",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _FieldLabel("Vehicle Type"),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: vehicleTypeController,
                hintText: "e.g. Container Truck",
              ),
              const SizedBox(height: 16),

              _FieldLabel("Vehicle Number"),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: vehicleNumberController,
                hintText: "e.g. LEA-2214",
              ),

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolors.secondaryPurple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    // Hook up to your AddDriver cubit / API call here.
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Add Driver",
                    style: TextStyle(
                      fontSize: 16,
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  const _SheetTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Appcolors.secondaryPurple, width: 1.6),
        ),
      ),
    );
  }
}