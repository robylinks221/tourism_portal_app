import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/admin_customization_service.dart';

const _primary = Color(0xFF165B5D);
const _accent = Color(0xFFF46627);

class AdminMyProfilePage extends StatefulWidget {
  const AdminMyProfilePage({super.key});
  @override
  State<AdminMyProfilePage> createState() => _AdminMyProfilePageState();
}

class _AdminMyProfilePageState extends State<AdminMyProfilePage> {
  Map<String, dynamic> profile = {};
  bool busy = true;
  String? error;
  final name = TextEditingController();
  final email = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { name.dispose(); email.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { busy = true; error = null; });
    try {
      final data = await AdminCustomizationService.instance.profile();
      if (!mounted) return;
      _apply(data);
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  void _apply(Map<String, dynamic> data) {
    final p = Map<String, dynamic>.from(data['profile'] as Map);
    setState(() { profile = p; name.text = p['name']?.toString() ?? '';
      email.text = p['email']?.toString() ?? ''; });
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty || !email.text.contains('@')) { _message('Enter a valid name and email.'); return; }
    String enteredPassword = '';
    final current = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirm profile update'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Enter your current password if required, especially when changing your email.'),
        TextField(onChanged: (value) => enteredPassword = value, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, enteredPassword), child: const Text('Save'))],
    ));
    if (!mounted || current == null) return;
    setState(() => busy = true);
    try {
      final data = await AdminCustomizationService.instance.updateProfile(name: name.text.trim(),
        email: email.text.trim(), currentPassword: current);
      if (!mounted) return;
      _apply(data);
      _message(data['message']?.toString() ?? 'Profile updated.');
      if (data['reauthenticate'] == true) _message('Please log out and sign in again before making further changes.');
    } catch (e) { _message(e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _photo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) { _message('Photo must be 5 MB or smaller.'); return; }
    setState(() => busy = true);
    try {
      final data = await AdminCustomizationService.instance.uploadPhoto(bytes, file.name);
      if (!mounted) return;
      _apply(data);
      _message('Profile picture updated.');
    } catch (e) { _message(e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _password() async {
    String enteredCurrent = '';
    String enteredNew = '';
    String enteredConfirmation = '';
    final approved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Change password'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(onChanged: (value) => enteredCurrent = value, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
        TextField(onChanged: (value) => enteredNew = value, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
        TextField(onChanged: (value) => enteredConfirmation = value, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update password'))],
    ));
    if (!mounted || approved != true) return;
    final current = enteredCurrent;
    final password = enteredNew;
    final confirmation = enteredConfirmation;
    if (current.isEmpty || password.length < 8 || password != confirmation) {
      _message('Enter your current password and matching new passwords (at least 8 characters).'); return;
    }
    setState(() => busy = true);
    try {
      final data = await AdminCustomizationService.instance.changePassword(
        current: current, password: password, confirmation: confirmation);
      _message(data['message']?.toString() ?? 'Password changed. Please sign in again.');
      // API revokes sessions. Navigate to login using the app's existing logout flow.
    } catch (e) { _message(e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final photo = profile['photo_url']?.toString();
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEE1),
      appBar: AppBar(title: const Text('My Profile'), backgroundColor: _primary,
        foregroundColor: Colors.white, actions: [IconButton(onPressed: busy ? null : _load,
          icon: const Icon(Icons.refresh))]),
      body: busy && profile.isEmpty ? const Center(child: CircularProgressIndicator()) :
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 650),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _primary,
            borderRadius: BorderRadius.circular(22)), child: Column(children: [
              CircleAvatar(radius: 43, backgroundColor: Colors.white,
                backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo == null || photo.isEmpty ? const Icon(Icons.person, size: 44, color: _primary) : null),
              const SizedBox(height: 10),
              Text(profile['name']?.toString() ?? 'Administrator', style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 20)),
              Text(profile['email']?.toString() ?? '', style: const TextStyle(color: Colors.white70)),
              TextButton.icon(onPressed: busy ? null : _photo, icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Change profile photo'), style: TextButton.styleFrom(foregroundColor: Colors.white)),
            ])),
          const SizedBox(height: 24),
          const Text('Account details', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: busy ? null : _save, icon: const Icon(Icons.save_outlined),
            label: const Text('Save profile'), style: FilledButton.styleFrom(backgroundColor: _primary)),
          const SizedBox(height: 18),
          OutlinedButton.icon(onPressed: busy ? null : _password, icon: const Icon(Icons.lock_outline),
            label: const Text('Change password'), style: OutlinedButton.styleFrom(foregroundColor: _accent)),
          const SizedBox(height: 12),
          const Text('Changing your password revokes existing sessions. Sign in again after the update.',
            style: TextStyle(color: Colors.black54, fontSize: 12)),
          if (busy) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
        ]))),
    );
  }
}
