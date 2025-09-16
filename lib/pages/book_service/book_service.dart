import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../widgets/appbar.dart';
import '../../../widgets/bottom_navbar.dart';
import '../../../core/constants/colors.dart';
import '/widgets/vehicle_info_card.dart';
import '/pages/home/home_empty_view.dart';

class BookServicePage extends StatefulWidget {
  const BookServicePage({Key? key}) : super(key: key);

  @override
  State<BookServicePage> createState() => _BookServicePageState();
}

class _BookServicePageState extends State<BookServicePage> {
  // --- vehicle pick (latest by default; can be swapped) ---
  String? _selVehicleId;
  String? _selModel;
  String? _selPlate;
  String? _selImg;

  // --- form state ---
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  String? _serviceType;
  String? _workshop;
  DateTime? _date;
  TimeOfDay? _time;

  bool _submitting = false;

  // sample lists (replace with your own)
  final _serviceTypes = const <String>[
    'Regular Service',
    'Repair',
    'Inspection',
    'Tyre/Battery',
  ];
  final _workshops = const <String>[
    'PitStop Garage (Cheras)',
    'Speedy Autos (PJ)',
    'Green Motors (Setapak)',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/signin'));
      return const SizedBox.shrink();
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final latestVehicleQ = userDoc
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .limit(1);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ===== Header with CustomAppBar + overlapping vehicle card =====
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: userDoc.snapshots(),
                builder: (context, userSnap) {
                  final fullName = userSnap.data?.data()?['fullName'] as String? ??
                      user.displayName ??
                      'User';

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomAppBar(title: "Book Service",showBack: true),
                      Positioned(
                        bottom: -35,
                        left: 16,
                        right: 16,
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: latestVehicleQ.snapshots(),
                          builder: (context, vehSnap) {
                            if (vehSnap.connectionState == ConnectionState.waiting) {
                              return _loadingVehicleCardSkeleton();
                            }
                            if (vehSnap.hasError) {
                              return _noVehicleHeader();
                            }

                            final docs = vehSnap.data?.docs ?? [];
                            if (docs.isEmpty && _selModel == null) {
                              return _noVehicleHeader();
                            }

                            // Base (latest) from Firestore
                            String baseId = '';
                            String baseModel = '';
                            String basePlate = '';
                            String baseImg = 'lib/assets/images/car_icon.png';

                            if (docs.isNotEmpty) {
                              final first = docs.first;
                              final v = first.data();
                              baseId = first.id;
                              baseModel = (v['model'] ?? '') as String;
                              basePlate = (v['plateNumber'] ?? '') as String;
                              baseImg = _imageForModel(baseModel);
                            }

                            final vehicleId = _selVehicleId ?? baseId;
                            final model = _selModel ?? baseModel;
                            final plate = _selPlate ?? basePlate;
                            final img = _selImg ?? baseImg;

                            if (vehicleId.isEmpty) return _noVehicleHeader();

                            return VehicleInfoCard(
                              model: model,
                              plateNumber: plate,
                              imagePath: img,
                              onSwap: () async {
                                final picked = await Navigator.pushNamed(
                                  context,
                                  '/swap_vehicle',
                                  arguments: {'selectMode': true},
                                );
                                if (picked is Map) {
                                  final m = (picked['model'] ?? '').toString();
                                  setState(() {
                                    _selVehicleId = (picked['id'] ?? '').toString();
                                    _selModel = m;
                                    _selPlate = (picked['plate'] ?? '').toString();
                                    _selImg = _imageForModel(m);
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 50),

              // ===== Form card =====
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x15000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Service Type'),
                          DropdownButtonFormField<String>(
                            value: _serviceType,
                            items: _serviceTypes
                                .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            decoration: _fieldDeco('Select Service Type'),
                            validator: (v) =>
                            v == null ? 'Please select a service type' : null,
                            onChanged: (v) => setState(() => _serviceType = v),
                          ),
                          const SizedBox(height: 16),

                          _label('Workshop'),
                          DropdownButtonFormField<String>(
                            value: _workshop,
                            items: _workshops
                                .map((w) =>
                                DropdownMenuItem(value: w, child: Text(w)))
                                .toList(),
                            decoration: _fieldDeco('Select Workshop'),
                            validator: (v) =>
                            v == null ? 'Please select a workshop' : null,
                            onChanged: (v) => setState(() => _workshop = v),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Preferred Date'),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _pickDate,
                                      child: InputDecorator(
                                        decoration: _fieldDeco('dd-mm-yyyy'),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _date == null
                                                  ? 'dd-mm-yyyy'
                                                  : _fmtDate(_date!),
                                              style: TextStyle(
                                                color: _date == null
                                                    ? Colors.grey.shade500
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const Icon(Icons.calendar_today,
                                                size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Preferred Time'),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _pickTime,
                                      child: InputDecorator(
                                        decoration: _fieldDeco('hh:mm'),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _time == null
                                                  ? 'hh:mm'
                                                  : _fmtTime(_time!),
                                              style: TextStyle(
                                                color: _time == null
                                                    ? Colors.grey.shade500
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const Icon(Icons.schedule, size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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
                              onPressed: _submitting ? null : _onBook,
                              child:
                              Text(_submitting ? 'Booking…' : 'Book'),
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
          // Progress veil for submit
        ),
        if (_submitting)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withOpacity(0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  // ---------- helpers ----------

  InputDecoration _fieldDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF1F3F5),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          fontWeight: FontWeight.w700, color: Colors.black87),
    ),
  );

  Widget _loadingVehicleCardSkeleton() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primaryAccent),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(width: 80, height: 56, color: Colors.black12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 140, color: Colors.black12),
                const SizedBox(height: 8),
                Container(height: 14, width: 100, color: Colors.black12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noVehicleHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primaryAccent),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.directions_car, size: 32, color: Colors.black38),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No vehicle available. Add a vehicle first.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _date ?? now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked =
    await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  String _imageForModel(String model) {
    final m = model.toLowerCase();
    if (m.contains('x50')) return 'lib/assets/images/x50.png';
    if (m.contains('myvi')) return 'lib/assets/images/peroduamyvi.png';
    if (m.contains('civic')) return 'lib/assets/images/civic.png';
    if (m.contains('accord')) return 'lib/assets/images/accord.jpg';
    return 'lib/assets/images/car_icon.png';
  }

  Future<void> _onBook() async {
    // Validate vehicle + form
    if ((_selVehicleId ?? '').isEmpty) {
      // If user never swapped, we still might have a base vehicle from Firestore header;
      // the simplest safety: require a selected (swapped or base) vehicle.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle first.')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a preferred date and time.')),
      );
      return;
    }

    // Here you can combine date + time for startAt
    final startAt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    setState(() => _submitting = true);

    try {
      // TODO: Save booking to Firestore if you want:
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookings')
          .add({
            'vehicleId': _selVehicleId,
            'serviceType': _serviceType,
            'workshopName': _workshop,
            'date': Timestamp.fromDate(_date!),
            'time': _fmtTime(_time!),
            'startAt': Timestamp.fromDate(startAt),
            'notes': _notesCtrl.text.trim(),
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking submitted!')),
        );
        Navigator.pop(context); // or go to a confirmation page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit booking: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}