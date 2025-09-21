import 'package:flutter/material.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';

class InvoiceSummaryCard extends StatelessWidget {
  final int invoicesSelected;
  final int vehiclesInvolved;
  final int servicesIncluded;
  final double total;
  final double? top;

  final VoidCallback? onCheckout;

  const InvoiceSummaryCard({
    super.key,
    required this.invoicesSelected,
    required this.vehiclesInvolved,
    required this.servicesIncluded,
    required this.total,
    this.top,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: top == null ? Scale.cardTopOffset : null,
      left: Scale.cardMargin,
      right: Scale.cardMargin,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primaryAccent, width: 2),
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
            const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  "Summary",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildRow("Invoices Selected", invoicesSelected.toString()),
            _buildRow("Vehicles Involved", vehiclesInvolved.toString()),
            _buildRow("Services Included (types)", servicesIncluded.toString()),
            const Divider(),
            _buildRow("Total", "RM${total.toStringAsFixed(2)}", isBold: true),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: invoicesSelected > 0 ? onCheckout : null,
                child: const Text(
                  "Checkout",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String left, String right, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: const TextStyle(height: 1.15, fontWeight: FontWeight.w500),
          ),
          Text(
            right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
