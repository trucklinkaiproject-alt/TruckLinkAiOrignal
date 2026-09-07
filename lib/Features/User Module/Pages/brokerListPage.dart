import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/User Module/Pages/brokerDetailpage.dart';

class BrokerListPage extends StatefulWidget {
  final String? requiredVehicleType;
  const BrokerListPage({super.key, this.requiredVehicleType});

  @override
  State<BrokerListPage> createState() => _BrokerListPageState();
}

class _BrokerListPageState extends State<BrokerListPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSort = 0; // 0=Top Rated, 1=Nearest, 2=Fastest

  List<Map<String, dynamic>> _filterAndSortBrokers(List<Map<String, dynamic>> rawBrokers) {
    final query = _searchController.text.trim().toLowerCase();

    final list = rawBrokers.where((b) {
      final name = (b['name'] ?? b['broker_name'] ?? '').toString().toLowerCase();
      final location = (b['location'] ?? b['address'] ?? b['city'] ?? '').toString().toLowerCase();
      return query.isEmpty || name.contains(query) || location.contains(query);
    }).toList();

    switch (_selectedSort) {
      case 1: // Location/Nearest
        list.sort((a, b) {
          final locA = (a['location'] ?? a['address'] ?? '').toString();
          final locB = (b['location'] ?? b['address'] ?? '').toString();
          return locA.compareTo(locB);
        });
        break;
      case 2: // Fastest / Active
        list.sort((a, b) {
          final timeA = (a['estimatedTime'] ?? '0').toString();
          final timeB = (b['estimatedTime'] ?? '0').toString();
          return timeA.compareTo(timeB);
        });
        break;
      default: // Top Rated
        list.sort((a, b) {
          final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
          final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
    }

    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("Broker").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Appcolors.primaryBlue));
            }

            final docs = snapshot.data?.docs ?? [];
            final List<Map<String, dynamic>> rawBrokers = docs.map((doc) {
              return {
                'id': doc.id,
                'brokerId': doc.id,
                'uid': doc.id,
                ...doc.data() as Map<String, dynamic>,
              };
            }).toList();

            final filteredBrokers = _filterAndSortBrokers(rawBrokers);

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isMobile = width < 600;
                final double horizontalPadding = isMobile ? 22 : width * 0.12;

                return Column(
                  children: [
                    // -------- Header --------
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        15,
                        horizontalPadding,
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _BackButton(onTap: () => Navigator.pop(context)),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  "Find a Broker",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${filteredBrokers.length} real-time brokers available",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // -------- Search --------
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: _SearchField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // -------- Sort chips --------
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        children: [
                          _FilterChip(
                            label: "Top Rated",
                            icon: Icons.star_rounded,
                            selected: _selectedSort == 0,
                            onTap: () => setState(() => _selectedSort = 0),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: "Nearest",
                            icon: Icons.near_me_rounded,
                            selected: _selectedSort == 1,
                            onTap: () => setState(() => _selectedSort = 1),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: "Fastest",
                            icon: Icons.bolt_rounded,
                            selected: _selectedSort == 2,
                            onTap: () => setState(() => _selectedSort = 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // -------- Real-Time Broker list --------
                    Expanded(
                      child: filteredBrokers.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                8,
                                horizontalPadding,
                                24,
                              ),
                              itemCount: filteredBrokers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final brokerData = filteredBrokers[index];
                                return _BrokerCard(
                                  brokerData: brokerData,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BrokerDetailPage(brokerData: brokerData),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        hintText: "Search by broker name or location",
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: Colors.grey[400], size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged("");
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Appcolors.primaryBlue, width: 1.6),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Appcolors.primaryBlue.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Appcolors.primaryBlue : Colors.grey.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Appcolors.primaryBlue : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Appcolors.primaryBlue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokerCard extends StatelessWidget {
  final Map<String, dynamic> brokerData;
  final VoidCallback onTap;

  const _BrokerCard({required this.brokerData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String name = (brokerData['name'] ?? brokerData['broker_name'] ?? 'Broker').toString();
    final String location = (brokerData['location'] ?? brokerData['address'] ?? brokerData['city'] ?? 'Location not specified').toString();
    final String brokerId = (brokerData['brokerId'] ?? brokerData['id'] ?? '').toString();
    final double rating = (brokerData['rating'] as num?)?.toDouble() ?? 4.8;
    final int reviews = (brokerData['reviews'] as num?)?.toInt() ?? 120;
    final bool isVerified = brokerData['isVerified'] ?? true;
    final String estimatedTime = (brokerData['estimatedTime'] ?? 'Available now').toString();

    final initials = name
        .trim()
        .split(RegExp(r"\s+"))
        .map((e) => e.isNotEmpty ? e[0] : "")
        .take(2)
        .join()
        .toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Appcolors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Appcolors.primaryBlue,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Appcolors.primaryBlue,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Broker ID: $brokerId",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "($reviews)",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.schedule_outlined,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        estimatedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Appcolors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: Appcolors.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No brokers found",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "No active brokers match your search criteria. Check back soon!",
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