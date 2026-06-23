import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/signupTextField.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authState.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/signUpPage.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokernavbar.dart';


import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/shipperbottomnavbar.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Pages/transporterHomePage.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool userChecked = false;
  bool brokerChecked = false;
  bool driverChecked = false;

  @override
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) {
              if(state.role=="User"){
                return ShipperBottomNavBar();
              }
              else if(state.role=="Broker"){
                //return BrokerHomePage();
                return BrokerBottomNavBar();
              }
              else if(state.role=="Driver"){
                //return DriverHomePage();
                return TransporterHomePage();
              }
              else{
                return ShipperBottomNavBar();
              }
            }),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            width: double.infinity,
            height: double.infinity,
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
                        color: Appcolors.primaryBlue,
                        size: 30,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      child: Image.asset(
                        "assets/Images/TruckLink AI.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "TruckLink AI",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Appcolors.primaryBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "Login to Continue",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 40),
                  SignUpTextField(
                    hintText: "Email",
                    controller: emailController,
                    type: TextInputType.emailAddress,
                  ),
                  SignUpTextField(
                    hintText: "Password",
                    controller: passwordController,
                    obscureText: true,
                    
                  ),

                  Container(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          //width:50,
                          height: 30,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: userChecked,
                                onChanged: (value) {
                                  setState(() {
                                    userChecked = value!;
                                    brokerChecked = false;
                                    driverChecked = false;
                                  });
                                },
                              ),
                              Text(
                                "User",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          //width:50,
                          height: 30,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: brokerChecked,
                                onChanged: (value) {
                                  setState(() {
                                    brokerChecked = value!;
                                    userChecked = false;
                                    driverChecked = false;
                                  });
                                },
                              ),
                              Text(
                                "Broker",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          //width:50,
                          height: 30,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: driverChecked,
                                onChanged: (value) {
                                  setState(() {
                                    driverChecked = value!;
                                    userChecked = false;
                                    brokerChecked = false;
                                  });
                                },
                              ),
                              Text(
                                "Driver",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return ContinueButton(
                        text: state is AuthLoading
                            ? "Logging In..."
                            : "Continue",
                        clr: Appcolors.primaryBlue,
                        onTap: state is AuthLoading
                            ? null
                            : () {
                                context.read<AuthCubit>().logIn(
                                  email: emailController.text,
                                  password: passwordController.text,
                                  role: userChecked
                                      ? "User"
                                      : brokerChecked
                                      ? "Broker"
                                      : driverChecked
                                      ? "Driver"
                                      : "",
                                );
                              },
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 14,
                            color: Appcolors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
