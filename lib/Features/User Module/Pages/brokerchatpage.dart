import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/appBar.dart';

class BrokerChatPage extends StatefulWidget {
  const BrokerChatPage({super.key});

  @override
  State<BrokerChatPage> createState() => _BrokerChatPageState();
}

class _BrokerChatPageState extends State<BrokerChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          color:Appcolors.background,
          child: Column(
            
            children: [
              AppBarContainer(title: "Chat with Broker"),

            ],
          ),
        ),
      ),
    );
  }
}

// // ─────────────────────────────────────────────────────────────────────────────
// // broker_chat_page.dart
// //
// // Drop-in Flutter chat page: User ↔ Broker
// // Stack: Firebase Firestore + Cubit (no architecture layer)
// //
// // HOW TO INTEGRATE:
// //   1. Add dependencies in pubspec.yaml:
// //        flutter_bloc: ^8.1.5
// //        cloud_firestore: ^5.x.x
// //        firebase_auth: ^5.x.x
// //        intl: ^0.19.0
// //
// //   2. Firestore collection structure:
// //        /chats/{chatId}/messages/{messageId}
// //          - senderId   : String
// //          - text       : String
// //          - timestamp  : Timestamp
// //          - isRead     : bool
// //
// //   3. Navigate to this page:
// //        Navigator.push(context, MaterialPageRoute(
// //          builder: (_) => BrokerChatPage(
// //            chatId: 'your_chat_id',
// //            brokerId: 'broker_uid',
// //            brokerName: 'John Smith',
// //            brokerAvatar: 'https://...', // optional
// //          ),
// //        ));
// // ─────────────────────────────────────────────────────────────────────────────

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';

// // ══════════════════════════════════════════════════════════════════════════════
// // MODEL
// // ══════════════════════════════════════════════════════════════════════════════

// class ChatMessage {
//   final String id;
//   final String senderId;
//   final String text;
//   final DateTime timestamp;
//   final bool isRead;

//   const ChatMessage({
//     required this.id,
//     required this.senderId,
//     required this.text,
//     required this.timestamp,
//     required this.isRead,
//   });

//   factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return ChatMessage(
//       id: doc.id,
//       senderId: data['senderId'] as String,
//       text: data['text'] as String,
//       timestamp: (data['timestamp'] as Timestamp).toDate(),
//       isRead: data['isRead'] as bool? ?? false,
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // STATE
// // ══════════════════════════════════════════════════════════════════════════════

// abstract class ChatState {}

// class ChatInitial extends ChatState {}

// class ChatLoading extends ChatState {}

// class ChatLoaded extends ChatState {
//   final List<ChatMessage> messages;
//   final bool isSending;
//   final bool brokerOnline;

//   ChatLoaded({
//     required this.messages,
//     this.isSending = false,
//     this.brokerOnline = false,
//   });

//   ChatLoaded copyWith({
//     List<ChatMessage>? messages,
//     bool? isSending,
//     bool? brokerOnline,
//   }) =>
//       ChatLoaded(
//         messages: messages ?? this.messages,
//         isSending: isSending ?? this.isSending,
//         brokerOnline: brokerOnline ?? this.brokerOnline,
//       );
// }

// class ChatError extends ChatState {
//   final String message;
//   ChatError(this.message);
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // CUBIT
// // ══════════════════════════════════════════════════════════════════════════════

// class ChatCubit extends Cubit<ChatState> {
//   final String chatId;
//   final String brokerId;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   StreamSubscription<QuerySnapshot>? _messagesSubscription;

//   ChatCubit({required this.chatId, required this.brokerId})
//       : super(ChatInitial());

//   String get currentUserId => _auth.currentUser?.uid ?? '';

//   /// Call once when the page opens.
//   void initialize() {
//     emit(ChatLoading());

//     _messagesSubscription = _firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .orderBy('timestamp', descending: false)
//         .snapshots()
//         .listen(
//           (snapshot) {
//             final messages =
//                 snapshot.docs.map(ChatMessage.fromFirestore).toList();

//             final current = state;
//             emit(ChatLoaded(
//               messages: messages,
//               isSending:
//                   current is ChatLoaded ? current.isSending : false,
//               brokerOnline:
//                   current is ChatLoaded ? current.brokerOnline : false,
//             ));

//             _markMessagesAsRead(snapshot.docs);
//           },
//           onError: (e) => emit(ChatError('Failed to load messages: $e')),
//         );
//   }

