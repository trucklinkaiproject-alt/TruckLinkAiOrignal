import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Widgets/backArrowButton.dart';

/// UI-only Builty (Consignment Note) page.
/// Swap the values in the constructor for your real order/broker/driver
/// data whenever this gets wired up — the layout below only depends on
/// these fields.
class BuiltyPage extends StatelessWidget {
  BuiltyPage({
    super.key,
    required this.docNo,
    required this.orderId,
    required this.date,
    required this.userName,
    required this.brokerName,
    required this.driverName,
    required this.fromLocation,
    required this.toLocation,
    required this.weight,
    required this.itemType,
    required this.transportName,
    required this.price,
    required this.quantity,
  });

  final String docNo;
  final String orderId;
  final String date;
  final String userName;
  final String brokerName;
  final int quantity;
  final String driverName;
  final String fromLocation;
  final String toLocation;
  final int weight;
  final String itemType;
  final String transportName;
  final int price;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final double horizontalPadding = isMobile ? 22 : width * 0.18;

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BackArrowButton(
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      _RoundIconButton(
                        icon: Icons.file_download_outlined,
                        onTap: () async {
                          print("PDF DOWNLOAD BUTTON PRESSED");

                          await downloadBuiltyPdf();
                        },
                        filled: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // -------- Document card --------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // -------- Title --------
                        const Text(
                          "Builty / Consignment Note",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Doc No: $docNo",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[500],
                          ),
                        ),

                        const SizedBox(height: 26),

                        // -------- Order ID / Date --------
                        _FieldRow(label: "Order ID", value: " TL - ${orderId}"),
                        const SizedBox(height: 16),
                        _FieldRow(label: "Date", value: date),

                        const SizedBox(height: 18),
                        const _Divider(),
                        const SizedBox(height: 18),

                        // -------- People involved --------
                        _FieldRow(label: "Customer", value: userName),
                        const SizedBox(height: 16),
                        _FieldRow(label: "Broker", value: brokerName),
                        const SizedBox(height: 16),
                        _FieldRow(label: "Driver", value: driverName),

                        const SizedBox(height: 18),
                        const _Divider(),
                        const SizedBox(height: 18),

                        // -------- Route --------
                        _FieldRow(label: "From", value: fromLocation),
                        const SizedBox(height: 16),
                        _FieldRow(label: "To", value: toLocation),

                        const SizedBox(height: 18),
                        const _Divider(),
                        const SizedBox(height: 18),

                        // -------- Item + Price --------
                        _FieldRow(label: "Weight", value: weight.toString()),
                        _FieldRow(
                          label: "Quantity",
                          value: quantity.toString(),
                        ),
                        const SizedBox(height: 4),
                        _FieldRow(label: "", value: itemType),
                        const SizedBox(height: 16),
                        _FieldRow(
                          label: "Price",
                          value: price.toString(),
                          highlight: true,
                        ),

                        const SizedBox(height: 18),
                        const _Divider(),
                        const SizedBox(height: 18),

                        // -------- Transport --------
                        _FieldRow(label: "Transport", value: transportName),

                        const SizedBox(height: 40),

                        // -------- Signature + Stamp --------
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomPaint(
                                    size: const Size(110, 44),
                                    painter: _SignaturePainter(),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 130,
                                    height: 1,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Authorised Signature",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StampBadge(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  pw.Widget pdfInfoCard({
    required String title,
    required String value,
    required pw.FontWeight fontWeight,
    PdfColor? valueColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            maxLines: 2,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: fontWeight,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget pdfField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),

          pw.SizedBox(width: 20),

          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget pdfSectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 16,
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(3),
          ),
        ),

        pw.SizedBox(width: 8),

        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.blue800,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Future<void> downloadBuiltyPdf() async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load('assets/Images/Trucklink AI.png');

    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),

        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              borderRadius: pw.BorderRadius.circular(16),
            ),

            child: pw.Column(
              children: [
                // =========================================================
                // HEADER
                // =========================================================
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),

                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue800,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(16),
                      topRight: pw.Radius.circular(16),
                    ),
                  ),

                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                    children: [
                      // Logo / Brand
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 55,
                            height: 55,
                            padding: const pw.EdgeInsets.all(5),

                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(10),
                            ),

                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),

                          pw.SizedBox(width: 12),

                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,

                            children: [
                              pw.Text(
                                "TRUCKLINK AI",
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),

                              pw.SizedBox(height: 3),

                              pw.Text(
                                "SMART LOGISTICS • TRUSTED DELIVERY",
                                style: const pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Document Type
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,

                        children: [
                          pw.Text(
                            "CONSIGNMENT NOTE",
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(height: 6),

                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),

                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(20),
                            ),

                            child: pw.Text(
                              "VERIFIED DOCUMENT",
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.blue800,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // =========================================================
                // DOCUMENT INFORMATION
                // =========================================================
                pw.Padding(
                  padding: const pw.EdgeInsets.all(20),

                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,

                            children: [
                              pw.Text(
                                "DOCUMENT DETAILS",
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.blue800,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),

                              pw.SizedBox(height: 5),

                              pw.Text(
                                "Official shipment record",
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                          ),

                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,

                            children: [
                              pw.Text(
                                "DOCUMENT NO.",
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                ),
                              ),

                              pw.SizedBox(height: 4),

                              pw.Text(
                                docNo,
                                style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 18),

                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pdfInfoCard(
                              title: "Order ID",
                              value: "TL - $orderId",
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(width: 12),

                          pw.Expanded(
                            child: pdfInfoCard(
                              title: "Date",
                              value: date,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 20),

                      // =====================================================
                      // PEOPLE INVOLVED
                      // =====================================================
                      pdfSectionTitle("PEOPLE INVOLVED"),

                      pw.SizedBox(height: 10),

                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pdfInfoCard(
                              title: "Customer",
                              value: userName,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(width: 10),

                          pw.Expanded(
                            child: pdfInfoCard(
                              title: "Broker",
                              value: brokerName,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(width: 10),

                          pw.Expanded(
                            child: pdfInfoCard(
                              title: "Driver",
                              value: driverName,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 20),

                      // =====================================================
                      // ROUTE
                      // =====================================================
                      pdfSectionTitle("SHIPMENT ROUTE"),

                      pw.SizedBox(height: 10),

                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),

                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: PdfColors.blue200),
                        ),

                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,

                                children: [
                                  pw.Text(
                                    "PICKUP LOCATION",
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.blue700,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),

                                  pw.SizedBox(height: 6),

                                  pw.Text(
                                    fromLocation,
                                    style: pw.TextStyle(
                                      fontSize: 13,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            pw.Container(
                              width: 55,
                              height: 1,
                              color: PdfColors.blue400,
                            ),

                            pw.Container(
                              margin: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                              ),

                              width: 28,
                              height: 28,

                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue800,
                                shape: pw.BoxShape.circle,
                              ),

                              child: pw.Center(
                                child: pw.Text(
                                  "To",
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            pw.Container(
                              width: 55,
                              height: 1,
                              color: PdfColors.blue400,
                            ),

                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,

                                children: [
                                  pw.Text(
                                    "DROP-OFF LOCATION",
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.blue700,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),

                                  pw.SizedBox(height: 6),

                                  pw.Text(
                                    toLocation,
                                    textAlign: pw.TextAlign.right,

                                    style: pw.TextStyle(
                                      fontSize: 13,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 20),

                      // =====================================================
                      // CARGO DETAILS
                      // =====================================================
                      pdfSectionTitle("CARGO DETAILS"),

                      pw.SizedBox(height: 10),

                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pdfInfoCard(
                              title: "Item Type",
                              value: itemType,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(width: 10),

                          pw.Expanded(
                            child: pdfInfoCard(
                              title: "Weight",
                              value: "$weight kg",
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(width: 10),

                          pw.Expanded(
                            child: pdfInfoCard(
                              title: "Quantity",
                              value: quantity.toString(),
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 12),

                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pdfInfoCard(
                              title: "Transport",
                              value: transportName,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(width: 10),

                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(12),

                              decoration: pw.BoxDecoration(
                                color: PdfColors.green50,
                                borderRadius: pw.BorderRadius.circular(10),
                                border: pw.Border.all(
                                  color: PdfColors.green200,
                                ),
                              ),

                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,

                                children: [
                                  pw.Text(
                                    "AGREED PRICE",
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.green800,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),

                                  pw.SizedBox(height: 6),

                                  pw.Text(
                                    "PKR $price",
                                    style: pw.TextStyle(
                                      fontSize: 16,
                                      color: PdfColors.green800,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 28),

                      // =====================================================
                      // SIGNATURE SECTION
                      // =====================================================
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                        crossAxisAlignment: pw.CrossAxisAlignment.end,

                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,

                            children: [
                              pw.Container(
                                width: 150,
                                height: 1,
                                color: PdfColors.grey500,
                              ),

                              pw.SizedBox(height: 6),

                              pw.Text(
                                "Authorised Signature",
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                          ),

                          pw.Container(
                            padding: const pw.EdgeInsets.all(10),

                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.blue700,
                                width: 2,
                              ),
                              borderRadius: pw.BorderRadius.circular(8),
                            ),

                            child: pw.Column(
                              children: [
                                pw.Text(
                                  "TRUCKLINK AI",
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.blue800,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),

                                pw.SizedBox(height: 3),

                                pw.Text(
                                  "VERIFIED",
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.blue800,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // =========================================================
                // FOOTER
                // =========================================================
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),

                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(16),
                      bottomRight: pw.Radius.circular(16),
                    ),
                  ),

                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                    children: [
                      pw.Text(
                        "Generated by TruckLink AI",
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),

                      pw.Text(
                        "Smart • Reliable • Connected",
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'TruckLink_Builty_$orderId.pdf',
    );
  }
}

// =====================================================================
// UI-only helper widgets below. No business logic lives here.
// =====================================================================

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: filled ? Appcolors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : Colors.black87,
          size: 20,
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _FieldRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: highlight ? 16 : 14,
              fontWeight: FontWeight.w800,
              color: highlight ? Appcolors.tertiaryGreen : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.grey.withOpacity(0.15));
  }
}

/// Simple squiggle painted to stand in for a hand-drawn signature.
class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(4, size.height * 0.6)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.1,
        size.width * 0.25,
        size.height * 0.9,
        size.width * 0.4,
        size.height * 0.35,
      )
      ..cubicTo(
        size.width * 0.5,
        size.height * 0.0,
        size.width * 0.55,
        size.height * 0.6,
        size.width * 0.68,
        size.height * 0.5,
      )
      ..lineTo(size.width * 0.78, size.height * 0.2)
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.7,
        size.width * 0.92,
        size.height * 0.15,
        size.width - 4,
        size.height * 0.45,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular "verified / stamped" badge, standing in for a company stamp.
class _StampBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.18,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Appcolors.primaryBlue.withOpacity(0.6),
            width: 1.6,
          ),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Appcolors.primaryBlue.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 16,
                    color: Appcolors.primaryBlue.withOpacity(0.7),
                  ),
                  Text(
                    "TRUCKLINK AI",
                    style: TextStyle(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w800,
                      color: Appcolors.primaryBlue.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "VERIFIED",
                    style: TextStyle(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w800,
                      color: Appcolors.primaryBlue.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
