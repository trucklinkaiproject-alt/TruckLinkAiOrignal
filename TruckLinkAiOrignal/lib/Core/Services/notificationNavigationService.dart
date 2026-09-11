import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerAlertPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/orderDetailPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Pages/driverAlertPage.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Pages/driverOfferDetailPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/orderTrackingPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperOrderDetailPage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperalertpage.dart';

class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Map<String, dynamic>? _pendingPayload;
  bool _isNavigating = false;

  /// Store pending payload from terminated state
  void setPendingNotification(Map<String, dynamic> payload) {
    _pendingPayload = payload;
    debugPrint('[NotificationNavigationService] Pending notification stored: $payload');
  }

  /// Process any pending notification payload once UI / auth is ready
  Future<void> processPendingNotification() async {
    if (_pendingPayload == null) return;
    final payload = Map<String, dynamic>.from(_pendingPayload!);
    _pendingPayload = null;
    await handleNotificationTap(payload);
  }

  /// Resolve current logged-in user role
  Future<String> _resolveUserRole(String uid) async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection("User").doc(uid).get(),
        FirebaseFirestore.instance.collection("Broker").doc(uid).get(),
        FirebaseFirestore.instance.collection("Driver").doc(uid).get(),
      ]);

      if (results[0].exists) return 'User';
      if (results[1].exists) return 'Broker';
      if (results[2].exists) return 'Driver';
    } catch (e) {
      debugPrint('[NotificationNavigationService] Error resolving role: $e');
    }
    return '';
  }

  /// Central notification tap dispatcher
  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final BuildContext? context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('[NotificationNavigationService] Navigator context not ready, storing pending payload');
        _pendingPayload = data;
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('[NotificationNavigationService] User not logged in, storing pending payload');
        _pendingPayload = data;
        return;
      }

      final String currentUid = currentUser.uid;
      final String role = await _resolveUserRole(currentUid);

      final String type = (data['type'] ?? data['notification_type'] ?? '').toString().toLowerCase();
      final String orderId = (data['order_id'] ?? data['orderId'] ?? data['related_id'] ?? '').toString();
      final String chatId = (data['chat_id'] ?? data['chatId'] ?? '').toString();
      final String senderId = (data['sender_id'] ?? data['senderId'] ?? '').toString();
      final String senderName = (data['sender_name'] ?? data['senderName'] ?? 'User').toString();
      final String receiverRole = (data['receiver_role'] ?? data['receiverRole'] ?? 'Broker').toString();

      debugPrint('[NotificationNavigationService] Navigating for type: $type | role: $role | orderId: $orderId | chatId: $chatId');

      // ── CHAT NOTIFICATIONS ──────────────────────────────────────────────
      if (type == 'chat' || type == 'new_message') {
        final String targetChatId = chatId.isNotEmpty
            ? chatId
            : (senderId.isNotEmpty ? getDeterministicChatId(currentUid, senderId) : '');

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BrokerChatPage(
                chatId: targetChatId,
                receiverId: senderId.isNotEmpty ? senderId : null,
                receiverName: senderName,
                receiverRole: receiverRole,
                orderId: orderId.isNotEmpty ? orderId : null,
              ),
            ),
          );
        }
        return;
      }

      // ── SHIPMENT & ORDER NOTIFICATIONS ──────────────────────────────────
      if (orderId.isNotEmpty) {
        if (role == 'User') {
          // If in transit or delivered, allow tracking or order detail
          if (type == 'trip_started' || type == 'in_transit' || type == 'driver_at_pickup') {
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderTrackingPage(
                    orderStatusDetail: {
                      'orderId': orderId,
                      'id': orderId,
                      'orderNo': data['order_no'] ?? data['orderNo'] ?? orderId,
                      'userUid': currentUid,
                    },
                  ),
                ),
              );
            }
          } else {
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShipperOrderDetailPage(
                    orderDetails: {
                      'orderId': orderId,
                      'id': orderId,
                      'orderNo': data['order_no'] ?? data['orderNo'] ?? orderId,
                      'userUid': currentUid,
                    },
                  ),
                ),
              );
            }
          }
          return;
        } else if (role == 'Broker') {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsPage(
                  orderReqData: {
                    'orderId': orderId,
                    'id': orderId,
                    'orderNo': data['order_no'] ?? data['orderNo'] ?? orderId,
                    'brokerId': currentUid,
                  },
                ),
              ),
            );
          }
          return;
        } else if (role == 'Driver') {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DriverOfferDetailPage(
                  offer: {
                    'order_id': orderId,
                    'orderId': orderId,
                    'order_no': data['order_no'] ?? data['orderNo'] ?? orderId,
                    'driver_id': currentUid,
                  },
                ),
              ),
            );
          }
          return;
        }
      }

      // ── FALLBACK: ROLE NOTIFICATION / ALERT CENTER ───────────────────────
      if (context.mounted) {
        if (role == 'User') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShipperAlertPage()),
          );
        } else if (role == 'Broker') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BrokerAlertPage()),
          );
        } else if (role == 'Driver') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DriverAlertPage()),
          );
        }
      }
    } catch (e) {
      debugPrint('[NotificationNavigationService] Error during notification navigation: $e');
    } finally {
      _isNavigating = false;
    }
  }
}