//   Future<void> sendMessage(String text) async {
//     final trimmed = text.trim();
//     if (trimmed.isEmpty) return;

//     final current = state;
//     if (current is ChatLoaded) {
//       emit(current.copyWith(isSending: true));
//     }

//     try {
//       await _firestore
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages')
//           .add({
//         'senderId': currentUserId,
//         'text': trimmed,
//         'timestamp': FieldValue.serverTimestamp(),
//         'isRead': false,
//       });

//       // Update last-message summary on the parent chat doc (optional).
//       await _firestore.collection('chats').doc(chatId).set({
//         'lastMessage': trimmed,
//         'lastMessageTime': FieldValue.serverTimestamp(),
//         'participants': [currentUserId, brokerId],
//       }, SetOptions(merge: true));
//     } catch (e) {
//       // Don't crash the page on a failed send; surface it gently.
//       emit(ChatError('Message not sent. Please try again.'));
//       // Re-emit loaded state after showing error briefly.
//       await Future.delayed(const Duration(seconds: 2));
//       if (current is ChatLoaded) emit(current.copyWith(isSending: false));
//     } finally {
//       final c = state;
//       if (c is ChatLoaded) emit(c.copyWith(isSending: false));
//     }
//   }

//   Future<void> _markMessagesAsRead(List<QueryDocumentSnapshot> docs) async {
//     final batch = _firestore.batch();
//     for (final doc in docs) {
//       final data = doc.data() as Map<String, dynamic>;
//       if (data['senderId'] != currentUserId &&
//           !(data['isRead'] as bool? ?? false)) {
//         batch.update(doc.reference, {'isRead': true});
//       }
//     }
//     await batch.commit();
//   }

//   @override
//   Future<void> close() {
//     _messagesSubscription?.cancel();
//     return super.close();
//   }
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // PAGE
// // ══════════════════════════════════════════════════════════════════════════════

// class BrokerChatPage extends StatelessWidget {
//   final String chatId;
//   final String brokerId;
//   final String brokerName;
//   final String? brokerAvatar;

//   const BrokerChatPage({
//     super.key,
//     required this.chatId,
//     required this.brokerId,
//     required this.brokerName,
//     this.brokerAvatar,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) =>
//           ChatCubit(chatId: chatId, brokerId: brokerId)..initialize(),
//       child: _ChatView(
//         brokerName: brokerName,
//         brokerAvatar: brokerAvatar,
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // INTERNAL VIEW
// // ══════════════════════════════════════════════════════════════════════════════

// class _ChatView extends StatefulWidget {
//   final String brokerName;
//   final String? brokerAvatar;

//   const _ChatView({required this.brokerName, this.brokerAvatar});

//   @override
//   State<_ChatView> createState() => _ChatViewState();
// }

// class _ChatViewState extends State<_ChatView> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _canSend = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller.addListener(() {
//       final canSend = _controller.text.trim().isNotEmpty;
//       if (canSend != _canSend) setState(() => _canSend = canSend);
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   void _handleSend() {
//     final text = _controller.text;
//     if (text.trim().isEmpty) return;
//     context.read<ChatCubit>().sendMessage(text);
//     _controller.clear();
//     _scrollToBottom();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F6FA),
//       appBar: _BrokerAppBar(
//         brokerName: widget.brokerName,
//         brokerAvatar: widget.brokerAvatar,
//       ),
//       body: Column(
//         children: [
//           // ── Message list ──────────────────────────────────────────
//           Expanded(
//             child: BlocConsumer<ChatCubit, ChatState>(
//               listener: (context, state) {
//                 if (state is ChatLoaded) _scrollToBottom();
//                 if (state is ChatError) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(state.message),
//                       backgroundColor: colorScheme.error,
//                       behavior: SnackBarBehavior.floating,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10)),
//                     ),
//                   );
//                 }
//               },
//               builder: (context, state) {
//                 if (state is ChatLoading) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (state is ChatLoaded) {
//                   if (state.messages.isEmpty) {
//                     return _EmptyChat(brokerName: widget.brokerName);
//                   }
//                   return _MessageList(
//                     messages: state.messages,
//                     currentUserId:
//                         context.read<ChatCubit>().currentUserId,
//                     scrollController: _scrollController,
//                   );
//                 }
//                 // ChatError handled via listener; show placeholder.
//                 return const SizedBox.shrink();
//               },
//             ),
//           ),

//           // ── Input bar ─────────────────────────────────────────────
//           _InputBar(
//             controller: _controller,
//             canSend: _canSend,
//             onSend: _handleSend,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // APP BAR
// // ══════════════════════════════════════════════════════════════════════════════

// class _BrokerAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final String brokerName;
//   final String? brokerAvatar;

//   const _BrokerAppBar({required this.brokerName, this.brokerAvatar});

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.white,
//       elevation: 0,
//       shadowColor: Colors.transparent,
//       surfaceTintColor: Colors.transparent,
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Divider(height: 1, color: Colors.grey.shade200),
//       ),
//       leadingWidth: 40,
//       leading: const BackButton(color: Color(0xFF1A1A2E)),
//       title: Row(
//         children: [
//           _BrokerAvatar(avatarUrl: brokerAvatar, name: brokerName, radius: 18),
//           const SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 brokerName,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1A1A2E),
//                   letterSpacing: -0.3,
//                 ),
//               ),
//               const Text(
//                 'Broker',
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Color(0xFF6B7280),
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.phone_outlined, color: Color(0xFF4F46E5)),
//           tooltip: 'Call broker',
//           onPressed: () {
//             // TODO: integrate your calling logic
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
//           tooltip: 'More options',
//           onPressed: () {
//             // TODO: show bottom sheet with options
//           },
//         ),
//       ],
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // MESSAGE LIST
// // ══════════════════════════════════════════════════════════════════════════════

