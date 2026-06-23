import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerDetailpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/appBar.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/brokerdetailcontainer.dart';

class BrokerSelectionPage extends StatefulWidget {
  const BrokerSelectionPage({super.key});

  @override
  State<BrokerSelectionPage> createState() => _BrokerSelectionPageState();
}

class _BrokerSelectionPageState extends State<BrokerSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            color: Appcolors.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBarContainer(title: "Choose Broker"),
                SizedBox(height: 20),
                Text(
                  "Recommended For You",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Brokerdetailcontainer(
                  name: "John Doe",
                  Location: "Delhi, India",
                  rating: "4.5",
                  reviews: "200",
                  estTime: "2 hours",
                  ontap: () {
                    String brokerID = getBrokerUserId();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BrokerDetailPage(),
                      ),
                    );
                  },
                ),
                Brokerdetailcontainer(
                  name: "John Doe",
                  Location: "Delhi, India",
                  rating: "4.5",
                  reviews: "200",
                  estTime: "2 hours",
                ),
                Brokerdetailcontainer(
                  name: "John Doe",
                  Location: "Delhi, India",
                  rating: "4.5",
                  reviews: "200",
                  estTime: "2 hours",
                ),
                Brokerdetailcontainer(
                  name: "John Doe",
                  Location: "Delhi, India",
                  rating: "4.5",
                  reviews: "200",
                  estTime: "2 hours",
                ),
                Brokerdetailcontainer(
                  name: "John Doe",
                  Location: "Delhi, India",
                  rating: "4.5",
                  reviews: "200",
                  estTime: "2 hours",
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "View More Brokers",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_downward, color: Colors.blue, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getBrokerUserId() {
    String uid = DateTime.now().millisecondsSinceEpoch.toString();
    return uid;
  }
}
