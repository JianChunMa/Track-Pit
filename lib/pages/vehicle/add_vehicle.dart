import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/vehicle.dart';
import '../../services/user_services.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({Key? key}) : super(key: key);

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();

  // simple demo models list; replace with your own source
  final _models = const <String>[
    'Proton X50 1.5T',
    'Proton Saga 1.3L',
    'Perodua Myvi 1.5',
    'Honda Accord 2.4L',
    'Honda Civic 1.5T',
    'Toyota Vios 1.5',
  ];

  String? _selectedModel;
  int? _selectedYear;
  Transmission? _selectedTx;

  bool _loading = false;
  final _service = UserService();

  @override
  void dispose() {
    _plateCtrl.dispose();
    _vinCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  String _canonPlate(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'\s+'), '');

  List<int> _yearOptions() {
    final now = DateTime.now().year;
    return List<int>.generate(40, (i) => now - i); // last 40 years
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in.')),
      );
      return;
    }

    setState(() => _loading = true);

    final plate = _canonPlate(_plateCtrl.text.trim());
    final model = _selectedModel!;
    final vin = _vinCtrl.text.trim();
    final year = _selectedYear!;
    final mileage = int.parse(_mileageCtrl.text.trim());
    final tx = _selectedTx!;

    try {
      // Build the Vehicle (id is not used on create; Firestore generates it)
      final vehicle = Vehicle(
        id: '', // not used in create
        plateNumber: plate,
        model: model,
        chassisNumber: vin,
        year: year,
        mileage: mileage,
        transmission: tx,
        createdAt: DateTime.now(),
      );

      await _service.addVehicleForUser(uid: user.uid, vehicle: vehicle);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle added successfully!')),
      );

      Navigator.pop(context); // return to previous page (e.g., Home)
    } on Exception catch (e) {
      final msg = e.toString().contains('Plate already registered')
          ? 'This plate is already registered.'
          : 'Failed to add vehicle. Please try again.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = _yearOptions();

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Add a Vehicle'),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Vehicle Plate Number'),
                    _RoundedField(
                      controller: _plateCtrl,
                      hint: 'Enter Plate Number',
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Plate number is required';
                        }
                        final canonical = _canonPlate(v);
                        if (!RegExp(r'^[A-Z0-9\-]{4,12}$').hasMatch(canonical)) {
                          return 'Enter a valid plate (A–Z/0–9, 4–12 chars)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Vehicle Model'),
                    _RoundedDropdown<String>(
                      value: _selectedModel,
                      hint: 'Select Model',
                      items: _models
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      validator: (v) => v == null ? 'Select a model' : null,
                      onChanged: (v) => setState(() => _selectedModel = v),
                    ),
                    const SizedBox(height: 16),

                    _label('Chassis Number (VIN)'),
                    _RoundedField(
                      controller: _vinCtrl,
                      hint: 'Enter VIN',
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'VIN is required' : null,
                    ),
                    const SizedBox(height: 16),

                    _label('Year of Manufacture'),
                    _RoundedDropdown<int>(
                      value: _selectedYear,
                      hint: 'Select Year',
                      items: years
                          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                          .toList(),
                      validator: (v) => v == null ? 'Select a year' : null,
                      onChanged: (v) => setState(() => _selectedYear = v),
                    ),
                    const SizedBox(height: 16),

                    _label('Mileage (km)'),
                    _RoundedField(
                      controller: _mileageCtrl,
                      hint: 'Enter Mileage',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Mileage is required';
                        }
                        final n = int.tryParse(v);
                        if (n == null || n < 0) {
                          return 'Enter a valid mileage';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Transmission Type'),
                    _RoundedDropdown<Transmission>(
                      value: _selectedTx,
                      hint: 'Select Transmission Type',
                      items: Transmission.values
                          .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_txLabel(t)),
                      ))
                          .toList(),
                      validator: (v) =>
                      v == null ? 'Select a transmission type' : null,
                      onChanged: (v) => setState(() => _selectedTx = v),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submit,
                        child: const Text('Add Vehicle'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_loading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _label(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  String _txLabel(Transmission t) {
    switch (t) {
      case Transmission.manual:
        return 'Manual';
      case Transmission.automatic:
        return 'Automatic';
      case Transmission.cvt:
        return 'CVT';
      case Transmission.dct:
        return 'DCT';
    }
  }
}

/// Rounded text field (matches your style)
class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _RoundedField({
    Key? key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryAccent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.6),
        ),
      ),
    );
  }
}

/// Rounded dropdown with validation
class _RoundedDropdown<T> extends FormField<T> {
  _RoundedDropdown({
    Key? key,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    String? Function(T?)? validator,
    required void Function(T?) onChanged,
  }) : super(
    key: key,
    validator: validator,
    initialValue: value,
    builder: (state) {
      final themeBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primaryAccent,
        ),
      );

      return InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          border: themeBorder,
          enabledBorder: themeBorder,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            BorderSide(color: AppColors.primaryGreen, width: 1.6),
          ),
          errorText: state.errorText,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: state.value,
            hint: Text(hint),
            items: items,
            onChanged: (v) {
              state.didChange(v);
              onChanged(v);
            },
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      );
    },
  );
}