// class _MessageList extends StatelessWidget {
//   final List<ChatMessage> messages;
//   final String currentUserId;
//   final ScrollController scrollController;

//   const _MessageList({
//     required this.messages,
//     required this.currentUserId,
//     required this.scrollController,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       controller: scrollController,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       itemCount: messages.length,
//       itemBuilder: (context, index) {
//         final message = messages[index];
//         final isMe = message.senderId == currentUserId;

//         // Show a date divider when the date changes.
//         final showDivider = index == 0 ||
//             !_isSameDay(messages[index - 1].timestamp, message.timestamp);

//         return Column(
//           children: [
//             if (showDivider) _DateDivider(date: message.timestamp),
//             _MessageBubble(message: message, isMe: isMe),
//           ],
//         );
//       },
//     );
//   }

//   bool _isSameDay(DateTime a, DateTime b) =>
//       a.year == b.year && a.month == b.month && a.day == b.day;
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // MESSAGE BUBBLE
// // ══════════════════════════════════════════════════════════════════════════════

// class _MessageBubble extends StatelessWidget {
//   final ChatMessage message;
//   final bool isMe;

//   const _MessageBubble({required this.message, required this.isMe});

//   @override
//   Widget build(BuildContext context) {
//     const myColor = Color(0xFF4F46E5);   // indigo
//     const theirColor = Colors.white;

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.72,
//         ),
//         decoration: BoxDecoration(
//           color: isMe ? myColor : theirColor,
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(18),
//             topRight: const Radius.circular(18),
//             bottomLeft: Radius.circular(isMe ? 18 : 4),
//             bottomRight: Radius.circular(isMe ? 4 : 18),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.06),
//               blurRadius: 6,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         child: Column(
//           crossAxisAlignment:
//               isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//           children: [
//             Text(
//               message.text,
//               style: TextStyle(
//                 fontSize: 14.5,
//                 color: isMe ? Colors.white : const Color(0xFF1A1A2E),
//                 height: 1.4,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   DateFormat('h:mm a').format(message.timestamp),
//                   style: TextStyle(
//                     fontSize: 10.5,
//                     color: isMe
//                         ? Colors.white.withOpacity(0.65)
//                         : const Color(0xFF9CA3AF),
//                   ),
//                 ),
//                 if (isMe) ...[
//                   const SizedBox(width: 4),
//                   Icon(
//                     message.isRead ? Icons.done_all : Icons.done,
//                     size: 13,
//                     color: message.isRead
//                         ? Colors.lightBlueAccent
//                         : Colors.white.withOpacity(0.65),
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // DATE DIVIDER
// // ══════════════════════════════════════════════════════════════════════════════

// class _DateDivider extends StatelessWidget {
//   final DateTime date;
//   const _DateDivider({required this.date});

