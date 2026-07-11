import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerDetailpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/appBar.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/brokerdetailcontainer.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerState.dart';

class BrokerSelectionPage extends StatefulWidget {
  const BrokerSelectionPage({super.key});

  @override
  State<BrokerSelectionPage> createState() => _BrokerSelectionPageState();
}

class _BrokerSelectionPageState extends State<BrokerSelectionPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<GetBrokerCubit>().fetchAllBroker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            color: Appcolors.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBarContainer(title: "Choose Broker", backArrow: true),
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
          
                BlocBuilder<GetBrokerCubit, GetBrokerState>(
                  builder: (context, state) {
                    if (state is GetBrokerLoadingState) {
                      return const Center(child: CircularProgressIndicator());
                    }
          
                    if (state is GetBrokerLoadedState) {
                      final brokers = context.read<GetBrokerCubit>().brokers;
                      Map<String,dynamic> broker;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: brokers.length,
                        itemBuilder: (context, index) {
                          broker = brokers[index];
                         
          
                          return Brokerdetailcontainer(
                            name: broker["name"] ?? "",
                            Location:
                                broker["location"] ?? "Not Specify by broker",
                            rating: broker["rating"]?.toString() ?? "0",
                            reviews: broker["reviews"]?.toString() ?? "0",
                            estTime: broker["estimatedTime"] ?? "0",
                            brokerUid: broker["uid"],
                            ontap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BrokerDetailPage(brokerData: brokers[index],),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
          
                    return const Center(child: Text("No Broker Available"));
                  },
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
                SizedBox(height: 20),
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
