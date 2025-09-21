import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:track_pit/core/utils/snackbar.dart';
import 'package:track_pit/models/vehicle.dart';
import 'package:track_pit/provider/vehicle_provider.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/services/car_model_service.dart';

class EditVehiclePage extends StatefulWidget {
  final Vehicle vehicle;

  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _plateCtrl;
  late TextEditingController _chassisCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _mileageCtrl;

  String? _selectedModel;
  List<String> _models = [];

  Transmission? _tx;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _plateCtrl = TextEditingController(text: v.plateNumber);
    _chassisCtrl = TextEditingController(text: v.chassisNumber);
    _yearCtrl = TextEditingController(text: v.year.toString());
    _mileageCtrl = TextEditingController(text: v.mileage.toString());
    _tx = v.transmission;
    _selectedModel = v.model;

    _loadModels();
  }

  Future<void> _loadModels() async {
    final names = await CarModelService.getAllModelNames();
    setState(() => _models = names);
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _chassisCtrl.dispose();
    _yearCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  String _canonPlate(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'\s+'), '');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final updated = Vehicle(
      id: widget.vehicle.id,
      plateNumber: _plateCtrl.text.trim(),
      model: _selectedModel ?? widget.vehicle.model,
      chassisNumber: _chassisCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()) ?? 0,
      mileage: int.tryParse(_mileageCtrl.text.trim()) ?? 0,
      transmission: _tx ?? Transmission.automatic,
      createdAt: widget.vehicle.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await context.read<VehicleProvider>().updateVehicle(
        widget.vehicle.id,
        updated,
        widget.vehicle.plateNumber,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showClosableSnackBar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text("Edit Vehicle"),
            actions: [
              IconButton(icon: const Icon(Icons.save), onPressed: _save),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _label("Vehicle Plate Number"),
                  _RoundedField(
                    controller: _plateCtrl,
                    hint: "Enter Plate Number",
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: TextInputType.visiblePassword,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Plate number is required";
                      }
                      final canonical = _canonPlate(v);
                      if (!RegExp(
                        r'^[A-Z]{1,3}[0-9]{1,4}[A-Z]?$',
                      ).hasMatch(canonical)) {
                        return "Enter a valid Malaysian plate (e.g., W1234)";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _label("Vehicle Model"),
                  DropdownSearch<String>(
                    selectedItem: _selectedModel,
                    items: (String filter, _) async {
                      if (filter.isEmpty) return _models;
                      return _models
                          .where(
                            (m) =>
                                m.toLowerCase().contains(filter.toLowerCase()),
                          )
                          .toList();
                    },
                    itemAsString: (item) => item,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      fit: FlexFit.loose,
                    ),
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        hintText: "Select Model",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(
                            color: AppColors.primaryAccent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(
                            color: AppColors.primaryAccent,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(
                            color: AppColors.primaryGreen,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? "Select a model"
                                : null,
                    onChanged: (v) => setState(() => _selectedModel = v),
                  ),
                  const SizedBox(height: 16),

                  _label("Chassis Number (VIN)"),
                  _RoundedField(
                    controller: _chassisCtrl,
                    hint: "Enter VIN",
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: TextInputType.visiblePassword,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "VIN is required";
                      }
                      final vin = v.trim().toUpperCase();
                      if (vin.length < 10 || vin.length > 17) {
                        return "VIN must be 10–17 characters long";
                      }
                      if (!RegExp(r'^[A-Z0-9]+$').hasMatch(vin)) {
                        return "VIN must only contain A-Z and 0-9";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _label("Year of Manufacture"),
                  _RoundedField(
                    controller: _yearCtrl,
                    hint: "Enter Year",
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Year is required";
                      }
                      final year = int.tryParse(v);
                      if (year == null ||
                          year < 1980 ||
                          year > DateTime.now().year) {
                        return "Enter a valid year";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _label("Mileage (km)"),
                  _RoundedField(
                    controller: _mileageCtrl,
                    hint: "Enter Mileage",
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Mileage is required";
                      }
                      final n = int.tryParse(v);
                      if (n == null || n < 0) {
                        return "Enter a valid mileage";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _label("Transmission Type"),
                  _RoundedDropdown<Transmission>(
                    value: _tx,
                    hint: "Select Transmission",
                    items:
                        Transmission.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                    validator:
                        (v) => v == null ? "Select a transmission type" : null,
                    onChanged: (val) => setState(() => _tx = val),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_loading)
          Positioned.fill(
            child: ColoredBox(
              color: Color.fromRGBO(0, 0, 0, 0.1),
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
}

/// Reuse rounded text field styling
class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _RoundedField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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

/// Reuse dropdown styling
class _RoundedDropdown<T> extends FormField<T> {
  _RoundedDropdown({
    super.key,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    super.validator,
    required void Function(T?) onChanged,
  }) : super(
         initialValue: value,
         builder: (state) {
           final themeBorder = OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(color: AppColors.primaryAccent),
           );

           return InputDecorator(
             decoration: InputDecoration(
               filled: true,
               fillColor: const Color(0xFFFFFFFF),
               contentPadding: const EdgeInsets.symmetric(
                 horizontal: 14,
                 vertical: 4,
               ),
               border: themeBorder,
               enabledBorder: themeBorder,
               focusedBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(12),
                 borderSide: BorderSide(
                   color: AppColors.primaryGreen,
                   width: 1.6,
                 ),
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