//   String _label() {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final d = DateTime(date.year, date.month, date.day);
//     if (d == today) return 'Today';
//     if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
//     return DateFormat('MMM d, yyyy').format(date);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         children: [
//           const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Text(
//               _label(),
//               style: const TextStyle(
//                 fontSize: 11.5,
//                 color: Color(0xFF9CA3AF),
//                 fontWeight: FontWeight.w500,
//                 letterSpacing: 0.3,
//               ),
//             ),
//           ),
//           const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
//         ],
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // EMPTY STATE
// // ══════════════════════════════════════════════════════════════════════════════

// class _EmptyChat extends StatelessWidget {
//   final String brokerName;
//   const _EmptyChat({required this.brokerName});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF4F46E5).withOpacity(0.08),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.chat_bubble_outline_rounded,
//                 size: 40,
//                 color: Color(0xFF4F46E5),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Start the conversation',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1A1A2E),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Send a message to $brokerName and get the\npersonalized advice you need.',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 13.5,
//                 color: Color(0xFF6B7280),
//                 height: 1.5,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // INPUT BAR
// // ══════════════════════════════════════════════════════════════════════════════

// class _InputBar extends StatelessWidget {
//   final TextEditingController controller;
//   final bool canSend;
//   final VoidCallback onSend;

//   const _InputBar({
//     required this.controller,
//     required this.canSend,
//     required this.onSend,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ChatCubit, ChatState>(
//       builder: (context, state) {
//         final sending = state is ChatLoaded && state.isSending;

//         return Container(
//           color: Colors.white,
//           padding: EdgeInsets.fromLTRB(
//             12,
//             10,
//             12,
//             10 + MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: SafeArea(
//             top: false,
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 // Attachment button
//                 IconButton(
//                   icon: const Icon(Icons.attach_file_rounded,
//                       color: Color(0xFF9CA3AF)),
//                   onPressed: () {
//                     // TODO: handle file/image attachment
//                   },
//                   tooltip: 'Attach file',
//                 ),

//                 // Text field
//                 Expanded(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF5F6FA),
//                       borderRadius: BorderRadius.circular(24),
//                       border: Border.all(color: const Color(0xFFE5E7EB)),
//                     ),
//                     child: TextField(
//                       controller: controller,
//                       minLines: 1,
//                       maxLines: 5,
//                       textCapitalization: TextCapitalization.sentences,
//                       style: const TextStyle(
//                         fontSize: 14.5,
//                         color: Color(0xFF1A1A2E),
//                       ),
//                       decoration: const InputDecoration(
//                         hintText: 'Type a message…',
//                         hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
//                         contentPadding:
//                             EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                         border: InputBorder.none,
//                       ),
//                       onSubmitted: (_) => onSend(),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(width: 8),

//                 // Send button
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     color: canSend
//                         ? const Color(0xFF4F46E5)
//                         : const Color(0xFFE5E7EB),
//                     shape: BoxShape.circle,
//                   ),
//                   child: sending
//                       ? const Padding(
//                           padding: EdgeInsets.all(10),
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : IconButton(
//                           padding: EdgeInsets.zero,
//                           icon: Icon(
//                             Icons.send_rounded,
//                             size: 20,
//                             color:
//                                 canSend ? Colors.white : const Color(0xFF9CA3AF),
//                           ),
//                           onPressed: canSend ? onSend : null,
//                           tooltip: 'Send',
//                         ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // ══════════════════════════════════════════════════════════════════════════════
// // BROKER AVATAR WIDGET (reusable)
// // ══════════════════════════════════════════════════════════════════════════════

// class _BrokerAvatar extends StatelessWidget {
//   final String? avatarUrl;
//   final String name;
//   final double radius;

//   const _BrokerAvatar(
//       {required this.name, this.avatarUrl, this.radius = 20});

//   @override
//   Widget build(BuildContext context) {
//     if (avatarUrl != null && avatarUrl!.isNotEmpty) {
//       return CircleAvatar(
//         radius: radius,
//         backgroundImage: NetworkImage(avatarUrl!),
//         backgroundColor: const Color(0xFFE0E7FF),
//       );
//     }
//     // Initials fallback
//     final initials = name.trim().split(' ').take(2).map((w) => w[0]).join();
//     return CircleAvatar(
//       radius: radius,
//       backgroundColor: const Color(0xFFE0E7FF),
//       child: Text(
//         initials.toUpperCase(),
//         style: const TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w700,
//           color: Color(0xFF4F46E5),
//         ),
//       ),
//     );
//   }
// }
