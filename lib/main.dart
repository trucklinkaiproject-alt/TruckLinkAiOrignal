import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/splashScreenPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqcubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';
import 'Core/Constants/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthCubit()),
          BlocProvider(create: (context) => UserCubit()),
          BlocProvider(create: (context) => CreateReqCubit()),
          BlocProvider(create: (context) => BrokerCubit()),

          
        ],
        child: TruckLinkApp(),
      ),);
}

class TruckLinkApp extends StatelessWidget {
  const TruckLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TruckLink AI",
      debugShowCheckedModeBanner: false,
       theme: ThemeData(
    textTheme: GoogleFonts.poppinsTextTheme(),
  ),
      home: const SplashPage(),
    );
  }
}
