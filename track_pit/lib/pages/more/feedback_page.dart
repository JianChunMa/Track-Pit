import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_pit/core/utils/snackbar.dart';
import 'package:track_pit/core/constants/colors.dart';

class FeedbackPage extends StatefulWidget {
  final String? serviceId;
  const FeedbackPage({super.key, this.serviceId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _rating = 0;
  final TextEditingController _messageCtrl = TextEditingController();
  bool _submitting = false;

  final Map<int, Map<String, dynamic>> _ratingMap = {
    1: {'label': 'Bad', 'color': Colors.red},
    2: {'label': 'Acceptable', 'color': Colors.orange},
    3: {'label': 'Good', 'color': Colors.yellow},
    4: {'label': 'Excellent', 'color': Colors.lightGreen},
    5: {'label': 'Best', 'color': Colors.green},
  };

  Future<void> _submit() async {
    if (_rating == 0) {
      showClosableSnackBar(context, 'Please select a rating');
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final feedbackData = {
        'uid': user?.uid,
        'email': user?.email,
        'rating': _rating,
        'message': _messageCtrl.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (widget.serviceId != null) {
        feedbackData['serviceId'] = widget.serviceId;
      }

      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      if (!mounted) return;
      showClosableSnackBar(context, 'Feedback submitted successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showClosableSnackBar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingInfo = _ratingMap[_rating];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          const Text(
            "How was your experience?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          if (ratingInfo != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ratingInfo['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ratingInfo['label'],
                  style: TextStyle(
                    color: ratingInfo['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final index = i + 1;
              return IconButton(
                icon: Icon(
                  index <= _rating ? Icons.star : Icons.star_border,
                  size: 36,
                  color:
                      index <= _rating
                          ? (_ratingMap[_rating]?['color'] ?? Colors.grey)
                          : Colors.grey,
                ),
                onPressed: () => setState(() => _rating = index),
              );
            }),
          ),
          const SizedBox(height: 24),

          const Text("Write your message:"),
          const SizedBox(height: 8),
          TextField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Enter your feedback here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _submitting ? null : _submit,
            icon:
                _submitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.send),
            label: Text(_submitting ? "Submitting..." : "Submit Feedback"),
          ),
        ),
      ),
    );
  }
}
