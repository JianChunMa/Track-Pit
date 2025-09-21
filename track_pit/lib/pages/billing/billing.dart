import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';
import 'package:track_pit/core/utils/app_logger.dart';
import 'package:track_pit/pages/billing/checkout.dart';
import 'package:track_pit/provider/payment_provider.dart';
import 'package:track_pit/widgets/billing/invoice_card.dart';
import 'package:track_pit/widgets/billing/invoice_summary_card.dart';
import 'package:track_pit/widgets/billing/payment_history_card.dart';
import 'package:track_pit/widgets/layout/appbar.dart';
import 'package:track_pit/widgets/layout/bottom_navbar.dart';
import 'package:track_pit/provider/invoice_provider.dart';
import 'package:track_pit/provider/service_provider.dart';
import 'package:track_pit/provider/vehicle_provider.dart';

import 'package:track_pit/models/invoice.dart';
import 'package:track_pit/models/service.dart';
import 'package:track_pit/models/service_type.dart';
import 'package:track_pit/models/vehicle.dart';
import 'package:track_pit/models/workshop.dart';

import 'package:track_pit/services/service_type_service.dart';
import 'package:track_pit/services/workshop_service.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage>
    with SingleTickerProviderStateMixin {
  static const double appBarHeight = 254;
  late final TabController _tab;
  final GlobalKey _cardKey = GlobalKey();
  double? _cardHeight;
  final Map<String, bool> _selectedInvoices = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().startListening();

      final contextCard = _cardKey.currentContext;
      if (contextCard != null) {
        final box = contextCard.findRenderObject() as RenderBox;
        setState(() {
          _cardHeight = box.size.height;
        });
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    context.read<InvoiceProvider>().stopListening();
    super.dispose();
  }

  void _onCheckout() {
    AppLogger.log("[BillingPage] _onCheckout called");
    final invoices = context.read<InvoiceProvider>().invoices;
    final selected =
        invoices.where((inv) => _selectedInvoices[inv.id] ?? false).toList();
    AppLogger.log(selected.isEmpty.toString());
    if (selected.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(selectedInvoices: selected),
      ),
    );
  }

  Future<List<Map<String, String>>> _resolveInvoices(
    List<String> invoiceIds,
  ) async {
    final invoiceProvider = Provider.of<InvoiceProvider>(
      context,
      listen: false,
    );
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    final vehicleProvider = Provider.of<VehicleProvider>(
      context,
      listen: false,
    );

    final List<Map<String, String>> results = [];

    for (final id in invoiceIds) {
      final inv = invoiceProvider.invoices.firstWhereOrNull((i) => i.id == id);
      if (inv == null) continue;

      final service = serviceProvider.services.firstWhereOrNull(
        (s) => s.id == inv.serviceId,
      );

      String? title;
      String? car;
      String date = DateFormat("d MMM yyyy").format(inv.issuedAt);

      if (service != null) {
        final vehicle = vehicleProvider.vehicles.firstWhereOrNull(
          (v) => v.id == service.vehicleId,
        );
        final serviceType = await ServiceTypeService.getServiceType(
          service.serviceTypeId,
        );

        title = serviceType?.name ?? "Unknown Service";
        car =
            vehicle != null
                ? "${vehicle.model} (${vehicle.plateNumber})"
                : "Unknown Vehicle";
      }

      results.add({
        "title": title ?? "Unknown Service",
        "car": car ?? "Unknown Car",
        "date": date,
      });
    }

    return results;
  }

  Future<Map<String, dynamic>> _calculateSummary(List<Invoice> invoices) async {
    // Only consider selected invoices
    final selectedIds =
        _selectedInvoices.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toSet();

    final selectedInvoices =
        invoices.where((inv) => selectedIds.contains(inv.id)).toList();

    if (selectedInvoices.isEmpty) {
      return {
        "invoicesSelected": 0,
        "vehiclesInvolved": 0,
        "servicesIncluded": 0,
        "total": 0.0,
      };
    }

    // Query sqlite via providers
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );

    final vehicleIds = <String>{};
    final serviceTypeIds = <int>{};
    double total = 0.0;

    for (final inv in selectedInvoices) {
      final Service? service = serviceProvider.services.firstWhereOrNull(
        (s) => s.id == inv.serviceId,
      );
      if (service != null) {
        vehicleIds.add(service.vehicleId);
        serviceTypeIds.add(service.serviceTypeId);
      }

      total += inv.price;
    }

    return {
      "invoicesSelected": selectedInvoices.length,
      "vehiclesInvolved": vehicleIds.length,
      "servicesIncluded": serviceTypeIds.length,
      "total": total,
    };
  }

  Future<Map<String, String>> _loadInvoiceDetails(Invoice inv) async {
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
          SizedBox(
            height:
                appBarHeight +
                (_cardHeight != null ? _cardHeight! / 2 : appBarHeight / 2) +
                Scale.cardMargin / 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const CustomAppBar(
                  title: "Billing",
                  subtitle: "Your billing records",
                  showNotifications: false,
                  height: appBarHeight,
                ),
                FutureBuilder<Map<String, dynamic>>(
                  key: ValueKey(_selectedInvoices.hashCode),
                  future: _calculateSummary(
                    context.read<InvoiceProvider>().invoices,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return InvoiceSummaryCard(
                        key: _cardKey,
                        top:
                            _cardHeight != null
                                ? appBarHeight - _cardHeight! / 2
                                : appBarHeight / 2,
                        invoicesSelected: 0,
                        vehiclesInvolved: 0,
                        servicesIncluded: 0,
                        total: 0,
                        onCheckout: _onCheckout,
                      );
                    }

                    final data = snapshot.data!;
                    return InvoiceSummaryCard(
                      key: _cardKey,
                      top:
                          _cardHeight != null
                              ? appBarHeight - _cardHeight! / 2
                              : appBarHeight / 2,
                      invoicesSelected: data["invoicesSelected"],
                      vehiclesInvolved: data["vehiclesInvolved"],
                      servicesIncluded: data["servicesIncluded"],
                      total: data["total"],
                      onCheckout: _onCheckout,
                    );
                  },
                ),
              ],
            ),
          ),

          Material(
            color: AppColors.white,
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: Colors.black45,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              indicatorColor: AppColors.primaryGreen,
              tabs: const [Tab(text: 'Bills'), Tab(text: 'Payment History')],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                Consumer<InvoiceProvider>(
                  builder: (context, invoiceProvider, _) {
                    if (invoiceProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (invoiceProvider.error != null) {
                      return Center(
                        child: Text("Error: ${invoiceProvider.error}"),
                      );
                    }
                    if (invoiceProvider.invoices.isEmpty) {
                      return const Center(
                        child: EmptyBillingView(message: "No bills found"),
                      );
                    }
                    final unpaidInvoices =
                        invoiceProvider.invoices
                            .where((inv) => !inv.paid)
                            .toList();

                    if (unpaidInvoices.isEmpty) {
                      return const Center(
                        child: EmptyBillingView(message: "No unpaid bills 🎉"),
                      );
                    }
                    return ListView.separated(
                      separatorBuilder:
                          (_, __) => const SizedBox(height: Scale.cardItemGaps),
                      padding: const EdgeInsets.fromLTRB(
                        Scale.cardMargin,
                        Scale.cardMargin,
                        Scale.cardMargin,
                        Scale.cardMargin * 2,
                      ),
                      itemCount: unpaidInvoices.length,
                      itemBuilder: (context, index) {
                        final inv = unpaidInvoices[index];

                        return FutureBuilder<Map<String, String>>(
                          future: _loadInvoiceDetails(inv),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              );
                            }
                            final details = snapshot.data!;
                            return InvoiceCard(
                              id: inv.id,
                              date: inv.issuedAt,
                              title: details["title"]!,
                              car: details["car"]!,
                              location: details["location"]!,
                              price: inv.price,
                              isSelected: _selectedInvoices[inv.id] ?? false,
                              onToggle: (id) {
                                setState(() {
                                  _selectedInvoices[id] =
                                      !(_selectedInvoices[id] ?? false);
                                });
                              },
                              onShowInvoice: () {},
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                Consumer<PaymentProvider>(
                  builder: (context, paymentProvider, _) {
                    if (paymentProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (paymentProvider.error != null) {
                      return Center(
                        child: Text("Error: ${paymentProvider.error}"),
                      );
                    }
                    if (paymentProvider.payments.isEmpty) {
                      return const EmptyBillingView(
                        message: "No payment history found",
                        icon: Icons.history,
                      );
                    }

                    return ListView.separated(
                      separatorBuilder:
                          (_, __) => const SizedBox(height: Scale.cardItemGaps),
                      padding: const EdgeInsets.all(Scale.cardMargin),
                      itemCount: paymentProvider.payments.length,
                      itemBuilder: (context, index) {
                        final payment = paymentProvider.payments[index];
                        return FutureBuilder<List<Map<String, String>>>(
                          future: _resolveInvoices(payment.invoiceIds),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              );
                            }
                            return PaymentHistoryCard(
                              subtotal: payment.subtotal,
                              discount: payment.discount,
                              netTotal: payment.netTotal,
                              paidAt: payment.paidAt,
                              invoices: snapshot.data!,
                              onShowInvoice: () {}, // leave functionless
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }
}

class EmptyBillingView extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyBillingView({
    super.key,
    this.message = "No billings found",
    this.icon = Icons.receipt_long_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.black26),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
