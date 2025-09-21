import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:track_pit/core/utils/app_logger.dart';
import 'package:track_pit/models/invoice.dart';
import 'package:track_pit/pages/billing/keys.dart';

class PaymentService {
  Map<String, dynamic>? _intentPaymentData;

  Future<Map<String, dynamic>?> makeIntentForPayment(
    String amountToBeCharge,
    String currency,
  ) async {
    try {
      Map<String, dynamic> paymentInfo = {
        'amount': (int.parse(amountToBeCharge) * 100).toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        body: paymentInfo,
        headers: {
          "Authorization": "Bearer $secretKey",
          "Content-Type": "application/x-www-form-urlencoded",
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("[PaymentService] makeIntentForPayment error: $e");
      return null;
    }
  }

  Future<void> initPaymentSheet(
    BuildContext context,
    String amountToBeCharge,
    String currency, {
    String? userEmail,
    String? userName,
    List<Invoice>? selectedInvoices,
  }) async {
    try {
      _intentPaymentData = await makeIntentForPayment(
        amountToBeCharge,
        currency,
      );

      if (_intentPaymentData == null) {
        throw Exception("PaymentIntent creation failed");
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: _intentPaymentData!['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: "Track Pit",

          billingDetails: BillingDetails(
            name: userName ?? "Default User",
            email: userEmail ?? "user@example.com",
            phone: "+60123456789",
            address: const Address(
              city: "",
              country: "MY",
              line1: "",
              line2: "",
              postalCode: "",
              state: "",
            ),
          ),

          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
                address: AddressCollectionMode.automatic,
              ),
        ),
      );

      await presentPaymentSheet(context, selectedInvoices: selectedInvoices);
    } catch (e) {
      debugPrint("[PaymentService] initPaymentSheet error: $e");
      _navigateToResultPage(
        context,
        false,
        0.0,
        selectedInvoices: selectedInvoices,
      );
    }
  }

  Future<void> presentPaymentSheet(
    BuildContext context, {
    List<Invoice>? selectedInvoices,
  }) async {
    try {
      await Stripe.instance.presentPaymentSheet();

      final paidAmount =
          double.parse(_intentPaymentData?['amount'].toString() ?? "0") / 100;

      _intentPaymentData = null;

      _navigateToResultPage(
        context,
        true,
        paidAmount,
        selectedInvoices: selectedInvoices,
      );
    } on StripeException {
      _navigateToResultPage(
        context,
        false,
        0.0,
        selectedInvoices: selectedInvoices,
      );
    } catch (e) {
      _navigateToResultPage(
        context,
        false,
        0.0,
        selectedInvoices: selectedInvoices,
      );
    }
  }

  void _navigateToResultPage(
    BuildContext context,
    bool isSuccess,
    double amountPaid, {
    List<Invoice>? selectedInvoices,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Placeholder()),
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    return doc.data();
  }

  Future<bool> pay(BuildContext context, {required double amount}) async {
    AppLogger.info("[PaymentService] pay() called with amount: $amount");

    final userProfile = await _getUserProfile();
    final fullName = userProfile?['fullName'] ?? "Default User";
    final email = userProfile?['email'] ?? "user@example.com";
    AppLogger.info(
      "[PaymentService] User profile -> name: $fullName, email: $email",
    );

    try {
      AppLogger.info("[PaymentService] Creating payment intent...");
      _intentPaymentData = await makeIntentForPayment(
        amount.round().toString(),
        "myr",
      );
      AppLogger.info(
        "[PaymentService] Payment intent response: $_intentPaymentData",
      );

      if (_intentPaymentData == null) {
        AppLogger.info("[PaymentService] Payment intent is null ❌");
        return false;
      }

      AppLogger.info("[PaymentService] Initializing payment sheet...");
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: _intentPaymentData!['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: "Track Pit",
          billingDetails: BillingDetails(
            name: fullName,
            email: email,
            address: const Address(
              city: "",
              country: "MY",
              line1: "",
              line2: "",
              postalCode: "",
              state: "",
            ),
          ),
        ),
      );
      AppLogger.info("[PaymentService] Payment sheet initialized ✅");

      AppLogger.info("[PaymentService] Presenting payment sheet...");
      await Stripe.instance.presentPaymentSheet();
      AppLogger.info("[PaymentService] Payment sheet completed ✅");

      _intentPaymentData = null;
      AppLogger.info("[PaymentService] Payment flow finished successfully 🎉");
      return true;
    } catch (e, s) {
      AppLogger.info("[PaymentService] pay() error: $e");
      AppLogger.info("[PaymentService] Stacktrace: $s");
      return false;
    }
  }

  Future<void> savePaymentToFirestore(
    List<Invoice> invoices,
    double subtotal,
    double discount,
    double netTotal,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(uid);

    final batch = firestore.batch();
    final now = Timestamp.now();
    for (final inv in invoices) {
      final invoiceRef = userRef.collection('invoices').doc(inv.id);
      batch.update(invoiceRef, {'paid': true});
    }
    final paymentRef = userRef.collection('payments').doc();
    batch.set(paymentRef, {
      'invoiceIds': invoices.map((i) => i.id).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'netTotal': netTotal,
      'paidAt': now,
    });
    await batch.commit();
  }
}
