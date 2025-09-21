import 'package:flutter/material.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';

class ServiceInfoCard extends StatelessWidget {
  final DateTime dateTime;
  final String title;
  final String workshop;
  final String status;
  final double? top;

  const ServiceInfoCard({
    super.key,
    required this.dateTime,
    required this.title,
    required this.workshop,
    required this.status,
    this.top,
  });

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final d = dateTime;
    final day = d.day.toString().padLeft(2, '0');
    final mon = _month(d.month);
    final year = d.year.toString();
    final time = _formatTime(d);

    return Positioned(
      top: top,
      bottom: top == null ? Scale.cardTopOffset : null,
      left: Scale.cardMargin,
      right: Scale.cardMargin,
      child: Container(
        height: Scale.cardHeight + 8,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primaryAccent, width: 1.5),
          borderRadius: BorderRadius.circular(Scale.cardBorderRadius),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.12),
              blurRadius: 6,
              offset: Offset(0, 2),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$day $mon",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                Text(
                  year,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    workshop,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _capitalize(status),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _statusColor(status),
              ),
            ),
          ],
        ),
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

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return AppColors.primaryGreen;
      case 'completed':
        return Colors.grey;
      case 'upcoming':
        return Colors.blueAccent;
      default:
        return Colors.black54;
    }
  }
}
