import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverRequestsBloc/brokerDriverRequestsCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverRequestsBloc/brokerDriverRequestsState.dart';

class BrokerDriverRequestsWidget extends StatelessWidget {
  const BrokerDriverRequestsWidget({super.key});

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate());
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BrokerDriverRequestsCubit, BrokerDriverRequestsState>(
      listener: (context, state) {
        if (state is BrokerDriverRequestsActionSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Appcolors.tertiaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        if (state is BrokerDriverRequestsErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is BrokerDriverRequestsLoadingState) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: Appcolors.secondaryPurple),
            ),
          );
        }

        List<Map<String, dynamic>> requests = [];
        if (state is BrokerDriverRequestsLoadedState) {
          requests = state.pendingRequests;
        }

        if (requests.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_disabled_outlined,
                    size: 38,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No Pending Join Requests",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Join requests from Drivers will appear here.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Pending Join Requests",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${requests.length}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                final String reqId = req['id'] ?? '';
                final String driverId =
                    (req['driver_id'] ?? req['driverId'] ?? reqId).toString();
                final String driverName =
                    (req['driver_name'] ?? req['name'] ?? 'Driver').toString();
                final String vehicleNumber = (req['vehicle_number'] ?? req['vehicleNumber'] ?? 'Not specified').toString();
                final String vehicleType = (req['vehicle_type'] ?? 'Not specified').toString();
                final double rating = (req['driver_rating'] as num?)?.toDouble() ?? 0.0;
                final int totalTrips = (req['total_trips'] as num?)?.toInt() ?? 0;
                final int completedTrips = (req['completed_trips'] as num?)?.toInt() ?? 0;
                final int cancelledTrips = (req['cancelled_trips'] as num?)?.toInt() ?? 0;
                final String requestStatus = (req['status'] ?? 'pending').toString();
                final String timeFormatted = _formatTimestamp(req['created_at'] ?? req['createdAt']);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Avatar, Name, Status Badge
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                Appcolors.secondaryPurple.withValues(alpha: 0.12),
                            child: Text(
                              driverName.isNotEmpty
                                  ? driverName[0].toUpperCase()
                                  : "D",
                              style: const TextStyle(
                                color: Appcolors.secondaryPurple,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Driver ID: $driverId",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Pending Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  requestStatus.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: 10),

                      // Truck Details: Type & Number
                      Row(
                        children: [
                          Icon(Icons.fire_truck_outlined, size: 15, color: Appcolors.secondaryPurple),
                          const SizedBox(width: 4),
                          Text(
                            "$vehicleType • $vehicleNumber",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Info Row: Rating & Trip Statistics
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 15, color: Colors.amber[700]),
                          const SizedBox(width: 3),
                          Text(
                            rating > 0 ? "$rating ★" : "No rating yet",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: rating > 0 ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Icon(
                            Icons.route_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Trips: $totalTrips (Done: $completedTrips, Cancel: $cancelledTrips)",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 13, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            timeFormatted,
                            style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Action Buttons: Accept & Reject
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[700],
                                side: BorderSide(
                                  color: Colors.red.withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () {
                                context.read<BrokerDriverRequestsCubit>().rejectRequest(
                                      requestId: reqId,
                                      driverId: driverId,
                                      driverName: driverName,
                                    );
                              },
                              child: const Text(
                                "Reject",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Appcolors.tertiaryGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () {
                                context.read<BrokerDriverRequestsCubit>().acceptRequest(
                                      requestId: reqId,
                                      driverId: driverId,
                                      driverName: driverName,
                                    );
                              },
                              child: const Text(
                                "Accept",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
