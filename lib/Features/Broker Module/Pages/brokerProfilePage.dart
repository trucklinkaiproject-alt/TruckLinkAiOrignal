import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/roleSelectionPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/appBar.dart';

class BrokerProfilePage extends StatelessWidget {
  const BrokerProfilePage({super.key});

  Widget buildProfileOption({
    required IconData icon,
    required String title,
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppBarContainer(title: "My Profile",backArrow: false,),
            const SizedBox(height: 16),

            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Appcolors.secondaryPurple.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Appcolors.secondaryPurple,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'John Doe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),

                  Text('Broker', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // First Section
            buildSection([
              buildProfileOption(
                icon: Icons.person_outline,
                title: 'Personal Information',
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              buildProfileOption(
                icon: Icons.business_center_outlined,
                title: 'Business Details',
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              buildProfileOption(icon: Icons.payment, title: 'Payment Methods'),
              Divider(height: 1, color: Colors.grey.shade300),
              buildProfileOption(
                icon: Icons.location_on_outlined,
                title: 'Saved Addresses',
              ),
            ]),

            const SizedBox(height: 24),

            // Second Section
            buildSection([
              buildProfileOption(
                icon: Icons.help_outline,
                title: 'Help & Support',
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              buildProfileOption(
                icon: Icons.settings_outlined,
                title: 'Settings',
              ),
            ]),

            const SizedBox(height: 24),

            // Logout Section
            buildSection([
              buildProfileOption(
                icon: Icons.logout,
                title: 'Log Out',
                isDestructive: true,
                onTap: () {
                  context.read<AuthCubit>().logOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoleSelectionPage(),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
