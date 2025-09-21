import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';
import 'package:track_pit/models/service.dart';

import 'package:track_pit/models/service_status.dart';
import 'package:track_pit/pages/more/feedback_page.dart';
import 'package:track_pit/provider/invoice_provider.dart';
import 'package:track_pit/provider/service_provider.dart';
import 'package:track_pit/provider/vehicle_provider.dart';

import 'package:track_pit/services/car_model_service.dart';
import 'package:track_pit/services/feedback_service.dart';
import 'package:track_pit/services/service_type_service.dart';
import 'package:track_pit/services/workshop_service.dart';

import 'package:track_pit/widgets/layout/appbar.dart';
import 'package:track_pit/widgets/service/timeline_section.dart';
import 'package:track_pit/widgets/vehicle/vehicle_info_card.dart';
import 'package:track_pit/widgets/service/service_info_card.dart';

List<TimelineStep>? toTimelineSteps(List<ServiceStatus>? statuses) {
  if (statuses == null) return null;
  return statuses.map((s) => TimelineStep(dateTime: s.completedAt)).toList();
}

class ServiceDetailsPage extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsPage({super.key, required this.serviceId});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final serviceProv = context.watch<ServiceProvider>();
    final vehicleProv = context.watch<VehicleProvider>();
    final invoiceProv = context.watch<InvoiceProvider>();

    final service =
        (() {
          try {
            return serviceProv.services.firstWhere(
              (s) => s.id == widget.serviceId,
            );
          } catch (_) {
            return null;
          }
        })();

    if (serviceProv.isLoading || service == null) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final invoice = invoiceProv.invoices.firstWhereOrNull(
      (inv) => inv.serviceId == service.id,
    );

    final vehicle =
        (() {
          try {
            return vehicleProv.vehicles.firstWhere(
              (v) => v.id == service.vehicleId,
            );
          } catch (_) {
            return null;
          }
        })();

    final future = Future.wait([
      WorkshopService.getWorkshop(service.workshopId),
      ServiceTypeService.getServiceType(service.serviceTypeId),
      if (vehicle?.model != null && vehicle!.model.isNotEmpty)
        CarModelService.getImagePathForModel(vehicle.model)
      else
        Future.value('assets/images/car_icon.png'),
    ]);

    final formattedCreatedAt = DateFormat(
      "dd MMM yyyy, hh:mm a",
    ).format(service.createdAt.toLocal());
    final steps = toTimelineSteps(service.timeline);

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.white,
            body: Column(
              children: [
                const CustomAppBar(
                  title: "Service Details",
                  subtitle: "Your service details",
                  showBack: true,
                  showNotifications: false,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final workshopName =
            (snap.data != null && snap.data!.isNotEmpty)
                ? (snap.data![0]?.name ?? "Workshop #${service.workshopId}")
                : "Workshop #${service.workshopId}";
        final serviceName =
            (snap.data != null && snap.data!.length >= 2)
                ? (snap.data![1]?.name ?? "Service #${service.serviceTypeId}")
                : "Service #${service.serviceTypeId}";
        final imagePath =
            (snap.data != null && snap.data!.length >= 3)
                ? (snap.data![2] as String? ?? 'assets/images/car_icon.png')
                : 'assets/images/car_icon.png';

        final model = vehicle?.model ?? "Unknown Model";
        final plate = vehicle?.plateNumber ?? "Unknown Plate";

        return Scaffold(
          backgroundColor: AppColors.white,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Scale.cardMargin,
                    Scale.cardHeight -
                        Scale.cardTopOffset +
                        (Scale.cardMargin / 2) +
                        Scale.defaultAppbarHeight +
                        Scale.cardMargin,
                    Scale.cardMargin,
                    120,
                  ),
                  child: Column(
                    children: [
                      FutureBuilder<bool>(
                        future: FeedbackService.hasFeedback(service.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox();
                          }
                          final hasFeedback = snapshot.data ?? false;

                          if (service.overallStatus ==
                              ServiceOverallStatus.completed) {
                            if (!hasFeedback) {
                              // Case 1: Service completed but no feedback yet
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Service completed 🎉\nWe'd love your feedback!",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      label: const Text(
                                        "Submit Feedback",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => FeedbackPage(
                                                  serviceId: service.id,
                                                ),
                                          ),
                                        ).then((_) {
                                          setState(() {}); // refresh
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Case 2: Feedback already submitted
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  border: Border.all(
                                    color: Colors.blue.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Thank you! You have already submitted your feedback.",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                          return const SizedBox();
                        },
                      ),

                      Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number,
                            size: 18,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Service ID: ${service.id}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Booked on: $formattedCreatedAt",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TimelineSection(steps: steps),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (service.notes.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Notes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                service.notes,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: const Text(
                            "No additional notes.",
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const CustomAppBar(
                        title: "Service Details",
                        subtitle: "Your service details",
                        showBack: true,
                        showNotifications: false,
                      ),
                      ServiceInfoCard(
                        dateTime: service.bookedDateTime,
                        title: serviceName,
                        workshop: workshopName,
                        status: service.overallStatus.name,
                      ),
                      VehicleInfoCard(
                        top:
                            Scale.defaultAppbarHeight -
                            Scale.cardTopOffset +
                            Scale.cardMargin / 2,
                        model: model,
                        plateNumber: plate,
                        imagePath: imagePath,
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Scale.cardMargin,
                    vertical: Scale.cardMargin,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.primaryGreen, width: 1),
                    ),
                    color: Colors.white,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 💰 Total Amount Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Total Amount:",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              invoice == null
                                  ? "Price TBD"
                                  : "RM ${invoice.price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                        // 💳 Make Payment Button
                        // 💳 Right section
                        if (invoice == null) ...[
                          ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              "Awaiting Invoice",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else if (!invoice.paid) ...[
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              "Make Payment",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else ...[
                          // ✅ Invoice is already paid → show badge instead of button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Paid",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
