import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../services/car_model_service.dart';
import '../../models/user.dart' as app;
import '../../widgets/layout/appbar.dart';
import '../../widgets/more/profile_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  String _originalName = '';

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleFabPress(fb_auth.User authUser, String uid) async {
    final messenger = ScaffoldMessenger.of(context);

    if (!_editing) {
      setState(() => _editing = true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Editing enabled. Use back to discard.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    final newName = _nameCtrl.text.trim();

    if (newName == _originalName) {
      setState(() => _editing = false);
      return;
    }

    setState(() => _saving = true);
    try {
      await _users.doc(uid).update({
        'fullName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await authUser.updateDisplayName(newName);
      if (mounted) {
        _originalName = newName;
        messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
        setState(() => _editing = false);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Update failed: ${e.message ?? e.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final uid = authUser.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: RawMaterialButton(
        fillColor: AppColors.primaryGreen,
        shape: const CircleBorder(),
        constraints: const BoxConstraints.tightFor(width: 72, height: 72),
        onPressed: _saving ? null : () => _handleFabPress(authUser, uid),
        child: _saving
            ? const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Icon(_editing ? Icons.save : Icons.edit, color: Colors.white, size: 32),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _users.doc(uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Profile not found'));
          }

          final data = snap.data!.data()!;
          final model = app.User.fromMap(uid, data);

          if (!_editing) {
            _nameCtrl.text = model.fullName;
            _originalName = model.fullName;
          }

          return WillPopScope(
            onWillPop: () async {
              final changed = _editing && _nameCtrl.text.trim() != _originalName.trim();
              if (changed) {
                final discard = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Discard changes?'),
                    content: const Text('You have unsaved changes. Discard them?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep editing'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Discard'),
                      ),
                    ],
                  ),
                );
                if (discard == true) {
                  setState(() {
                    _editing = false;
                    _nameCtrl.text = _originalName;
                  });
                  return true;
                }
                return false;
              }
              return true;
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CustomAppBar(
                      title: "Profile",
                      showBack: true,
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 120,
                      child: ProfileCard(
                        name: model.fullName.isEmpty
                            ? (authUser.displayName ?? 'Guest')
                            : model.fullName,
                        email: model.email,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Account Info',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameCtrl,
                                enabled: _editing && !_saving,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryGreen,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  final name = (v ?? '').trim();
                                  if (name.isEmpty) return 'Full name is required';
                                  if (name.length < 3) return 'Please enter at least 3 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _ReadOnlyField(
                                label: 'Date Joined',
                                value: _formatDate(model.createdAt),
                              ),
                              _ReadOnlyField(
                                label: 'Points',
                                value: model.points.toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _VehiclesSection(uid: uid),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VehiclesSection extends StatelessWidget {
  final String uid;
  const _VehiclesSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    final vehiclesQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: vehiclesQuery.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SectionCard(
            child: Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )),
          );
        }

        final docs = snap.data?.docs ?? [];

        return _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Vehicles',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '${docs.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                Text(
                  'No vehicles yet.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                Column(
                  children: docs.map((d) {
                    final data = d.data();
                    final model = (data['model'] ?? '').toString();
                    final plate = (data['plateNumber'] ?? '').toString();
                    return _VehicleTile(model: model, plateNumber: plate);
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final String model;
  final String plateNumber;
  const _VehicleTile({required this.model, required this.plateNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FutureBuilder<String>(
            future: CarModelService.getImagePathForModel(model),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 70,
                  height: 45,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final imagePath = snapshot.data ?? 'assets/images/car_icon.png';
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  width: 70,
                  height: 45,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/car_icon.png',
                    width: 70,
                    height: 45,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.isEmpty ? 'Unknown model' : model,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  plateNumber.isEmpty ? '—' : plateNumber,
                  style: TextStyle(color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10)],
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: child,
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}