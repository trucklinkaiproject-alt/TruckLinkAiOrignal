import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerQuoteBloc/brokerQuoteCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerQuoteBloc/brokerQuoteStates.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderReqData;

  const OrderDetailsPage({super.key, required this.orderReqData});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final TextEditingController quoteController = TextEditingController();

  @override
  void dispose() {
    quoteController.dispose();
    super.dispose();
  }

  void submitQuote() {
    final quote = quoteController.text.trim();

    if (quote.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your quote.")));
      return;
    }

    final amount = double.tryParse(quote);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid amount.")));
      return;
    }

    context.read<BrokerQuoteCubit>().submitQuote(
      userUid: widget.orderReqData["userUid"],
      orderId: widget.orderReqData["orderId"],
      brokerId: widget.orderReqData["brokerId"],
      amount: amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderReqData;

    final requestId = "Order No # " + data["orderNo"];

    final createdAt = data["createdAt"] ?? "Time not available";

    final customerName = data["userUid"] ?? "userId not available";
    final phone = data["phone"] ?? "Phone not available";

    final pickup = data["pickupCity"] ?? "Pickup city not available";
    final drop = data["dropCity"] ?? "Drop city not available";

    final itemType = data["itemType"] ?? "Unknown";
    final weight = data["weight"] ?? "0";
    final quantity = data["quantity"] ?? "0";
    final description = data["additionalInfo"] ?? "No description available.";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final double horizontalPadding = isMobile ? 22 : width * 0.12;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- Header --------
                  Row(
                    children: [
                      BackArrowButton(onTap: () => Navigator.pop(context)),
                      const Spacer(),
                      const Text(
                        "Request Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {},
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
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isMobile ? 24 : 30),

                  // -------- Order # + time --------
                  Text(
                    requestId,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    createdAt.toString(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12.5),
                  ),

                  SizedBox(height: isMobile ? 24 : 30),

                  // -------- Customer Information --------
                  const _SectionLabel("Customer Information"),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.person_pin_circle_outlined,
                    iconColor: Appcolors.primaryBlue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 22 : 26),

                  // -------- Route --------
                  const _SectionLabel("Route"),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.location_on_outlined,
                    iconColor: Appcolors.secondaryPurple,
                    child: Text(
                      "$pickup  ➜  $drop",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 22 : 26),

                  // -------- Item Details --------
                  const _SectionLabel("Item Details"),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.inventory_2_outlined,
                    iconColor: Appcolors.tertiaryGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemType,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Weight: $weight kg",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          "Quantity: $quantity",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[500],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 30 : 36),

                  // -------- Quote input (same controller) --------
                  const _SectionLabel("Your Quote (PKR)"),
                  const SizedBox(height: 10),
                  TextField(
                    controller: quoteController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter Your Quote",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Appcolors.secondaryPurple,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 26 : 32),

                  // -------- Submit (same listener/cubit logic) --------
                  BlocListener<BrokerQuoteCubit, BrokerQuoteState>(
                    listener: (context, state) {
                      if (state is BrokerQuoteSuccess) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Quote Submitted: PKR ${state.amount.toStringAsFixed(0)}",
                            ),
                          ),
                        );
                      } else if (state is BrokerQuoteError) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(state.error)));
                      }
                    },
                    child: BlocBuilder<BrokerQuoteCubit, BrokerQuoteState>(
                      builder: (context, state) {
                        final bool loading = state is BrokerQuoteLoading;

                        return SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appcolors.secondaryPurple,
                              disabledBackgroundColor: Appcolors.secondaryPurple
                                  .withOpacity(0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: loading ? null : submitQuote,
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Submit Quote",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: isMobile ? 15 : 20),
                ],
              ),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.child,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}
