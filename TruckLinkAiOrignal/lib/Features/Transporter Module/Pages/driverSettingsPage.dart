import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/roleSelectionPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/Pages/driverTruckDetailsPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/Pages/findBrokerPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverBloc/driverCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverBloc/driverState.dart';
import 'package:trucklinkai_orignal/Core/Widgets/myReviewsPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/appBar.dart';

class DriverSettingsPage extends StatelessWidget {
  const DriverSettingsPage({super.key});

  Widget buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFEE2E2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? const Color(0xFFEF4444) : Colors.black87,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isDestructive ? const Color(0xFFEF4444) : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }

  Widget buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<DriverCubit, DriverState>(
          builder: (context, state) {
            if (state is! DriverLoadedState) {
              return const Center(
                child: CircularProgressIndicator(color: Appcolors.tertiaryGreen),
              );
            }

            final driver = state.driver;
            final bool hasTruck = driver.isTruckDetailsComplete;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AppBarContainer(title: "Driver Profile", backArrow: false),
                  const SizedBox(height: 16),

                  // Profile Header (Matches User / Broker Profile)
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Appcolors.tertiaryGreen.withOpacity(0.12),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Appcolors.tertiaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          driver.name.isNotEmpty ? driver.name : "Driver",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Appcolors.tertiaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Driver / Transporter',
                                style: TextStyle(
                                  color: Appcolors.tertiaryGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Section 1: Personal & Contact Information
                  buildSection([
                    buildProfileOption(
                      icon: Icons.person_outline,
                      title: 'Name',
                      subtitle: driver.name.isNotEmpty ? driver.name : 'Not set',
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    buildProfileOption(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: driver.email.isNotEmpty ? driver.email : 'Not set',
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    buildProfileOption(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      subtitle: driver.phone.isNotEmpty ? driver.phone : 'Not set',
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    buildProfileOption(
                      icon: Icons.badge_outlined,
                      title: 'Driver ID',
                      subtitle: driver.driverId,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section 2: Vehicle / Truck Details
                  buildSection([
                    buildProfileOption(
                      icon: Icons.local_shipping_outlined,
                      title: 'Vehicle Type',
                      subtitle: driver.vehicleType ?? 'Not specified',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverTruckDetailsPage(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    buildProfileOption(
                      icon: Icons.pin_outlined,
                      title: 'Truck Number',
                      subtitle: driver.vehicleNumber ?? 'Not specified',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverTruckDetailsPage(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    buildProfileOption(
                      icon: Icons.edit_note_rounded,
                      title: hasTruck ? 'Edit Truck Details' : 'Add Truck Details',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverTruckDetailsPage(),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section 3: Broker Network & Operations
                  buildSection([
                    buildProfileOption(
                      icon: Icons.business_outlined,
                      title: 'Broker Network',
                      subtitle: state.brokerName ?? (driver.brokerId != null ? 'Connected (${driver.brokerId})' : 'Not Connected'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FindBrokerPage(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    buildProfileOption(
                      icon: Icons.star_rate_rounded,
                      title: 'My Reviews',
                      subtitle: driver.driverRating > 0
                          ? '${driver.driverRating.toStringAsFixed(1)} ★ Rating'
                          : 'View your ratings & feedback',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyReviewsPage(
                              userId: driver.driverId,
                              userRole: 'Driver',
                              userName: driver.name,
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    buildProfileOption(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section 4: Log Out (Destructive Section matching Broker / User)
                  buildSection([
                    buildProfileOption(
                      icon: Icons.logout,
                      title: 'Log Out',
                      isDestructive: true,
                      onTap: () async {
                        await context.read<AuthCubit>().logOut(context);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ]),

                  const SizedBox(height: 36),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
