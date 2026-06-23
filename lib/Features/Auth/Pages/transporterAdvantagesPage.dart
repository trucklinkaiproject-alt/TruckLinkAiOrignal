import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/signUpPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/advantagePageRow.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';

class TransporterAdvantagesPage extends StatelessWidget {
  const TransporterAdvantagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 40, left: 20, right: 20),
        width: double.infinity,
        height: double.infinity,
        color: const Color.fromARGB(255, 207, 255, 239),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Appcolors.tertiaryGreen,
                    size: 30,
                  ),
                ),
              ),
          
              SvgPicture.asset(
                "assets/Images/trucksvg.svg",
                width: 100,
                color: Appcolors.tertiaryGreen,
              ),
              Text(
                "Transporter/Driver",
                style: TextStyle(
                  color: Appcolors.tertiaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
          
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
          
                  children: [
                    Text(
                      "TruckLink",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Appcolors.tertiaryGreen,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "AI",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Appcolors.tertiaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "Load , Deliver ,",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              Text(
                "Update.",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 50),
          
              AdvantagesPageRow(
                text: "Assign Trips",
                clr: Appcolors.tertiaryGreen,
              ),
              AdvantagesPageRow(
                text: "Update Shipment Status",
                clr: Appcolors.tertiaryGreen,
              ),
              AdvantagesPageRow(
                text: "Live Tracking",
                clr: Appcolors.tertiaryGreen,
              ),
              AdvantagesPageRow(
                text: "Proof of Delivery",
                clr: Appcolors.tertiaryGreen,
              ),
          
              SizedBox(height: 30),
              ContinueButton(
                text: "Continue",
                clr: Appcolors.tertiaryGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
