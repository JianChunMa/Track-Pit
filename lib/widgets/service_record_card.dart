import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class ServiceRecordCard extends StatelessWidget {
  final DateTime dateTime;
  final String title;
  final String workshop;
  final double price;
  final VoidCallback? onDetails;

  const ServiceRecordCard({
    Key? key,
    required this.dateTime,
    required this.title,
    required this.workshop,
    required this.price,
    this.onDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final d = dateTime;
    final day = d.day.toString().padLeft(2, '0');
    final mon = _month(d.month);
    final year = d.year.toString();
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primaryGreen.withOpacity(.35), width: 1.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date block
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$day $mon', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(year, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 10),
                Text(time, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  workshop,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'RM${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onDetails,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen.withOpacity(.12),
                        foregroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _month(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[m - 1];
  }
}
