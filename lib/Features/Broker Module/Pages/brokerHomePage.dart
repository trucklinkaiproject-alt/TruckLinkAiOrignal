import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/orderDetailPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerStates.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/widgets/brokerincomingreqcontainer.dart';

class BrokerHomePage extends StatefulWidget {
  const BrokerHomePage({super.key});

  @override
  State<BrokerHomePage> createState() => _BrokerHomePageState();
}

class _BrokerHomePageState extends State<BrokerHomePage> {
  @override
  void initState() {
    context.read<BrokerCubit>().fetchUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 70,
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: Appcolors.secondaryPurple),
              child: Row(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BlocBuilder<BrokerCubit, BrokerState>(
                    builder: (context, state) {
                      return Text(
                        state is BrokerLoadedState
                            ? "Hello, ${state.userData} !"
                            : "Hello, Unknown !",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              width: double.infinity,
              height: double.infinity,
              margin: EdgeInsets.only(top: 60),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Broker, Dashboard",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Appcolors.secondaryPurple,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        brokerHomeContainer(
                          "18",
                          "New Request",
                          const Color.fromARGB(255, 239, 233, 250),
                          Appcolors.secondaryPurple,
                          const Color.fromARGB(255, 154, 137, 192),
                        ),
                        brokerHomeContainer(
                          "20",
                          "Active Orders",
                          const Color.fromARGB(255, 255, 252, 224),
                          Colors.black,
                          Colors.black,
                        ),
                        brokerHomeContainer(
                          "56",
                          "Completed",
                          const Color.fromARGB(255, 217, 252, 235),
                          Colors.black,
                          Colors.black,
                        ),
                      ],
                    ),
                    SizedBox(height: 35),
                    Row(
                      children: [
                        Text(
                          "Incoming Orders",
                          style: TextStyle(
                            color: Appcolors.secondaryPurple,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          "View All",
                          style: TextStyle(
                            color: Color.fromARGB(255, 143, 133, 168),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    BrokerIcomingReqContainer(
                      orderNumber: "12345",
                      pickupLocation: "Mumbai",
                      dropLocation: "Delhi",
                      date: "20-04-2026",
                      status: "In Transit",
                      weight: "120",
                      itemType: "Electronics",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsPage(),
                          ),
                        );
                      },
                    ),
                    BrokerIcomingReqContainer(
                      orderNumber: "12340",
                      pickupLocation: "Lahore",
                      dropLocation: "Karachi",
                      date: "18-03-2026",
                      status: "Delivered",
                      weight: "120",
                      itemType: "Electronics",
                    ),
                    BrokerIcomingReqContainer(
                      orderNumber: "12340",
                      pickupLocation: "Lahore",
                      dropLocation: "Karachi",
                      date: "18-03-2026",
                      status: "Delivered",
                      weight: "120",
                      itemType: "Electronics",
                    ),
                    BrokerIcomingReqContainer(
                      orderNumber: "12340",
                      pickupLocation: "Lahore",
                      dropLocation: "Karachi",
                      date: "18-03-2026",
                      status: "Delivered",
                      weight: "120",
                      itemType: "Electronics",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget brokerHomeContainer(
    String quantity,
    String text,
    Color clr,
    Color? noClr,
    Color? txtClr,
  ) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: clr,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            quantity,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: noClr ?? Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: txtClr ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
