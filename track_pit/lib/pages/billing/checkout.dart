import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';
import 'package:track_pit/models/invoice.dart';
import 'package:track_pit/models/service.dart';
import 'package:track_pit/models/service_type.dart';
import 'package:track_pit/models/vehicle.dart';
import 'package:track_pit/models/workshop.dart';
import 'package:track_pit/pages/billing/result_page.dart';
import 'package:track_pit/services/payment_service.dart';
import 'package:track_pit/services/service_type_service.dart';
import 'package:track_pit/services/workshop_service.dart';
import 'package:track_pit/provider/service_provider.dart';
import 'package:track_pit/provider/vehicle_provider.dart';

import 'package:track_pit/widgets/layout/appbar.dart';

class CheckoutPage extends StatefulWidget {
  final List<Invoice> selectedInvoices;
  const CheckoutPage({super.key, required this.selectedInvoices});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final PaymentService _paymentService = PaymentService();

  double get subtotal =>
      widget.selectedInvoices.fold(0.0, (sum, e) => sum + e.price);
  double get discount => subtotal * 0.1; // Example 10%
  double get totalPayment => subtotal - discount;

  Future<Map<String, String>> _loadDetails(
    BuildContext context,
    Invoice inv,
  ) async {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    final vehicleProvider = Provider.of<VehicleProvider>(
      context,
      listen: false,
    );

    final Service? service = serviceProvider.services.firstWhereOrNull(
      (s) => s.id == inv.serviceId,
    );

    Vehicle? vehicle;
    ServiceType? serviceType;
    Workshop? workshop;

    if (service != null) {
      vehicle = vehicleProvider.vehicles.firstWhereOrNull(
        (v) => v.id == service.vehicleId,
      );
      serviceType = await ServiceTypeService.getServiceType(
        service.serviceTypeId,
      );
      workshop = await WorkshopService.getWorkshop(service.workshopId);
    }

    return {
      "title": serviceType?.name ?? "Unknown Service",
      "car":
          vehicle != null
              ? "${vehicle.model} (${vehicle.plateNumber})"
              : "Unknown Vehicle",
      "location": workshop?.name ?? "Unknown Workshop",
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // ---------- AppBar ----------
          const CustomAppBar(
            title: "Checkout",
            showNotifications: false,
            showBack: true,
            height: 152,
          ),

          // ---------- Main content ----------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Scale.cardMargin,
                Scale.cardMargin,
                Scale.cardMargin,
                Scale.cardMargin * 2,
              ),
              children: [
                _buildBillingDetails(context),
                const SizedBox(height: Scale.cardMargin),
                _buildPaymentDetails(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Scale.cardMargin),
          child: _buildPayNowButton(context),
        ),
      ),
    );
  }

  Widget _buildBillingDetails(BuildContext context) {
    return Container(
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
          // Header
          Row(
            children: const [
              Icon(Icons.receipt_long, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text(
                "Billing Summary",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(widget.selectedInvoices.length, (index) {
            final inv = widget.selectedInvoices[index];
            return FutureBuilder<Map<String, String>>(
              future: _loadDetails(context, inv),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  );
                }
                final details = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invoice ${index + 1}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details["car"]!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        "• ${details["title"]!}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Subtotal",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "RM${inv.price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    if (index < widget.selectedInvoices.length - 1) ...[
                      const SizedBox(height: 6),
                      const Divider(),
                      const SizedBox(height: 4),
                    ],
                  ],
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
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
          const Text(
            "Payment Details",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildRow("Subtotal", "RM${subtotal.toStringAsFixed(2)}"),
          _buildRow(
            "Discount",
            "-RM${discount.toStringAsFixed(2)}",
            color: Colors.red,
          ),
          const Divider(),
          _buildRow(
            "Total Payment",
            "RM${totalPayment.toStringAsFixed(2)}",
            isBold: true,
            color: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildPayNowButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          bool success = await _paymentService.pay(
            context,
            amount: totalPayment,
          );

          if (success) {
            _paymentService.savePaymentToFirestore(
              widget.selectedInvoices,
              subtotal,
              discount,
              totalPayment,
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ResultPage(isSuccess: success, amount: totalPayment),
              ),
            );
          });
        },
        child: Text(
          "Pay Now RM${totalPayment.toStringAsFixed(2)}",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String left,
    String right, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isBold ? 15 : 14,
              height: 1.25,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isBold ? 15 : 14,
              color: color ?? Colors.black,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
