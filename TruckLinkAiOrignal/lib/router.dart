// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationNavigationService.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/splashScreenPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperhomePage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/createorderpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperorderpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperOrderDetailPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/orderTrackingPage.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/Pages/transporterHomePage.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/Pages/driverOfferDetailPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerAlertPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/orderDetailPage.dart';

final GoRouter router = GoRouter(
  navigatorKey: NotificationNavigationService.navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const ShipperHomePage(),
    ),
    GoRoute(
      path: '/create-order',
      builder: (context, state) => const CreateOrderPage(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const ShipperOrderPage(),
    ),
    GoRoute(
      path: '/order/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        return ShipperOrderDetailPage(
          orderDetails: extra ?? {'orderId': orderId, 'id': orderId},
        );
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final chatId = state.uri.queryParameters['chatId'] ?? extra?['chatId'] ?? '';
        return BrokerChatPage(
          chatId: chatId,
          receiverName: extra?['receiverName'] ?? 'Chat',
        );
      },
    ),
    GoRoute(
      path: '/tracking/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        return OrderTrackingPage(
          orderStatusDetail: extra ?? {'orderId': orderId, 'id': orderId},
        );
      },
    ),
    // Driver routes
    GoRoute(
      path: '/driver/home',
      builder: (context, state) => const TransporterHomePage(),
    ),
    GoRoute(
      path: '/driver/offer/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        return DriverOfferDetailPage(
          offer: extra ?? {'orderId': orderId, 'id': orderId},
        );
      },
    ),
    // Broker routes
    GoRoute(
      path: '/broker/alert',
      builder: (context, state) => const BrokerAlertPage(),
    ),
    GoRoute(
      path: '/broker/order/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        return OrderDetailsPage(
          orderReqData: extra ?? {'orderId': orderId, 'id': orderId},
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.uri}')),
  ),
);
