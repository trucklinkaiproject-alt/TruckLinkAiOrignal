import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OfferCard extends StatefulWidget {
  final String brokerName;
  final String fare;
  final String eta;
  final double rating;
  final String? brokerPhone;
  final String? successRate;
  final String? brokerId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const OfferCard({
    super.key,
    required this.brokerName,
    required this.fare,
    required this.eta,
    required this.rating,
    this.brokerPhone,
    this.successRate,
    this.brokerId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  String? _phone;
  String? _successRate;
  String? _realName;
  double? _realRating;
  int _realReviewCount = 0;
  List<Map<String, dynamic>> _brokerReviews = [];

  @override
  void initState() {
    super.initState();
    _phone = widget.brokerPhone;
    _successRate = widget.successRate;
    _realName = widget.brokerName;
    _realRating = widget.rating > 0 ? widget.rating : null;

    if (widget.brokerId != null && widget.brokerId!.isNotEmpty) {
      _fetchBrokerProfile();
    }
  }

  Future<void> _fetchBrokerProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection("Broker").doc(widget.brokerId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _realName = data['name'] ?? data['broker_name'] ?? _realName;
            _phone = data['phone'] ?? data['phone_number'] ?? _phone;
            _realRating = (data['rating'] as num?)?.toDouble() ?? (data['overall_rating'] as num?)?.toDouble() ?? _realRating ?? 4.8;
            _realReviewCount = (data['review_count'] as num?)?.toInt() ?? (data['total_reviews'] as num?)?.toInt() ?? 0;
            final completionRate = data['completion_rate'] ?? data['success_rate'];
            if (completionRate != null) {
              _successRate = "$completionRate%";
            } else {
              _successRate = "96% Completion Rate";
            }
          });
        }
      }

      // Also check for actual reviews
      try {
        final revSnap = await FirebaseFirestore.instance
            .collection("Broker")
            .doc(widget.brokerId)
            .collection("Reviews")
            .limit(5)
            .get();
        if (revSnap.docs.isNotEmpty && mounted) {
          setState(() {
            _brokerReviews = revSnap.docs.map((d) => d.data()).toList();
            if (_realReviewCount == 0) _realReviewCount = revSnap.docs.length;
          });
        }
      } catch (_) {}
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = (_realName != null && _realName!.isNotEmpty && _realName != widget.brokerId)
        ? _realName!
        : widget.brokerName;
    final String displayPhone = _phone ?? "Phone N/A";
    final String displaySuccess = _successRate ?? "96% Completion Rate";
    final double displayRating = _realRating ?? widget.rating;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Phone: $displayPhone",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber.shade600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    displayRating > 0 ? displayRating.toStringAsFixed(1) : "New",
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (_realReviewCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      "($_realReviewCount rev)",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      displaySuccess,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Fare Offer",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Rs. ${widget.fare}",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Colors.blue.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Estimated Arrival",
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                            ),
                          ),
                          Text(
                            widget.eta,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red.shade300),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Reject",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Accept Offer",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 15),
//       elevation: 8,
//       shadowColor: Colors.black26,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(22),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           children: [

//             Row(
//               children: [

//                 CircleAvatar(
//                   radius: 28,
//                   backgroundColor: Colors.blue.shade100,
//                   child: const Icon(
//                     Icons.local_shipping,
//                     color: Colors.blue,
//                     size: 30,
//                   ),
//                 ),

//                 const SizedBox(width: 15),

//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [

//                       Text(
//                         brokerName,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),

//                       const SizedBox(height: 5),

//                       Row(
//                         children: [

//                           const Icon(
//                             Icons.star,
//                             size: 18,
//                             color: Colors.amber,
//                           ),

//                           const SizedBox(width: 4),

//                           Text(
//                             rating.toString(),
//                           ),
//                         ],
//                       )
//                     ],
//                   ),
//                 ),

//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 10,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.green.shade50,
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Text(
//                     "PKR $fare",
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
//                       fontSize: 18,
//                     ),
//                   ),
//                 )
//               ],
//             ),

//             const SizedBox(height: 20),

//             Row(
//               children: [

//                 const Icon(Icons.timer),

//                 const SizedBox(width: 8),

//                 Text("ETA : $eta"),
//               ],
//             ),

//             const SizedBox(height: 20),

//             Row(
//               children: [

//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: onReject,
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size.fromHeight(48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     child: const Text("Reject"),
//                   ),
//                 ),

//                 const SizedBox(width: 12),

//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: onAccept,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       minimumSize: const Size.fromHeight(48),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     child: const Text(
//                       "Accept",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 )
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';

// class OfferCard extends StatelessWidget {
//   final String brokerName;
//   final String fare;
//   final String eta;
//   final double rating;
//   final VoidCallback onAccept;
//   final VoidCallback onReject;

//   const OfferCard({
//     super.key,
//     required this.brokerName,
//     required this.fare,
//     required this.eta,
//     required this.rating,
//     required this.onAccept,
//     required this.onReject,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 4,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
//               child: Column(
//                 children: [
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         width: 52,
//                         height: 52,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               Colors.blue.shade400,
//                               Colors.blue.shade700,
//                             ],
//                           ),
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.blue.withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.local_shipping_rounded,
//                           color: Colors.white,
//                           size: 26,
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               brokerName,
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 1,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 16.5,
//                                 color: Colors.black87,
//                                 letterSpacing: -0.2,
//                               ),
//                             ),
//                             const SizedBox(height: 6),
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                     vertical: 3,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.amber.withOpacity(0.12),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Icon(
//                                         Icons.star_rounded,
//                                         size: 15,
//                                         color: Colors.amber.shade700,
//                                       ),
//                                       const SizedBox(width: 3),
//                                       Text(
//                                         rating.toStringAsFixed(1),
//                                         style: TextStyle(
//                                           fontSize: 12.5,
//                                           fontWeight: FontWeight.w700,
//                                           color: Colors.amber.shade800,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 10,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.green.shade50,
//                           borderRadius: BorderRadius.circular(14),
//                           border: Border.all(
//                             color: Colors.green.shade100,
//                             width: 1,
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               "PKR",
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.green.shade600,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                             Text(
//                               fare,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w800,
//                                 color: Colors.green.shade700,
//                                 fontSize: 17,
//                                 letterSpacing: -0.3,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF7F8FA),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.timer_outlined,
//                           size: 18,
//                           color: Colors.grey.shade600,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           "Estimated arrival",
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Colors.grey.shade600,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const Spacer(),
//                         Text(
//                           eta,
//                           style: const TextStyle(
//                             fontSize: 13.5,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: onReject,
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.grey.shade700,
//                         side: BorderSide(color: Colors.grey.shade300, width: 1.4),
//                         minimumSize: const Size.fromHeight(48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: const Text(
//                         "Reject",
//                         style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     flex: 2,
//                     child: Container(
//                       height: 48,
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.green.shade500, Colors.green.shade700],
//                         ),
//                         borderRadius: BorderRadius.circular(14),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.green.withOpacity(0.3),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(14),
//                           onTap: onAccept,
//                           child: const Center(
//                             child: Text(
//                               "Accept Offer",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 14.5,
//                                 letterSpacing: 0.2,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
