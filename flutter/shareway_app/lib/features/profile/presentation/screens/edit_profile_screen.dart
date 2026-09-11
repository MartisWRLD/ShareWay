import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/user_profile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _bioCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '3');
  final Set<String> _features = {};
  File? _pickedImage;
  bool _initialized = false;
  bool _saving = false;

  void _initFromProfile(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _bioCtrl.text = profile.bio ?? '';
    if (profile.vehicle != null) {
      _makeCtrl.text = profile.vehicle!.make;
      _modelCtrl.text = profile.vehicle!.model;
      _colorCtrl.text = profile.vehicle!.color;
      _seatsCtrl.text = profile.vehicle!.seatsAvailable.toString();
      _features.addAll(profile.vehicle!.features);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _save(UserProfile profile) async {
    setState(() => _saving = true);
    final profileRepo = ref.read(profileRepositoryProvider);

    String? photoUrl = profile.photoUrl;
    if (_pickedImage != null) {
      photoUrl = await profileRepo.uploadProfileImage(profile.uid, _pickedImage!);
    }

    final changes = <String, dynamic>{
      'bio': _bioCtrl.text.trim(),
      if (photoUrl != null) 'photoUrl': photoUrl,
    };

    if (profile.role == UserRole.driver) {
      changes['vehicle'] = VehicleInfo(
        make: _makeCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        seatsAvailable: int.tryParse(_seatsCtrl.text) ?? 1,
        features: _features.toList(),
      ).toMap();
    }

    await profileRepo.updateProfile(profile.uid, changes);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil bearbeiten')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const SizedBox();
          _initFromProfile(profile);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (profile.photoUrl != null
                            ? NetworkImage(profile.photoUrl!)
                            : null) as ImageProvider?,
                    child: (_pickedImage == null && profile.photoUrl == null)
                        ? const Icon(Icons.camera_alt_outlined)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Biografie'),
              ),
              if (profile.role == UserRole.driver) ...[
                const SizedBox(height: 24),
                Text('Fahrzeug', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _makeCtrl,
                      decoration: const InputDecoration(labelText: 'Marke'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _modelCtrl,
                      decoration: const InputDecoration(labelText: 'Modell'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _colorCtrl,
                      decoration: const InputDecoration(labelText: 'Farbe'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _seatsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Freie Plätze'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: const [
                    'Klimaanlage', 'Nichtraucher', 'Musik ok', 'Haustiere erlaubt'
                  ].map((f) {
                    final selected = _features.contains(f);
                    return FilterChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (v) => setState(() => v ? _features.add(f) : _features.remove(f)),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : () => _save(profile),
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Speichern'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }
}
