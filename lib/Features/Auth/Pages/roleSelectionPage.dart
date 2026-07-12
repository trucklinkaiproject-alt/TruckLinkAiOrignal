
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/brokerAdvantagesPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/shipperAdvantagesPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/transporterAdvantagesPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/roleListTile.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double logoSize = 150;
    double titleFont = (screenWidth * 0.065).clamp(22.0, 28.0);
    double subtitleFont = (screenWidth * 0.04).clamp(14.0, 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 
                  Container(
                    width: logoSize,
                    height: logoSize,
                    
                    child: Image.asset(
                      "assets/Images/Only Logo.png",
                      fit: BoxFit.fill,
                     
                    ),
                  ),

                 

                  Text(
                    "Smart Logistics",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleFont,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Select a module to explore",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleFont,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.035),

                  
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return RoleListTile(
                        title: state is AuthLoading
                            ? "Loading ..."
                            : "Customer Module",
                        subtitle:
                            "Create shipments, select brokers, track orders",
                        icon: Icons.person_outline_sharp,
                        color: Appcolors.primaryBlue,
                        onTap: state is AuthLoading
                            ? null
                            : () {
                                context.read<AuthCubit>().getRoleName("User");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ShipperAdvantagesPage(),
                                  ),
                                );
                              },
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                 
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return RoleListTile(
                        title: state is AuthLoading
                            ? "Loading ..."
                            : "Broker Module",
                        subtitle:
                            "Manage requests, assign transport, view bilty",
                        icon: Icons.interpreter_mode_outlined,
                        color: Appcolors.secondaryPurple,
                        onTap: state is AuthLoading
                            ? null
                            : () {
                                context.read<AuthCubit>().getRoleName("Broker");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BrokerAdvantagesPage(),
                                  ),
                                );
                              },
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return RoleListTile(
                        title: state is AuthLoading
                            ? "Loading ..."
                            : "Driver Module",
                        subtitle:
                            "View deliveries, update status, manage orders",
                        icon: Icons.fire_truck_sharp,
                        color: Appcolors.tertiaryGreen,
                        onTap: state is AuthLoading
                            ? null
                            : () {
                                context.read<AuthCubit>().getRoleName("Driver");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TransporterAdvantagesPage(),
                                  ),
                                );
                              },
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  Text(
                    "Click any module to explore the complete interface",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                  ),

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


