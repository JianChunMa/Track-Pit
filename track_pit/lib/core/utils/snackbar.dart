import 'package:flutter/material.dart';

void showClosableSnackBar(
  BuildContext context,
  String message, {
  String closeLabel = "Close",
  Duration duration = const Duration(seconds: 3),
  Color backgroundColor = Colors.black87,
  SnackBarAction? extraAction, // optional extra action
  IconData icon = Icons.info_outline, // default icon
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating, // makes it float above content
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      backgroundColor: backgroundColor,
      duration: duration,
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      action:
          extraAction ??
          SnackBarAction(
            label: closeLabel,
            textColor: Colors.white70,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
    ),
  );
}
