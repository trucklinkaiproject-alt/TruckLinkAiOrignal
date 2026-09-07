import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Widgets/noscrollbehaviour.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/splashScreenPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerQuoteBloc/brokerQuoteCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqcubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/OrderDetailBloc/orderDetialCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverBloc/driverCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/findBrokerBloc/findBrokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverRequestsBloc/brokerDriverRequestsCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverNetworkBloc/brokerDriverNetworkCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerAssignDriverBloc/brokerAssignDriverCubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverOffersBloc/driverOffersCubit.dart';
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
          BlocProvider(create: (context) => GetBrokerCubit()),
          BlocProvider(create: (context) => OrderDetailCubit()),
          BlocProvider(create: (context) => BrokerQuoteCubit()),
          BlocProvider(create: (context) => DriverCubit()),
          BlocProvider(create: (context) => FindBrokerCubit()),
          BlocProvider(create: (context) => BrokerDriverRequestsCubit()),
          BlocProvider(create: (context) => BrokerDriverNetworkCubit()),
          BlocProvider(create: (context) => BrokerAssignDriverCubit()),
          BlocProvider(create: (context) => DriverOffersCubit()),
        ],
        child: TruckLinkApp(),
      ),);
}

class TruckLinkApp extends StatelessWidget {
  const TruckLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: NoScrollbarBehavior(),
      title: "TruckLink AI",
      debugShowCheckedModeBanner: false,
       theme:ThemeData(
    fontFamily: 'Poppins',
  ),
      home: const SplashPage(),
    );
  }
}
