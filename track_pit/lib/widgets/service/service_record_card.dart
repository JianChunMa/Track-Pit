import 'package:flutter/material.dart';
import 'package:track_pit/core/constants/colors.dart';

class ServiceRecordCard extends StatelessWidget {
  final DateTime dateTime;
  final String title;
  final String workshop;
  final double? price;
  final VoidCallback? onDetails;

  const ServiceRecordCard({
    super.key,
    required this.dateTime,
    required this.title,
    required this.workshop,
    this.price,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    String formatTime(DateTime dt) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:$minute $period';
    }

    final d = dateTime;
    final day = d.day.toString().padLeft(2, '0');
    final mon = _month(d.month);
    final year = d.year.toString();
    final time = formatTime(d);

    const double dateColWidth = 78;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.secondaryGreen, width: 1.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: dateColWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$day $mon',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    Text(
                      year,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      workshop,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.blueGrey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              SizedBox(
                width: dateColWidth,
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Text(
                price != null ? 'RM${price!.toStringAsFixed(2)}' : 'Price TBD',
                style: TextStyle(
                  color:
                      price != null ? AppColors.primaryGreen : Colors.black54,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),

              const Spacer(),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onDetails,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Details',
                  style: TextStyle(fontWeight: FontWeight.w700, height: 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}
