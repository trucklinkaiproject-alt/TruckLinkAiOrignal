import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Broker Module/Pages/brokerDriverDetailsPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverRequestsBloc/brokerDriverRequestsCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverNetworkBloc/brokerDriverNetworkCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverNetworkBloc/brokerDriverNetworkState.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/widgets/brokerDriverRequestsWidget.dart';

class BrokerDriversNetworkPage extends StatefulWidget {
  const BrokerDriversNetworkPage({super.key});

  @override
  State<BrokerDriversNetworkPage> createState() =>
      _BrokerDriversNetworkPageState();
}

class _BrokerDriversNetworkPageState extends State<BrokerDriversNetworkPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0; // 0=All, 1=Available, 2=On Trip, 3=Offline

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BrokerDriverRequestsCubit>().fetchPendingRequests();
        context.read<BrokerDriverNetworkCubit>().fetchNetworkDrivers();
      }
    });
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

            return BlocBuilder<BrokerDriverNetworkCubit, BrokerDriverNetworkState>(
              builder: (context, state) {
                List<Map<String, dynamic>> allDrivers = [];
                if (state is BrokerDriverNetworkLoadedState) {
                  allDrivers = state.drivers;
                }

                // Filter drivers by search query and availability filter
                final query = _searchController.text.trim().toLowerCase();
                final filteredDrivers = allDrivers.where((d) {
                  final name =
                      (d['driver_name'] ?? d['name'] ?? '').toString().toLowerCase();
                  final vehicleNum = (d['vehicle_number'] ??
                          d['vehicle_num'] ??
                          d['vehicle_type'] ??
                          '')
                      .toString()
                      .toLowerCase();
                  final matchesQuery = query.isEmpty ||
                      name.contains(query) ||
                      vehicleNum.contains(query);

                  final bool isAvailable = d['status'] == 'active' ||
                      d['vehicle_available'] == true ||
                      d['availability'] == 'available';

                  final matchesFilter = switch (_selectedFilter) {
                    1 => isAvailable,
                    2 => d['availability'] == 'onTrip',
                    3 => !isAvailable,
                    _ => true,
                  };

                  return matchesQuery && matchesFilter;
                }).toList();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              "${allDrivers.length} drivers in your network",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // -------- Pending Join Requests --------
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          16,
                        ),
                        child: const BrokerDriverRequestsWidget(),
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

                      const SizedBox(height: 14),

                      // -------- Driver Network List / Loading / Empty --------
                      if (state is BrokerDriverNetworkLoadingState) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Appcolors.secondaryPurple,
                            ),
                          ),
                        ),
                      ] else if (filteredDrivers.isEmpty) ...[
                        const _EmptyState(),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            24,
                          ),
                          itemCount: filteredDrivers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _NetworkDriverCard(
                              driver: filteredDrivers[index],
                            );
                          },
                        ),
                      ],
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
        hintText: "Search by name or vehicle type",
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
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Appcolors.secondaryPurple, width: 1.6),
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
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.withValues(alpha: 0.2),
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

