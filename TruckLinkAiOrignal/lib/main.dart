import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Widgets/noscrollbehaviour.dart';
import 'package:trucklinkai_orignal/Features/Auth/AuthBloc/authCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerQuoteBloc/brokerQuoteCubit.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/bloc/driverBloc/driverCubit.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/bloc/driverOffersBloc/driverOffersCubit.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/bloc/findBrokerBloc/findBrokerCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqcubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/OrderDetailBloc/orderDetialCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverRequestsBloc/brokerDriverRequestsCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverNetworkBloc/brokerDriverNetworkCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerAssignDriverBloc/brokerAssignDriverCubit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
import 'package:trucklinkai_orignal/Core/Services/pushNotificationService.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/brokerRecommendationBloc/brokerRecommendationCubit.dart';
import 'Core/Constants/firebase_options.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register top-level background FCM message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Push Notification Service (Channels, Local notifications, Permissions)
  await PushNotificationService().initialize();

  if (kIsWeb) {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
    } catch (e) {
      AppLogger.warn("Failed to set web auth persistence: $e", "Main");
    }
  }

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
          BlocProvider(create: (context) => BrokerRecommendationCubit()),
        ],
        child: const TruckLinkApp(),
      ),);
}

class TruckLinkApp extends StatelessWidget {
  const TruckLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      scrollBehavior: NoScrollbarBehavior(),
      title: "TruckLink AI",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
    );
  }
}
