import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/createorderpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/homequickcontainer.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/ordercontainer.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/shipperhomebox.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/userstate.dart';

class ShipperHomePage extends StatefulWidget {
  const ShipperHomePage({super.key});

  @override
  State<ShipperHomePage> createState() => _ShipperHomePageState();
}

class _ShipperHomePageState extends State<ShipperHomePage> {
  @override
  void initState() {
    context.read<UserCubit>().fetchUserData();
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
              decoration: BoxDecoration(color: Appcolors.primaryBlue),
              child: Row(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  BlocBuilder<UserCubit, UserState>(
                    builder: (context, state) {
                    
                      
                      return Text(
                        state is UserLoadedState
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
                    onPressed: () {
                      
                    },
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
                    SizedBox(height: 10),
                    Text(
                      "Book Your Shipment with ease",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 118, 118, 118),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShipperHomeBox(
                          text1: "Create",
                          text2: "Shipment",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateOrderPage(),
                              ),
                            );
                          },
                          icn: Icon(Icons.add_circle, color: Colors.white),
                          clr: Colors.white,
                          ctnclr: Appcolors.primaryBlue,
                        ),
                        SizedBox(width: 30),
                        ShipperHomeBox(
                          text1: "Track",
                          text2: "Order",
                          icn: Icon(
                            Icons.track_changes,
                            color: Appcolors.primaryBlue,
                          ),
                          clr: Colors.black,
                          ctnclr: Color.fromARGB(255, 238, 245, 255),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Quick Actions",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        HomeQuickContainer(
                          text1: "My Orders",
                          icn: Icon(Icons.list_outlined),
                        ),
                        HomeQuickContainer(
                          text1: "Saved Address",
                          icn: Icon(
                            Icons.bookmark,
                            color: Appcolors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Recent Orders",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    OrderContainer(
                      orderNumber: "12345",
                      pickupLocation: "Mumbai",
                      dropLocation: "Delhi",
                      date: "20-04-2026",
                      status: "In Transit",
                    ),
                    OrderContainer(
                      orderNumber: "12340",
                      pickupLocation: "Lahore",
                      dropLocation: "Karachi",
                      date: "18-03-2026",
                      status: "Delivered",
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
}
