import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/User Module/Pages/brokerchatpage.dart';

class BrokerChatInboxPage extends StatefulWidget {
  const BrokerChatInboxPage({super.key});

  @override
  State<BrokerChatInboxPage> createState() => _BrokerChatInboxPageState();
}

class _BrokerChatInboxPageState extends State<BrokerChatInboxPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All"; // "All", "Customers", "Drivers"

  // In-memory cache for participant profiles to prevent redundant Firestore reads
  static final Map<String, Map<String, dynamic>> _participantCache = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getParticipantProfile(
      String participantId, String? explicitRole) async {
    if (participantId.isEmpty) {
      return {'name': 'Unknown User', 'role': 'User', 'avatar': null, 'phone': ''};
    }

    if (_participantCache.containsKey(participantId)) {
      return _participantCache[participantId]!;
    }

    Map<String, dynamic> result = {
      'name': 'Participant',
      'role': explicitRole ?? 'User',
      'avatar': null,
      'phone': '',
    };

    try {
      // 1. Check User collection
      final userDoc = await _firestore.collection('User').doc(participantId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final u = userDoc.data()!;
        final name = (u['name'] ??
                u['full_name'] ??
                u['username'] ??
                u['userName'] ??
                'Customer')
            .toString();
        final avatar = u['profile_image'] ?? u['profileImage'] ?? u['avatar'];
        final phone = (u['phone'] ?? u['phoneNumber'] ?? u['phone_number'] ?? '').toString();
        result = {'name': name, 'role': 'Customer', 'avatar': avatar, 'phone': phone};
        _participantCache[participantId] = result;
        return result;
      }

      // 2. Check Driver collection
      final driverDoc =
          await _firestore.collection('Driver').doc(participantId).get();
      if (driverDoc.exists && driverDoc.data() != null) {
        final d = driverDoc.data()!;
        final name = (d['name'] ??
                d['driver_name'] ??
                d['driverName'] ??
                d['full_name'] ??
                'Driver')
            .toString();
        final avatar = d['profile_image'] ?? d['profileImage'] ?? d['avatar'];
        final phone = (d['phone'] ?? d['phoneNumber'] ?? d['phone_number'] ?? '').toString();
        result = {'name': name, 'role': 'Driver', 'avatar': avatar, 'phone': phone};
        _participantCache[participantId] = result;
        return result;
      }

      // 3. Check Broker collection (if chatting with another broker)
      final brokerDoc =
          await _firestore.collection('Broker').doc(participantId).get();
      if (brokerDoc.exists && brokerDoc.data() != null) {
        final b = brokerDoc.data()!;
        final name = (b['name'] ?? b['broker_name'] ?? b['brokerName'] ?? 'Broker').toString();
        final avatar = b['profile_image'] ?? b['profileImage'] ?? b['avatar'];
        result = {'name': name, 'role': 'Broker', 'avatar': avatar, 'phone': ''};
        _participantCache[participantId] = result;
        return result;
      }
    } catch (_) {}

    _participantCache[participantId] = result;
    return result;
  }

  String _formatChatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return "";
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dt.year, dt.month, dt.day);
    final difference = today.difference(messageDay).inDays;

    if (difference == 0) {
      return DateFormat('h:mm a').format(dt);
    } else if (difference == 1) {
      return "Yesterday";
    } else if (difference < 7) {
      return DateFormat('EEE').format(dt); // e.g. Wed
    } else {
      return DateFormat('MMM d').format(dt); // e.g. Sep 5
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentBrokerId = _auth.currentUser?.uid ?? '';

    if (currentBrokerId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: SafeArea(
          child: Center(
            child: Text(
              "Please sign in to view your chats.",
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final double horizontalPadding = isMobile ? 20 : width * 0.12;

            return Column(
              children: [
                // ── Top Header ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    15,
                    horizontalPadding,
                    10,
                  ),
                  child: Row(
                    children: [
                      BackArrowButton(onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          "Messages & Inquiries",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Real-time Total Unread Badge Stream
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection("chats")
                            .where("participants", arrayContains: currentBrokerId)
                            .snapshots(),
                        builder: (context, snap) {
                          int totalUnread = 0;
                          if (snap.hasData && snap.data != null) {
                            for (final doc in snap.data!.docs) {
                              final d = doc.data() as Map<String, dynamic>;
                              final u = (d['unreadCount_$currentBrokerId'] as num?)?.toInt() ?? 0;
                              totalUnread += u;
                            }
                          }
                          if (totalUnread == 0) return const SizedBox.shrink();

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Appcolors.secondaryPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$totalUnread new",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Search & Filter Section ─────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    6,
                    horizontalPadding,
                    10,
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: "Search conversations or orders...",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13.5,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter Chips
                      Row(
                        children: [
                          _buildFilterChip("All"),
                          const SizedBox(width: 8),
                          _buildFilterChip("Customers"),
                          const SizedBox(width: 8),
                          _buildFilterChip("Drivers"),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Real-Time Conversation List Stream ──────────────────
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection("chats")
                        .where("participants", arrayContains: currentBrokerId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Appcolors.secondaryPurple),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Failed to load conversations: ${snapshot.error}",
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return _buildEmptyState(
                          title: "No conversations yet",
                          subtitle: "Incoming inquiries and messages from Shippers & Drivers will appear here in real time.",
                        );
                      }

                      // Group all conversation documents strictly by other participant ID
                      final Map<String, _BrokerConversationItem> conversationMap = {};

                      for (final doc in docs) {
                        final chatData = doc.data() as Map<String, dynamic>;
                        final String rawChatId = doc.id;

                        // Extract other participant
                        final participants = (chatData['participants'] as List<dynamic>?) ?? [];
                        String otherId = participants.firstWhere(
                          (p) => p.toString() != currentBrokerId && p.toString().isNotEmpty,
                          orElse: () => '',
                        ).toString();

                        // Fallback if participants array was missing
                        if (otherId.isEmpty) {
                          if (chatData['receiverId'] != null && chatData['receiverId'].toString() != currentBrokerId) {
                            otherId = chatData['receiverId'].toString();
                          } else if (chatData['senderId'] != null && chatData['senderId'].toString() != currentBrokerId) {
                            otherId = chatData['senderId'].toString();
                          } else if (chatData['userUid'] != null && chatData['userUid'].toString() != currentBrokerId) {
                            otherId = chatData['userUid'].toString();
                          } else if (chatData['driverId'] != null && chatData['driverId'].toString() != currentBrokerId) {
                            otherId = chatData['driverId'].toString();
                          } else {
                            final parts = rawChatId.split('_');
                            for (final part in parts) {
                              if (part != 'chat' && part != 'user' && part != 'broker' && part != 'driver' && part != 'order' && part != currentBrokerId && part.length > 5) {
                                otherId = part;
                                break;
                              }
                            }
                          }
                        }

                        if (otherId.isEmpty || otherId == currentBrokerId) continue;

                        final String canonicalChatId = getDeterministicChatId(currentBrokerId, otherId);
                        final String lastMessage = (chatData['lastMessage'] ?? chatData['text'] ?? "Started conversation").toString();
                        final dynamic lastMessageTime = chatData['lastMessageTime'] ?? chatData['timestamp'] ?? chatData['created_at'];
                        final String lastSenderId = (chatData['lastSenderId'] ?? '').toString();
                        final int unreadCount = (chatData['unreadCount_$currentBrokerId'] as num?)?.toInt() ?? 0;
                        final String orderId = (chatData['orderId'] ?? chatData['order_id'] ?? chatData['orderNo'] ?? '').toString();

                        String? inferredRole;
                        if (rawChatId.contains("_driver_") || rawChatId.contains("driver")) {
                          inferredRole = "Driver";
                        } else if (rawChatId.contains("_user_") || rawChatId.contains("user")) {
                          inferredRole = "Customer";
                        }

                        DateTime docDt = DateTime(1970);
                        if (lastMessageTime is Timestamp) {
                          docDt = lastMessageTime.toDate();
                        } else if (lastMessageTime is DateTime) {
                          docDt = lastMessageTime;
                        }

                        if (!conversationMap.containsKey(otherId)) {
                          conversationMap[otherId] = _BrokerConversationItem(
                            canonicalChatId: canonicalChatId,
                            otherParticipantId: otherId,
                            lastMessage: lastMessage,
                            lastMessageTime: lastMessageTime,
                            latestDateTime: docDt,
                            lastSenderId: lastSenderId,
                            unreadCount: unreadCount,
                            orderId: orderId,
                            inferredRole: inferredRole,
                            rawChatId: rawChatId,
                          );
                        } else {
                          final existing = conversationMap[otherId]!;
                          final int combinedUnread = existing.unreadCount + unreadCount;

                          if (docDt.isAfter(existing.latestDateTime)) {
                            conversationMap[otherId] = _BrokerConversationItem(
                              canonicalChatId: canonicalChatId,
                              otherParticipantId: otherId,
                              lastMessage: lastMessage.isNotEmpty ? lastMessage : existing.lastMessage,
                              lastMessageTime: lastMessageTime ?? existing.lastMessageTime,
                              latestDateTime: docDt,
                              lastSenderId: lastSenderId.isNotEmpty ? lastSenderId : existing.lastSenderId,
                              unreadCount: combinedUnread,
                              orderId: orderId.isNotEmpty ? orderId : existing.orderId,
                              inferredRole: inferredRole ?? existing.inferredRole,
                              rawChatId: rawChatId,
                            );
                          } else {
                            existing.unreadCount = combinedUnread;
                            if (existing.lastMessage.isEmpty && lastMessage.isNotEmpty) {
                              existing.lastMessage = lastMessage;
                            }
                          }
                        }
                      }

                      // Unique 1-per-person conversations sorted descending by latest activity
                      final sortedConversations = conversationMap.values.toList()
                        ..sort((a, b) => b.latestDateTime.compareTo(a.latestDateTime));

                      if (sortedConversations.isEmpty) {
                        return _buildEmptyState(
                          title: "No conversations yet",
                          subtitle: "Incoming inquiries and messages from Shippers & Drivers will appear here in real time.",
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          6,
                          horizontalPadding,
                          20,
                        ),
                        itemCount: sortedConversations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final conv = sortedConversations[index];

                          return FutureBuilder<Map<String, dynamic>>(
                            future: _getParticipantProfile(conv.otherParticipantId, conv.inferredRole),
                            builder: (context, profileSnap) {
                              final profile = profileSnap.data ?? {
                                'name': 'Participant',
                                'role': conv.inferredRole ?? 'Customer',
                                'avatar': null,
                              };

                              final String participantName = profile['name'] ?? 'User';
                              final String participantRole = profile['role'] ?? conv.inferredRole ?? 'Customer';
                              final String? avatarUrl = profile['avatar'];

                              // Filter by search query
                              if (_searchQuery.isNotEmpty) {
                                final matchesName = participantName.toLowerCase().contains(_searchQuery);
                                final matchesOrder = conv.orderId.toLowerCase().contains(_searchQuery);
                                final matchesMsg = conv.lastMessage.toLowerCase().contains(_searchQuery);

                                if (!matchesName && !matchesOrder && !matchesMsg) {
                                  return const SizedBox.shrink();
                                }
                              }

                              // Filter by role chip
                              if (_selectedFilter == "Customers" && participantRole != "Customer") {
                                return const SizedBox.shrink();
                              }
                              if (_selectedFilter == "Drivers" && participantRole != "Driver") {
                                return const SizedBox.shrink();
                              }

                              return _buildConversationTile(
                                context: context,
                                chatId: conv.canonicalChatId,
                                participantId: conv.otherParticipantId,
                                participantName: participantName,
                                participantRole: participantRole,
                                avatarUrl: avatarUrl,
                                orderId: conv.orderId,
                                lastMessage: conv.lastMessage,
                                lastMessageTime: conv.lastMessageTime,
                                lastSenderId: conv.lastSenderId,
                                currentBrokerId: currentBrokerId,
                                unreadCount: conv.unreadCount,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Appcolors.secondaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Appcolors.secondaryPurple : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Appcolors.secondaryPurple.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile({
    required BuildContext context,
    required String chatId,
    required String participantId,
    required String participantName,
    required String participantRole,
    required String? avatarUrl,
    required String orderId,
    required String lastMessage,
    required dynamic lastMessageTime,
    required String lastSenderId,
    required String currentBrokerId,
    required int unreadCount,
  }) {
    final bool isUnread = unreadCount > 0;
    final bool isDriver = participantRole.toLowerCase() == 'driver';
    final Color roleColor = isDriver ? Appcolors.tertiaryGreen : Appcolors.primaryBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BrokerChatPage(
                chatId: chatId,
                receiverId: participantId,
                receiverName: participantName,
                brokerId: participantId,
                brokerName: participantName,
                receiverRole: participantRole,
                orderId: orderId,
                brokerAvatar: avatarUrl,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnread
                  ? Appcolors.secondaryPurple.withOpacity(0.35)
                  : Colors.grey.withOpacity(0.12),
              width: isUnread ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnread
                    ? Appcolors.secondaryPurple.withOpacity(0.06)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Participant Avatar ──────────────────────────────────
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: roleColor.withOpacity(0.12),
                      border: Border.all(
                        color: roleColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  participantName.isNotEmpty
                                      ? participantName[0].toUpperCase()
                                      : "U",
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: roleColor,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                participantName.isNotEmpty
                                    ? participantName[0].toUpperCase()
                                    : "U",
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: roleColor,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: roleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        isDriver ? Icons.local_shipping_rounded : Icons.person_rounded,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),

              // ── Middle: Name, Role/Order Tag, Latest Message ─────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participantName,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Timestamp
                        Text(
                          _formatChatTimestamp(lastMessageTime),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: isUnread ? Appcolors.secondaryPurple : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Role & Order Chip Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            participantRole,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                            ),
                          ),
                        ),
                        if (orderId.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Order #$orderId",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Direct Inquiry",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Latest message preview
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastSenderId == currentBrokerId
                                ? "You: $lastMessage"
                                : lastMessage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                              color: isUnread ? Colors.black87 : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Appcolors.secondaryPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
                            child: Text(
                              "$unreadCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Appcolors.secondaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: Appcolors.secondaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokerConversationItem {
  final String canonicalChatId;
  final String otherParticipantId;
  String lastMessage;
  dynamic lastMessageTime;
  DateTime latestDateTime;
  String lastSenderId;
  int unreadCount;
  String orderId;
  String? inferredRole;
  String rawChatId;

  _BrokerConversationItem({
    required this.canonicalChatId,
    required this.otherParticipantId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.latestDateTime,
    required this.lastSenderId,
    required this.unreadCount,
    required this.orderId,
    this.inferredRole,
    required this.rawChatId,
  });
}
