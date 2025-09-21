import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';

class PaymentHistoryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double netTotal;
  final DateTime paidAt;
  final List<Map<String, String>> invoices;
  // each: { "title": serviceTypeName, "car": model (plate), "date": issuedAt }

  final VoidCallback onShowInvoice;

  const PaymentHistoryCard({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.netTotal,
    required this.paidAt,
    required this.invoices,
    required this.onShowInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("d MMM yyyy, h:mm a").format(paidAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.secondaryGreen, width: 1.5),
        borderRadius: BorderRadius.circular(Scale.cardBorderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.16),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment header
          Text(
            "Payment on $dateStr",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Subtotal: RM${subtotal.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "Discount: RM${discount.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "Total Paid: RM${netTotal.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const Divider(height: 20),
          const SizedBox(height: 6),
          ...invoices.map((inv) {
            final title = inv["title"] ?? "Unknown Service";
            final car = inv["car"] ?? "Unknown Car";
            final date = inv["date"] ?? "-";

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_note,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$date • $car",
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onShowInvoice,
              child: const Text(
                "Show Invoice",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