class _NetworkDriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _NetworkDriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final String driverId = (driver['driver_id'] ?? driver['uid'] ?? driver['id'] ?? '').toString();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: driverId.isNotEmpty
          ? FirebaseFirestore.instance.collection("Driver").doc(driverId).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        Map<String, dynamic> combined = Map.from(driver);
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists && snapshot.data!.data() != null) {
          combined.addAll(snapshot.data!.data()!);
        }

        final String name = (combined['driver_name'] ?? combined['name'] ?? 'Driver').toString();

        final vehicleMap = (combined['vehicle'] is Map) ? combined['vehicle'] as Map : null;
        final truckMap = (combined['truckDetails'] is Map) ? combined['truckDetails'] as Map : null;

        final rawType = (combined['vehicle_type'] ??
                combined['vehicleType'] ??
                combined['truck_type'] ??
                combined['truckType'] ??
                combined['vehicle'] ??
                vehicleMap?['type'] ??
                vehicleMap?['vehicle_type'] ??
                truckMap?['vehicleType'] ??
                truckMap?['type'])
            ?.toString()
            .trim();

        final rawNumber = (combined['vehicle_number'] ??
                combined['vehicleNumber'] ??
                combined['truck_id'] ??
                combined['truckId'] ??
                combined['license_plate'] ??
                combined['licensePlate'] ??
                combined['plate_number'] ??
                combined['plateNumber'] ??
                vehicleMap?['number'] ??
                vehicleMap?['vehicle_number'] ??
                truckMap?['vehicleNumber'] ??
                truckMap?['number'])
            ?.toString()
            .trim();

        final String vehicleType = (rawType != null && rawType.isNotEmpty && rawType.toLowerCase() != 'null')
            ? rawType
            : 'Not specified';
        final String vehicleNumber = (rawNumber != null && rawNumber.isNotEmpty && rawNumber.toLowerCase() != 'null')
            ? rawNumber
            : 'Not specified';

        final String phone = (combined['phone'] ?? combined['driver_phone'] ?? 'N/A').toString();
        final double rating = (combined['driver_rating'] as num?)?.toDouble() ?? (combined['rating'] as num?)?.toDouble() ?? 0.0;
        final int totalTrips = (combined['total_trips'] as num?)?.toInt() ?? 0;
        final int completedTrips = (combined['completed_trips'] as num?)?.toInt() ?? 0;

        final bool isAvailable = combined['vehicle_available'] == true || combined['status'] == 'active' || combined['availability_status'] == 'online';
        final String statusLabel = isAvailable ? "Available" : "Offline";
        final Color statusColor = isAvailable ? Appcolors.tertiaryGreen : Colors.grey;

        final initials = name
            .trim()
            .split(RegExp(r"\s+"))
            .map((e) => e.isNotEmpty ? e[0] : "")
            .take(2)
            .join()
            .toUpperCase();

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BrokerDriverDetailsPage(driverData: combined),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                    color: Appcolors.secondaryPurple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.isNotEmpty ? initials : "D",
                    style: const TextStyle(
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
                              name,
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
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicleType,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Appcolors.secondaryPurple,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicleNumber,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: Colors.amber[600]),
                          const SizedBox(width: 3),
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : "No rating yet",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: rating > 0 ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.route_outlined,
                            size: 15,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "Trips: $totalTrips (Done: $completedTrips)",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          Icon(Icons.call_outlined, size: 15, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(
                            phone,
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
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Appcolors.secondaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_2_outlined,
                size: 38,
                color: Appcolors.secondaryPurple,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Drivers in Your Network",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Accepted drivers will appear here once you approve their join requests.",
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

class _AddDriverSheet extends StatefulWidget {
  const _AddDriverSheet();

  @override
  State<_AddDriverSheet> createState() => _AddDriverSheetState();
}

class _AddDriverSheetState extends State<_AddDriverSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController vehicleTypeController = TextEditingController(text: "Trailer");
  final TextEditingController vehicleNumberController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createDriver() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String phone = phoneController.text.trim();
    final String password = passwordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    // Validations
    if (name.isEmpty) {
      _showToast("Please enter driver name");
      return;
    }
    if (email.isEmpty || !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
      _showToast("Please enter a valid email address");
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      _showToast("Please enter a valid phone number");
      return;
    }
    if (password.length < 6) {
      _showToast("Password must be at least 6 characters long");
      return;
    }
    if (password != confirmPassword) {
      _showToast("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Driver Auth using a temporary secondary FirebaseApp instance
      // This guarantees the active Broker session is NOT logged out!
      final String tempAppName = 'DriverAuth_${DateTime.now().millisecondsSinceEpoch}';
      final tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email directly to Driver's email address
      await userCredential.user!.sendEmailVerification();

      final String newDriverUid = userCredential.user!.uid;

      final String brokerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final String brokerName = context.read<BrokerCubit>().userName.isNotEmpty
          ? context.read<BrokerCubit>().userName
          : 'Broker';

      final Map<String, dynamic> driverData = {
        'driver_id': newDriverUid,
        'uid': newDriverUid,
        'name': name,
        'email': email,
        'phone': phone,
        'vehicle_type': '',
        'vehicle_number': '',
        'truck_details_completed': false,
        'onboarding_completed': false,
        'broker_id': brokerId,
        'broker_name': brokerName,
        'availability_status': 'online',
        'vehicle_available': true,
        'status': 'active',
        'created_by_broker_id': brokerId,
        'completed_trips': 0,
        'total_trips': 0,
        'rating': 5.0,
        'total_reviews': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // 2. Write to main Driver collection
      await FirebaseFirestore.instance.collection("Driver").doc(newDriverUid).set(driverData);

      // 3. Write to Broker's DriverNetwork subcollection
      if (brokerId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("Broker")
            .doc(brokerId)
            .collection("DriverNetwork")
            .doc(newDriverUid)
            .set(driverData);
      }

      // 4. Clean up temporary FirebaseApp auth instance
      await tempAuth.signOut();
      await tempApp.delete();

      if (mounted) {
        Navigator.pop(context);
        context.read<BrokerDriverNetworkCubit>().fetchNetworkDrivers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Driver $name account created! A verification email has been sent to $email."),
            backgroundColor: Appcolors.tertiaryGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String err = e.message ?? "Authentication failed";
      if (e.code == 'email-already-in-use') {
        err = "An account with this email already exists.";
      } else if (e.code == 'weak-password') {
        err = "Password is too weak. Must be at least 6 characters.";
      }
      _showToast(err);
    } catch (e) {
      _showToast("Failed to create driver: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
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
                "Create a real Driver account directly in your network. The driver will configure their truck details upon first login.",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              const _FieldLabel("Driver Full Name"),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: nameController,
                hintText: "e.g. Ali Raza",
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 14),

              const _FieldLabel("Driver Email Address"),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: emailController,
                hintText: "driver@example.com",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              const _FieldLabel("Phone Number"),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: phoneController,
                hintText: "03001234567",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              const _FieldLabel("Password"),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: passwordController,
                hintText: "Min 6 characters",
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 14),

              const _FieldLabel("Confirm Password"),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: confirmPasswordController,
                hintText: "Re-enter password",
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolors.secondaryPurple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _isLoading ? null : _createDriver,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Create Driver Account",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
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
        fontSize: 13,
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
  final bool obscureText;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;

  const _SheetTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
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
          borderSide: const BorderSide(color: Appcolors.secondaryPurple, width: 1.5),
        ),
      ),
    );
  }
}