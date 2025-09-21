import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';

class InvoiceCard extends StatelessWidget {
  final String id;
  final DateTime date;
  final String title;
  final String car;
  final String location;
  final double price;
  final bool isSelected;

  final ValueChanged<String> onToggle;
  final VoidCallback onShowInvoice;

  const InvoiceCard({
    super.key,
    required this.id,
    required this.date,
    required this.title,
    required this.car,
    required this.location,
    required this.price,
    required this.isSelected,
    required this.onToggle,
    required this.onShowInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat("d MMM yyyy").format(date);

    return GestureDetector(
      onTap: () => onToggle(id), // tapping anywhere toggles
      child: Container(
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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Symbols.today,
                      size: 20,
                      color: AppColors.primaryGreen,
                      weight: 900,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Invoice ID: $id",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  car,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  location,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "RM${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    ElevatedButton(
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
                  ],
                ),
              ],
            ),

            // Bigger checkbox
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 24, // bigger size
                height: 24,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
