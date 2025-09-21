import 'package:flutter/material.dart';
import 'package:track_pit/core/constants/colors.dart';

class BookingConfirmedDialog extends StatelessWidget {
  final DateTime at;
  final VoidCallback onDetail;
  final VoidCallback? onConfirm;

  const BookingConfirmedDialog({
    super.key,
    required this.at,
    required this.onDetail,
    this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime at,
    required VoidCallback onDetail,
    VoidCallback? onConfirm,
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (_) => BookingConfirmedDialog(
            at: at,
            onDetail: onDetail,
            onConfirm: onConfirm,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final green = AppColors.primaryGreen;
    final dateStr = _fmtDate(at);
    final timeStr = _fmtTime(at);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // hard-coded asset
                Image.asset(
                  'assets/images/thumb.png', // fixed path
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'Booking Confirmed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your service has been\nsuccessfully booked',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onDetail,
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryGreen,
                      color: AppColors.primaryGreen,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _KV(label: 'Date', value: dateStr)),
                      const SizedBox(
                        height: 32,
                        child: VerticalDivider(
                          thickness: 1,
                          color: Color(0xFFD8DEE4),
                        ),
                      ),
                      Expanded(child: _KV(label: 'Time', value: timeStr)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                        onConfirm ?? () => Navigator.of(context).maybePop(),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
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
    return '${m[d.month - 1]} ${d.day}';
  }

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  const _KV({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: text.titleMedium?.copyWith(
            color: const Color(0xFF10B981),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
