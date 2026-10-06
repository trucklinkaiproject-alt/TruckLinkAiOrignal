

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Auth/Widgets/continueButton.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/brokerchatpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Widgets/shipperbottomnavbar.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqcubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqstate.dart';

class BrokerDetailPage extends StatefulWidget {
  const BrokerDetailPage({super.key, required this.brokerData});
  final Map<String, dynamic> brokerData;

  @override
  State<BrokerDetailPage> createState() => _BrokerDetailPageState();
}

class _BrokerDetailPageState extends State<BrokerDetailPage> {
  @override
  Widget build(BuildContext context) {
    final String brokerId = (widget.brokerData["uid"] ??
            widget.brokerData["brokerId"] ??
            widget.brokerData["id"] ??
            '')
        .toString();
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: brokerId.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection("Broker")
                  .doc(brokerId)
                  .snapshots()
              : const Stream.empty(),
          builder: (context, brokerSnap) {
            final liveBrokerData =
                brokerSnap.hasData && brokerSnap.data?.data() != null
                    ? brokerSnap.data!.data() as Map<String, dynamic>
                    : widget.brokerData;

            final String brokerName =
                (liveBrokerData["name"] ?? widget.brokerData["name"] ?? "Broker")
                    .toString();
            final String brokerPhone = (liveBrokerData["phone"] ??
                    widget.brokerData["phone"] ??
                    "Not specified")
                .toString();
            final String brokerEmail = (liveBrokerData["email"] ??
                    widget.brokerData["email"] ??
                    "Not specified")
                .toString();
            final String brokerLocation = (liveBrokerData["location"] ??
                    widget.brokerData["location"] ??
                    "Not specified")
                .toString();

            final double rating = (liveBrokerData["rating"] as num?)?.toDouble() ??
                (liveBrokerData["overall_rating"] as num?)?.toDouble() ??
                0.0;
            final int totalReviews =
                (liveBrokerData["total_reviews"] as num?)?.toInt() ??
                    (liveBrokerData["reviews"] as num?)?.toInt() ??
                    (liveBrokerData["review_count"] as num?)?.toInt() ??
                    0;

            final String ratingDisplay = rating > 0
                ? "$rating (${totalReviews > 0 ? totalReviews : 1} ${totalReviews == 1 ? 'review' : 'reviews'})"
                : "No reviews yet (0.0)";

            final String estimatedTimeDisplay = (liveBrokerData["estimatedTime"] != null &&
                    liveBrokerData["estimatedTime"].toString().isNotEmpty &&
                    !liveBrokerData["estimatedTime"].toString().contains("2 hours"))
                ? liveBrokerData["estimatedTime"].toString()
                : "Calculated upon trip route";

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isMobile = width < 600;
                final double horizontalPadding = isMobile ? 22 : width * 0.12;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          children: [
                            BackArrowButton(onTap: () => Navigator.pop(context)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                brokerName,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isMobile ? 22 : 28),


                        const _SectionLabel("Broker Details"),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DetailRow(
                                icon: Icons.badge_outlined,
                                label: "Broker ID",
                                value: brokerId,
                              ),
                              _DetailRow(
                                icon: Icons.location_on_outlined,
                                label: "Location",
                                value: brokerLocation,
                              ),
                              _DetailRow(
                                icon: Icons.call_outlined,
                                label: "Contact No",
                                value: brokerPhone,
                              ),
                              _DetailRow(
                                icon: Icons.email_outlined,
                                label: "Email",
                                value: brokerEmail,
                              ),
                              _DetailRow(
                                icon: Icons.star_rounded,
                                label: "Ratings",
                                value: ratingDisplay,
                              ),
                              _DetailRow(
                                icon: Icons.schedule_outlined,
                                label: "Estimated Time",
                                value: estimatedTimeDisplay,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isMobile ? 22 : 28),


                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            final String chatId =
                                getDeterministicChatId(currentUserId, brokerId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BrokerChatPage(
                                  chatId: chatId,
                                  brokerId: brokerId,
                                  brokerName: brokerName,
                                  receiverId: brokerId,
                                  receiverName: brokerName,
                                  receiverRole: 'Broker',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Appcolors.secondaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Appcolors.secondaryPurple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Chat with Broker",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "Discuss your requirements directly before or after acceptance",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Appcolors.secondaryPurple,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: isMobile ? 26 : 32),

                        BlocBuilder<CreateReqCubit, CreateReqState>(
                          builder: (context, state) {
                            final bool loading = state is CreateReqLoadingState;

                            return ContinueButton(
                              text: "Send Request",
                              clr: Appcolors.primaryBlue,
                              isLoading: loading,
                              onTap: loading
                                  ? null
                                  : () async {
                                      await context
                                          .read<CreateReqCubit>()
                                          .createRequestToBroker(
                                            brokerId,
                                          );

                                      if (!mounted) return;

                                      final cubitState = context.read<CreateReqCubit>().state;
                                      if (cubitState is CreateReqSuccessState) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Request sent to broker successfully!"),
                                            backgroundColor: Appcolors.tertiaryGreen,
                                          ),
                                        );


                                        context.read<CreateReqCubit>().resetState();


                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ShipperBottomNavBar(),
                                          ),
                                          (route) => false,
                                        );
                                      } else if (cubitState is CreateReqErrorState) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(cubitState.errorMessage),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                            );
                          },
                        ),

                        SizedBox(height: isMobile ? 26 : 32),


                        const _SectionLabel("Customer Reviews"),
                        const SizedBox(height: 10),

                        StreamBuilder<QuerySnapshot>(
                          stream: brokerId.isNotEmpty
                              ? FirebaseFirestore.instance
                                  .collection("Broker")
                                  .doc(brokerId)
                                  .collection("Reviews")
                                  .orderBy("created_at", descending: true)
                                  .snapshots()
                              : const Stream.empty(),
                          builder: (context, reviewSnap) {
                            if (reviewSnap.connectionState ==
                                    ConnectionState.waiting &&
                                !reviewSnap.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                      color: Appcolors.secondaryPurple),
                                ),
                              );
                            }

                            final docs = reviewSnap.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.rate_review_outlined,
                                      color: Colors.grey[400],
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "No customer reviews yet",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Reviews will appear here once verified completed orders are rated.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: docs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final rData =
                                    docs[index].data() as Map<String, dynamic>;
                                final rName =
                                    (rData["reviewer_name"] ?? "Verified Customer")
                                        .toString();
                                final rRating =
                                    (rData["rating"] as num?)?.toDouble() ?? 5.0;
                                final rComment =
                                    (rData["comment"] ?? "").toString();

                                return _ReviewCard(
                                  name: rName,
                                  rating: "${rRating.toStringAsFixed(1)}/5.0",
                                  review: rComment.isNotEmpty
                                      ? rComment
                                      : "Great and reliable service.",
                                );
                              },
                            );
                          },
                        ),

                        SizedBox(height: isMobile ? 20 : 30),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Appcolors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: Appcolors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$value",
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String rating;
  final String review;

  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 17),
              const SizedBox(width: 3),
              Text(
                rating,
                style: TextStyle(color: Colors.grey[600], fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
