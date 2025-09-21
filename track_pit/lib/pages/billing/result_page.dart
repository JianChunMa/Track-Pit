import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final bool isSuccess;
  final double amount;

  const ResultPage({super.key, required this.isSuccess, required this.amount});

  @override
  Widget build(BuildContext context) {
    final Color color = isSuccess ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Result"),
        backgroundColor: color,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 80,
              color: color,
            ),
            const SizedBox(height: 20),
            Text(
              isSuccess ? "Payment Successful!" : "Payment Failed!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Amount: RM ${amount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
