import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/User Module/Pages/brokerchatpage.dart';

class UserChatInboxPage extends StatefulWidget {
  const UserChatInboxPage({super.key});

  @override
  State<UserChatInboxPage> createState() => _UserChatInboxPageState();
}

class _UserChatInboxPageState extends State<UserChatInboxPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All"; // "All", "Brokers", "Drivers"

  // In-memory cache for participant profiles
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
      return {'name': 'Unknown', 'role': 'User', 'avatar': null, 'phone': ''};
    }

    if (_participantCache.containsKey(participantId)) {
      return _participantCache[participantId]!;
    }

    Map<String, dynamic> result = {
      'name': 'Participant',
      'role': explicitRole ?? 'Broker',
      'avatar': null,
      'phone': '',
    };

    try {
      // 1. Check Broker collection first
      final brokerDoc =
          await _firestore.collection('Broker').doc(participantId).get();
      if (brokerDoc.exists && brokerDoc.data() != null) {
        final b = brokerDoc.data()!;
        final name = (b['name'] ??
                b['broker_name'] ??
                b['brokerName'] ??
                b['full_name'] ??
                'Broker')
            .toString();
        final avatar = b['profile_image'] ?? b['profileImage'] ?? b['avatar'];
        final phone = (b['phone'] ?? b['phone_number'] ?? '').toString();
        result = {'name': name, 'role': 'Broker', 'avatar': avatar, 'phone': phone};
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

      // 3. Check User collection (if chatting with another shipper/user)
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
      return DateFormat('EEE').format(dt);
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
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
                            .where("participants", arrayContains: currentUserId)
                            .snapshots(),
                        builder: (context, snap) {
                          int totalUnread = 0;
                          if (snap.hasData && snap.data != null) {
                            for (final doc in snap.data!.docs) {
                              final d = doc.data() as Map<String, dynamic>? ?? {};
                              final count = d['unreadCount_$currentUserId'] ?? 0;
                              if (count is num) {
                                totalUnread += count.toInt();
                              }
                            }
                          }
                          if (totalUnread <= 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Appcolors.primaryBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "$totalUnread unread",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Search Bar ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 8,
                  ),
                  child: Container(
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
                        hintText: "Search chats by name or message...",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13.5,
                          fontWeight: FontWeight.normal,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // ── Category Filter Pills ───────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill("All"),
                        const SizedBox(width: 8),
                        _buildFilterPill("Brokers"),
                        const SizedBox(width: 8),
                        _buildFilterPill("Drivers"),
                        const SizedBox(width: 8),
                        _buildFilterPill("Shippers"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ── Real-Time Conversations List ─────────────────────────
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection("chats")
                        .where("participants", arrayContains: currentUserId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Appcolors.primaryBlue,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error loading chats: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return _buildEmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: "No Conversations Yet",
                          subtitle:
                              "When you send requests to brokers or communicate with assigned drivers, your chats will appear here.",
                        );
                      }

                      // Group all conversation documents strictly by other participant ID
                      final Map<String, _UserConversationItem> conversationMap = {};

                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final String rawChatId = doc.id;

                        // Find the other participant ID
                        final List<dynamic> participants = data['participants'] ?? [];
                        String otherUserId = participants.firstWhere(
                          (p) => p.toString() != currentUserId && p.toString().isNotEmpty,
                          orElse: () => '',
                        ).toString();

                        // Fallback if participants array was missing
                        if (otherUserId.isEmpty) {
                          if (data['receiverId'] != null && data['receiverId'].toString() != currentUserId) {
                            otherUserId = data['receiverId'].toString();
                          } else if (data['senderId'] != null && data['senderId'].toString() != currentUserId) {
                            otherUserId = data['senderId'].toString();
                          } else if (data['brokerId'] != null && data['brokerId'].toString() != currentUserId) {
                            otherUserId = data['brokerId'].toString();
                          } else if (data['driverId'] != null && data['driverId'].toString() != currentUserId) {
                            otherUserId = data['driverId'].toString();
                          } else {
                            final parts = rawChatId.split('_');
                            for (final part in parts) {
                              if (part != 'chat' && part != 'user' && part != 'broker' && part != 'driver' && part != 'order' && part != currentUserId && part.length > 5) {
                                otherUserId = part;
                                break;
                              }
                            }
                          }
                        }

                        if (otherUserId.isEmpty || otherUserId == currentUserId) continue;

                        final String canonicalChatId = getDeterministicChatId(currentUserId, otherUserId);
                        final String lastMessage = (data['lastMessage'] ?? data['text'] ?? '').toString();
                        final dynamic lastMessageTime = data['lastMessageTime'] ?? data['timestamp'] ?? data['created_at'];
                        final int unreadCount = (data['unreadCount_$currentUserId'] as num?)?.toInt() ?? 0;
                        final String orderId = (data['orderId'] ?? data['order_id'] ?? '').toString();
                        final String explicitRole = (data['role_$otherUserId'] ?? data['role'] ?? '').toString();

                        DateTime docDt = DateTime(1970);
                        if (lastMessageTime is Timestamp) {
                          docDt = lastMessageTime.toDate();
                        } else if (lastMessageTime is DateTime) {
                          docDt = lastMessageTime;
                        }

                        if (!conversationMap.containsKey(otherUserId)) {
                          conversationMap[otherUserId] = _UserConversationItem(
                            canonicalChatId: canonicalChatId,
                            otherUserId: otherUserId,
                            lastMessage: lastMessage,
                            lastMessageTime: lastMessageTime,
                            latestDateTime: docDt,
                            unreadCount: unreadCount,
                            orderId: orderId,
                            explicitRole: explicitRole,
                            rawChatId: rawChatId,
                          );
                        } else {
                          final existing = conversationMap[otherUserId]!;
                          final int combinedUnread = existing.unreadCount + unreadCount;

                          if (docDt.isAfter(existing.latestDateTime)) {
                            conversationMap[otherUserId] = _UserConversationItem(
                              canonicalChatId: canonicalChatId,
                              otherUserId: otherUserId,
                              lastMessage: lastMessage.isNotEmpty ? lastMessage : existing.lastMessage,
                              lastMessageTime: lastMessageTime ?? existing.lastMessageTime,
                              latestDateTime: docDt,
                              unreadCount: combinedUnread,
                              orderId: orderId.isNotEmpty ? orderId : existing.orderId,
                              explicitRole: explicitRole.isNotEmpty ? explicitRole : existing.explicitRole,
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
                          icon: Icons.chat_bubble_outline_rounded,
                          title: "No Conversations Yet",
                          subtitle:
                              "When you send requests to brokers or communicate with assigned drivers, your chats will appear here.",
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          24,
                        ),
                        itemCount: sortedConversations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final conv = sortedConversations[index];

                          return FutureBuilder<Map<String, dynamic>>(
                            future: _getParticipantProfile(conv.otherUserId, conv.explicitRole.isNotEmpty ? conv.explicitRole : null),
                            builder: (context, profileSnap) {
                              final profile = profileSnap.data ?? {
                                'name': 'Participant',
                                'role': conv.explicitRole.isNotEmpty ? conv.explicitRole : 'Broker',
                                'avatar': null,
                                'phone': '',
                              };

                              final String displayName = profile['name'] ?? 'Participant';
                              final String role = profile['role'] ?? (conv.explicitRole.isNotEmpty ? conv.explicitRole : 'Broker');
                              final String? avatarUrl = profile['avatar'];

                              // Apply Search Query Filter
                              if (_searchQuery.isNotEmpty) {
                                final matchesName = displayName.toLowerCase().contains(_searchQuery);
                                final matchesMessage = conv.lastMessage.toLowerCase().contains(_searchQuery);
                                final matchesOrder = conv.orderId.toLowerCase().contains(_searchQuery);
                                if (!matchesName && !matchesMessage && !matchesOrder) {
                                  return const SizedBox.shrink();
                                }
                              }

                              // Apply Category Filter
                              if (_selectedFilter == "Brokers" && role.toLowerCase() != "broker") {
                                return const SizedBox.shrink();
                              }
                              if (_selectedFilter == "Drivers" && role.toLowerCase() != "driver") {
                                return const SizedBox.shrink();
                              }
                              if (_selectedFilter == "Shippers" &&
                                  role.toLowerCase() != "customer" &&
                                  role.toLowerCase() != "user" &&
                                  role.toLowerCase() != "shipper") {
                                return const SizedBox.shrink();
                              }

                              return _buildConversationTile(
                                context: context,
                                chatId: conv.canonicalChatId,
                                currentUserId: currentUserId,
                                otherUserId: conv.otherUserId,
                                name: displayName,
                                role: role,
                                avatarUrl: avatarUrl,
                                lastMessage: conv.lastMessage,
                                timestamp: conv.lastMessageTime,
                                unreadCount: conv.unreadCount,
                                orderId: conv.orderId,
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

  Widget _buildFilterPill(String filterName) {
    final bool isSelected = _selectedFilter == filterName;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFilter = filterName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Appcolors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Appcolors.primaryBlue : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Appcolors.primaryBlue.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          filterName,
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
    required String currentUserId,
    required String otherUserId,
    required String name,
    required String role,
    required String? avatarUrl,
    required String lastMessage,
    required dynamic timestamp,
    required int unreadCount,
    required String orderId,
  }) {
    final bool hasUnread = unreadCount > 0;
    final bool isDriver = role.toLowerCase() == 'driver';
    final Color roleColor = isDriver ? Appcolors.secondaryPurple : Appcolors.primaryBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        // Mark conversation unread count for current user as 0
        try {
          await _firestore.collection('chats').doc(chatId).set({
            'unreadCount_$currentUserId': 0,
          }, SetOptions(merge: true));
        } catch (_) {}

        if (!context.mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BrokerChatPage(
              chatId: chatId,
              receiverId: otherUserId,
              receiverName: name,
              brokerId: otherUserId,
              brokerName: name,
              brokerAvatar: avatarUrl,
              receiverRole: role,
              orderId: orderId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasUnread ? Colors.white : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasUnread
                ? Appcolors.primaryBlue.withOpacity(0.35)
                : Colors.grey.withOpacity(0.12),
            width: hasUnread ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: hasUnread
                  ? Appcolors.primaryBlue.withOpacity(0.06)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: roleColor.withOpacity(0.12),
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(
                          name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDriver ? Icons.local_shipping_rounded : Icons.person_rounded,
                      size: 11,
                      color: roleColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // ── Name & Last Message ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (orderId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        "Order #$orderId",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                    ),
                  Text(
                    lastMessage.isNotEmpty ? lastMessage : "Start conversation...",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                      color: hasUnread ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Timestamp & Unread Badge ────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatChatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                    color: hasUnread ? Appcolors.primaryBlue : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Appcolors.primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$unreadCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Appcolors.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Appcolors.primaryBlue, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
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

class _UserConversationItem {
  final String canonicalChatId;
  final String otherUserId;
  String lastMessage;
  dynamic lastMessageTime;
  DateTime latestDateTime;
  int unreadCount;
  String orderId;
  String explicitRole;
  String rawChatId;

  _UserConversationItem({
    required this.canonicalChatId,
    required this.otherUserId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.latestDateTime,
    required this.unreadCount,
    required this.orderId,
    required this.explicitRole,
    required this.rawChatId,
  });
}
