import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';
import 'package:track_pit/models/service.dart';
import 'package:track_pit/models/service_status.dart';
import 'package:track_pit/models/service_type.dart';
import 'package:track_pit/models/workshop.dart';
import 'package:track_pit/pages/service/service_details.dart';
import 'package:track_pit/pages/vehicle/swap_vehicle.dart';
import 'package:track_pit/provider/service_provider.dart';
import 'package:track_pit/provider/vehicle_provider.dart';
import 'package:track_pit/services/car_model_service.dart';
import 'package:track_pit/services/service_type_service.dart';
import 'package:track_pit/services/workshop_service.dart';
import 'package:track_pit/widgets/layout/appbar.dart';
import 'package:track_pit/widgets/layout/bottom_navbar.dart';
import 'package:track_pit/widgets/service/service_record_card.dart';
import 'package:track_pit/widgets/service/timeline_section.dart';
import 'package:track_pit/widgets/vehicle/vehicle_add_card.dart';
import 'package:track_pit/widgets/vehicle/vehicle_info_card.dart';
import 'package:track_pit/widgets/vehicle/vehicle_loading_card.dart';

List<TimelineStep> mapToSteps(List<ServiceStatus> statuses) {
  final map = {for (var s in statuses) s.status: s.completedAt};
  const order = ["inspection", "parts_awaiting", "in_repair", "completed"];
  return order.map((status) => TimelineStep(dateTime: map[status])).toList();
}

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProv = context.watch<VehicleProvider>();
    var selected = vehicleProv.selectedVehicle;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CustomAppBar(
                title: "Services",
                subtitle: "Your service records",
                showNotifications: false,
              ),
              if (vehicleProv.isLoading)
                const VehicleLoadingCard()
              else if (selected != null)
                FutureBuilder<String>(
                  future: CarModelService.getImagePathForModel(selected.model),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const VehicleLoadingCard();
                    }

                    final imagePath =
                        snapshot.data ?? 'assets/images/car_icon.png';

                    return VehicleInfoCard(
                      model: selected.model,
                      plateNumber: selected.plateNumber,
                      imagePath: imagePath,
                      onSwap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SwapVehiclePage(),
                          ),
                        );
                      },
                    );
                  },
                )
              else
                const VehicleAddCard(),
            ],
          ),

          const SizedBox(height: Scale.cardHeight / 2 + Scale.cardMargin / 2),

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
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildServiceList(status: 'upcoming'),
                _buildServiceList(status: 'ongoing'),
                _buildServiceList(status: 'completed'),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGreen,
        onPressed: () => Navigator.pushNamed(context, '/book_service'),
        shape: const CircleBorder(),
        child: const Icon(
          Symbols.add,
          color: Colors.white,
          weight: 900,
          size: 28,
        ),
      ),

      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildServiceList({required String status}) {
    final serviceProv = context.watch<ServiceProvider>();
    final vehicleProv = context.watch<VehicleProvider>();
    final vehicle = vehicleProv.selectedVehicle;

    if (serviceProv.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehicle == null) {
      return const Center(child: Text("Please select a vehicle"));
    }
    final items =
        serviceProv.services.where((s) => s.vehicleId == vehicle.id).where((s) {
          switch (status) {
            case 'upcoming':
              return s.overallStatus == ServiceOverallStatus.upcoming;
            case 'ongoing':
              return s.overallStatus == ServiceOverallStatus.ongoing;
            case 'completed':
              return s.overallStatus == ServiceOverallStatus.completed;
            default:
              return false;
          }
        }).toList();

    items.sort((a, b) => a.bookedDateTime.compareTo(b.bookedDateTime));

    if (items.isEmpty) {
      return const Center(child: EmptyServiceView());
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        Scale.cardMargin,
        Scale.cardMargin,
        Scale.cardMargin,
        96,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: Scale.cardItemGaps),
      itemBuilder: (context, i) {
        final it = items[i];

        return FutureBuilder(
          future: Future.wait([
            WorkshopService.getWorkshop(it.workshopId),
            ServiceTypeService.getServiceType(it.serviceTypeId),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final workshop = snapshot.data![0] as Workshop?;
            final serviceType = snapshot.data![1] as ServiceType?;

            final workshopName = workshop?.name ?? "Workshop #${it.workshopId}";
            final serviceName =
                serviceType?.name ?? "Service #${it.serviceTypeId}";

            return ServiceRecordCard(
              dateTime: it.bookedDateTime,
              title: serviceName,
              workshop: workshopName,
              onDetails: () async {
                final ctx = context;
                final navigator = Navigator.of(ctx);

                if (!mounted) return;

                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailsPage(serviceId: it.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class EmptyServiceView extends StatelessWidget {
  const EmptyServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Symbols.build_circle, size: 64, color: Colors.black26),
        const SizedBox(height: 12),
        Text(
          "No services found",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
