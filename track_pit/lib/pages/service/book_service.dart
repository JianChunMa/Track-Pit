import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';
import 'package:track_pit/core/utils/snackbar.dart';
import 'package:track_pit/models/service.dart' show Service;
import 'package:track_pit/models/workshop.dart';
import 'package:track_pit/models/service_type.dart';
import 'package:track_pit/pages/vehicle/swap_vehicle.dart';
import 'package:track_pit/provider/service_provider.dart';
import 'package:track_pit/provider/vehicle_provider.dart';
import 'package:track_pit/services/car_model_service.dart';
import 'package:track_pit/services/workshop_service.dart';
import 'package:track_pit/services/service_type_service.dart';
import 'package:track_pit/widgets/layout/appbar.dart';
import 'package:track_pit/widgets/service/booking_confirm_dialog.dart';
import 'package:track_pit/widgets/vehicle/vehicle_add_card.dart';
import 'package:track_pit/widgets/vehicle/vehicle_info_card.dart';
import 'package:track_pit/widgets/vehicle/vehicle_loading_card.dart';

class BookServicePage extends StatefulWidget {
  const BookServicePage({super.key});

  @override
  State<BookServicePage> createState() => _BookServicePageState();
}

class _BookServicePageState extends State<BookServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  int? _serviceTypeId;
  int? _workshopId;
  DateTime? _date;
  TimeOfDay? _time;

  Future<void> _bookService(BuildContext context) async {
    final vehicleProv = context.read<VehicleProvider>();
    final serviceProv = context.read<ServiceProvider>();

    if (!_formKey.currentState!.validate()) return;

    final vehicle = vehicleProv.selectedVehicle;
    if (vehicle == null) {
      showClosableSnackBar(context, 'Please select a vehicle first');
      return;
    }

    if (_date == null || _time == null) {
      showClosableSnackBar(context, 'Please select a date & time');
      return;
    }

    final now = DateTime.now();
    final bookedDateTime = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (bookedDateTime.isBefore(tomorrow)) {
      showClosableSnackBar(
        context,
        'Earliest booking must be tomorrow or later',
      );
      return;
    }

    final service = Service(
      id: '',
      serviceTypeId: _serviceTypeId!,
      workshopId: _workshopId!,
      vehicleId: vehicle.id,
      bookedDateTime: bookedDateTime,
      notes: _notesCtrl.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    try {
      final serviceId = await serviceProv.addService(service);
      if (!mounted) return;
      if (!context.mounted) return;

      BookingConfirmedDialog.show(
        context,
        at: bookedDateTime,
        onDetail: () {
          Navigator.popAndPushNamed(context, '/service_page');
          Navigator.pushNamed(context, '/service_detail', arguments: serviceId);
        },
        onConfirm: () {
          Navigator.of(context).pop();
          Navigator.pop(context);
        },
      );
    } catch (e) {
      showClosableSnackBar(context, 'Failed to book: $e');
    }
  }

  List<ServiceType> _serviceTypes = [];
  bool _loadingServiceTypes = true;

  List<Workshop> _workshops = [];
  bool _loadingWorkshops = true;

  Future<void> _loadWorkshops() async {
    final workshops = await WorkshopService.getWorkshops();
    setState(() {
      _workshops = workshops;
      _loadingWorkshops = false;
    });
  }

  Future<void> _loadServiceTypes() async {
    final types = await ServiceTypeService.getServiceTypes();
    setState(() {
      _serviceTypes = types;
      _loadingServiceTypes = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
    _loadServiceTypes();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double vehicleCardTop = 184 - Scale.cardHeight - Scale.cardTopOffset;

    final vehicleProv = context.watch<VehicleProvider>();
    var selected = vehicleProv.selectedVehicle;

    Widget vehicleCard;
    if (vehicleProv.isLoading) {
      vehicleCard = const VehicleLoadingCard(top: vehicleCardTop);
    } else if (selected != null) {
      vehicleCard = FutureBuilder<String>(
        future: CarModelService.getImagePathForModel(selected.model),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const VehicleLoadingCard(top: vehicleCardTop);
          }

          final imagePath = snapshot.data ?? 'assets/images/car_icon.png';

          return VehicleInfoCard(
            model: selected.model,
            plateNumber: selected.plateNumber,
            imagePath: imagePath,
            top: vehicleCardTop,
            onSwap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SwapVehiclePage()),
              );
            },
          );
        },
      );
    } else {
      vehicleCard = const VehicleAddCard(top: vehicleCardTop);
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Column(
            children: [
              const CustomAppBar(
                title: "Book Service",
                showBack: true,
                showNotifications: false,
                height: 184,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Scale.cardMargin,
                    Scale.cardTopOffset * -1 + 12,
                    Scale.cardMargin,
                    20,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryAccent,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.16),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Service Type'),
                          DropdownButtonFormField<int>(
                            value: _serviceTypeId,
                            items:
                                _loadingServiceTypes
                                    ? []
                                    : _serviceTypes
                                        .map(
                                          (s) => DropdownMenuItem<int>(
                                            value: s.id,
                                            child: Text(s.name),
                                          ),
                                        )
                                        .toList(),
                            decoration: _fieldDeco('Select Service Type'),
                            validator:
                                (v) =>
                                    v == null
                                        ? 'Please select a service type'
                                        : null,
                            onChanged:
                                (v) => setState(() => _serviceTypeId = v),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _label('Workshop'),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/find_workshop',
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Find Workshop',
                                  style: TextStyle(
                                    color: AppColors.secondaryGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          DropdownButtonFormField<int>(
                            value: _workshopId,
                            items:
                                _loadingWorkshops
                                    ? []
                                    : _workshops
                                        .map(
                                          (w) => DropdownMenuItem<int>(
                                            value: w.id,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    w.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Text(
                                                    w.address,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                    softWrap: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                            selectedItemBuilder: (context) {
                              return _workshops.map((w) {
                                return Text(
                                  w.name,
                                  style: const TextStyle(color: Colors.black87),
                                );
                              }).toList();
                            },
                            decoration: _fieldDeco('Select Workshop'),
                            validator:
                                (v) =>
                                    v == null
                                        ? 'Please select a workshop'
                                        : null,
                            onChanged: (v) {
                              setState(() => _workshopId = v);
                            },
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: FormField<DateTime>(
                                  validator:
                                      (val) =>
                                          _date == null
                                              ? 'Please select a date'
                                              : null,
                                  builder:
                                      (state) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Preferred Date'),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: _pickDate,
                                            child: InputDecorator(
                                              decoration: _fieldDeco(
                                                'dd-mm-yyyy',
                                              ).copyWith(
                                                errorText: state.errorText,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _date == null
                                                        ? 'dd-mm-yyyy'
                                                        : _fmtDate(_date!),
                                                    style: TextStyle(
                                                      color:
                                                          _date == null
                                                              ? Colors
                                                                  .grey
                                                                  .shade500
                                                              : Colors.black87,
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: FormField<TimeOfDay>(
                                  validator:
                                      (val) =>
                                          _time == null
                                              ? 'Please select a time'
                                              : null,
                                  builder:
                                      (state) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Preferred Time'),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: _pickTime,
                                            child: InputDecorator(
                                              decoration: _fieldDeco(
                                                'hh:mm',
                                              ).copyWith(
                                                errorText: state.errorText,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _time == null
                                                        ? 'hh:mm'
                                                        : _fmtTime(_time!),
                                                    style: TextStyle(
                                                      color:
                                                          _time == null
                                                              ? Colors
                                                                  .grey
                                                                  .shade500
                                                              : Colors.black87,
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.schedule,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _label('Additional Notes'),
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 4,
                            decoration: _fieldDeco(
                              'Describe any specific issues or requirements...',
                            ),
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _bookService(context),
                              child: const Text('Book'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          vehicleCard,
        ],
      ),
    );
  }

  InputDecoration _fieldDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF1F3F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    ),
  );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    final picked = await showDatePicker(
      context: context,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 2),
      initialDate: _date ?? tomorrow,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final options = <TimeOfDay>[];
    for (int h = 8; h <= 19; h++) {
      options.add(TimeOfDay(hour: h, minute: 0));
      if (h < 19) options.add(TimeOfDay(hour: h, minute: 30));
    }

    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text("Select Time"),
          children:
              options.map((t) {
                final label =
                    "${t.hourOfPeriod.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} "
                    "${t.period == DayPeriod.am ? 'AM' : 'PM'}";
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, t),
                  child: Text(label),
                );
              }).toList(),
        );
      },
    );

    if (picked != null) {
      setState(() => _time = picked);
    }
  }
}
