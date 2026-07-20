import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

/// Simple model for a broker shown in the list.
/// Swap this out for your real model / cubit state whenever you wire this
/// page up to actual data — the UI below only depends on these fields.
class BrokerListItem {
  final String name;
  final String location;
  final double rating;
  final int reviewCount;
  final String estimatedTime;
  final bool isVerified;

  const BrokerListItem({
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.estimatedTime,
    this.isVerified = false,
  });
}

class BrokerListPage extends StatefulWidget {
  const BrokerListPage({super.key});

  @override
  State<BrokerListPage> createState() => _BrokerListPageState();
}

class _BrokerListPageState extends State<BrokerListPage> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedSort = 0; // 0=Top Rated, 1=Nearest, 2=Fastest

  // -------- Mock data for now — replace with real data source --------
  final List<BrokerListItem> _brokers = const [
    BrokerListItem(
      name: "Ahmed Freight Services",
      location: "Lahore, Punjab",
      rating: 4.8,
      reviewCount: 212,
      estimatedTime: "1.5 hours",
      isVerified: true,
    ),
    BrokerListItem(
      name: "Karachi Cargo Connect",
      location: "Karachi, Sindh",
      rating: 4.6,
      reviewCount: 158,
      estimatedTime: "2 hours",
      isVerified: true,
    ),
    BrokerListItem(
      name: "Speedy Logistics Co.",
      location: "Islamabad, ICT",
      rating: 4.3,
      reviewCount: 94,
      estimatedTime: "45 mins",
    ),
    BrokerListItem(
      name: "National Freight Brokers",
      location: "Faisalabad, Punjab",
      rating: 4.9,
      reviewCount: 301,
      estimatedTime: "1 hour",
      isVerified: true,
    ),
    BrokerListItem(
      name: "Sindh Transport Hub",
      location: "Hyderabad, Sindh",
      rating: 4.1,
      reviewCount: 67,
      estimatedTime: "3 hours",
    ),
    BrokerListItem(
      name: "Punjab Route Masters",
      location: "Multan, Punjab",
      rating: 4.5,
      reviewCount: 130,
      estimatedTime: "2.5 hours",
    ),
  ];

  List<BrokerListItem> get _filteredBrokers {
    final query = _searchController.text.trim().toLowerCase();

    final list = _brokers.where((b) {
      return query.isEmpty ||
          b.name.toLowerCase().contains(query) ||
          b.location.toLowerCase().contains(query);
    }).toList();

    switch (_selectedSort) {
      case 1: // Nearest — placeholder ordering (alphabetical by location)
        list.sort((a, b) => a.location.compareTo(b.location));
        break;
      case 2: // Fastest — by estimated time text length as a stand-in
        list.sort((a, b) => a.estimatedTime.compareTo(b.estimatedTime));
        break;
      default: // Top Rated
        list.sort((a, b) => b.rating.compareTo(a.rating));
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
        child: LayoutBuilder(
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
                        "${_filteredBrokers.length} brokers available near you",
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

                // -------- Broker list --------
                Expanded(
                  child: _filteredBrokers.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            24,
                          ),
                          itemCount: _filteredBrokers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _BrokerCard(
                              broker: _filteredBrokers[index],
                              onTap: () {},
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
}

// =====================================================================
// UI-only helper widgets below, matching the rest of the app's theme.
// No business logic lives here — everything is local state / mock data.
// =====================================================================

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
          color: selected
              ? Appcolors.primaryBlue.withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Appcolors.primaryBlue
                : Colors.grey.withOpacity(0.2),
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
  final BrokerListItem broker;
  final VoidCallback onTap;

  const _BrokerCard({required this.broker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = broker.name
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
            // -------- Avatar --------
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
                style: TextStyle(
                  color: Appcolors.primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // -------- Details --------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          broker.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (broker.isVerified) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Appcolors.primaryBlue,
                        ),
                      ],
                    ],
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
                          broker.location,
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
                        broker.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "(${broker.reviewCount})",
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
                        broker.estimatedTime,
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
              child: Icon(
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
              "Try a different name or location to find the right broker for your shipment.",
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