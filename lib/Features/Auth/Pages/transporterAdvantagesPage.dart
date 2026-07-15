
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/signUpPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/featureCard.dart';

class TransporterAdvantagesPage extends StatelessWidget {
  const TransporterAdvantagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final bool isMobile = width < 600;
            final bool isTablet = width >= 600 && width < 1024;

            final double horizontalPadding = isMobile
                ? 22
                : width * (isTablet ? 0.1 : 0.12);

            final double logoSize = (width * 0.16).clamp(64.0, 88.0);

            final double titleFont = (width * 0.065).clamp(22.0, 30.0);

            final double subtitleFont = (width * 0.04).clamp(14.0, 17.0);

            return SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: height),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   
                    BackArrowButton(onTap: () => Navigator.pop(context)),

                    SizedBox(height: isMobile ? 20 : 28),

                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              color: Appcolors.tertiaryGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.local_shipping_outlined,
                              color: Colors.white,
                              size: logoSize * 0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Appcolors.tertiaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Transporter/Driver",
                              style: TextStyle(
                                color: Appcolors.tertiaryGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "TruckLink AI",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleFont,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Load, Deliver, Update.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: subtitleFont,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 30 : 40),

              
                    FeatureCard(
                      color: Appcolors.tertiaryGreen,
                      items: const [
                        "Assign Trips",
                        "Update Shipment Status",
                        "Live Tracking",
                        "Proof of Delivery",
                      ],
                    ),

                    SizedBox(height: isMobile ? 30 : 44),

                  
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolors.tertiaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignUpPage()),
                          );
                        },
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isMobile ? 20 : 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
