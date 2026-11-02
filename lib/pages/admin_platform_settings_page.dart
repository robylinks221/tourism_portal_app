import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/admin_platform_settings_service.dart';

const _teal = Color(0xFF165B5D);
const _deep = Color(0xFF103F42);
const _orange = Color(0xFFF46627);
const _cream = Color(0xFFF4EEE1);
const _ink = Color(0xFF243D3F);
const _muted = Color(0xFF718082);

class AdminPlatformSettingsPage extends StatefulWidget {
  const AdminPlatformSettingsPage({super.key});
  @override
  State<AdminPlatformSettingsPage> createState() => _AdminPlatformSettingsPageState();
}

class _AdminPlatformSettingsPageState extends State<AdminPlatformSettingsPage> {
  final api = AdminPlatformSettingsService();
  Map<String, Map<String, dynamic>> sections = {};
  bool loading = true;
  String? error;
  @override
  void initState() { super.initState(); refresh(); }
  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await api.load();
      final raw = Map<String, dynamic>.from(result['settings'] as Map);
      if (!mounted) return;
      setState(() {
        sections = raw.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
        loading = false;
      });
    } catch (e) { if (mounted) setState(() { error = e.toString(); loading = false; }); }
  }
  Future<void> open(String key, String title) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => _Editor(
      section: key, title: title, initial: sections[key] ?? {}, api: api,
    )));
    if (mounted) refresh();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cream,
    appBar: AppBar(backgroundColor: _teal, foregroundColor: Colors.white,
      title: const Text('Platform Settings', style: TextStyle(fontWeight: FontWeight.w700))),
    body: loading ? const Center(child: CircularProgressIndicator(color: _teal)) : error != null
      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 42, color: _teal), const SizedBox(height: 14),
          Text(error!, textAlign: TextAlign.center), const SizedBox(height: 16),
          FilledButton(onPressed: refresh, child: const Text('Try again')),
        ])))
      : RefreshIndicator(onRefresh: refresh, child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720), child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 40), children: [
            const Text('Manage your platform', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: _deep)),
            const SizedBox(height: 5), const Text('Your brand, people and operational preferences.', style: TextStyle(color: _muted)),
            const SizedBox(height: 22),
            _menu(Icons.business_rounded, 'General Settings', 'Identity, logo and contact information', () => open('general', 'General Settings')),
            _menu(Icons.palette_outlined, 'Appearance', 'Brand palette and display preferences', () => open('appearance', 'Appearance')),
            _menu(Icons.people_outline_rounded, 'User Management', 'Accounts and administrator access', () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => _UsersPage(api: api)))),
            _menu(Icons.verified_user_outlined, 'Provider Management', 'Review and verification preferences', () => open('provider', 'Provider Management')),
            const SizedBox(height: 16),
            const Text('Some preferences are saved centrally but require further integration before changing the public app or verification rules.', style: TextStyle(fontSize: 12, color: _muted, height: 1.5)),
          ])))),
  );
  Widget _menu(IconData icon, String title, String subtitle, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 11), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(18),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E8E2))),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: _teal.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: _teal)),
          const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
          ])), const Icon(Icons.chevron_right_rounded, color: _muted),
        ])))));
}

class _Editor extends StatefulWidget {
  const _Editor({required this.section, required this.title, required this.initial, required this.api});
  final String section, title;
  final Map<String, dynamic> initial;
  final AdminPlatformSettingsService api;
  @override State<_Editor> createState() => _EditorState();
}
class _EditorState extends State<_Editor> {
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  late Map<String, dynamic> data;
  bool busy = false;
  String? logo;
  @override void initState() { super.initState(); data = Map.of(widget.initial); logo = (data['logo_url'] ?? '').toString(); }
  @override void dispose() { for (final c in fields.values) { c.dispose(); } super.dispose(); }
  Widget heading(String title, String subtitle, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 20, 2, 13), child: Row(children: [
      Icon(icon, color: _teal, size: 20), const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _deep)),
        const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
      ])),
    ]));
  Widget panel(List<Widget> children) => Container(
    padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE9E8E2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  Widget field(String key, String label, {TextInputType? type, bool required = false, int maxLines = 1, String? hint}) {
    final controller = fields.putIfAbsent(key, () => TextEditingController(text: (data[key] ?? '').toString()));
    return Padding(padding: const EdgeInsets.only(bottom: 13), child: TextFormField(
      controller: controller, enabled: !busy, keyboardType: type, maxLines: maxLines,
      onChanged: (value) => data[key] = value.trim(),
      validator: (v) {
        final value = (v ?? '').trim();
        if (required && value.isEmpty) return '$label is required';
        if (key == 'support_email' && value.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) return 'Enter a valid email address';
        if (key == 'website' && value.isNotEmpty && !(Uri.tryParse(value)?.hasAbsolutePath ?? false) && !(Uri.tryParse(value)?.hasAuthority ?? false)) return 'Enter a complete website URL';
        if (key.endsWith('_color') && !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) return 'Use a 6-digit HEX colour, e.g. #165B5D';
        return null;
      },
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
      decoration: InputDecoration(labelText: label, hintText: hint, floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        filled: true, fillColor: const Color(0xFFFAFAF8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFE4E7E3)), borderRadius: BorderRadius.circular(13)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _teal, width: 1.5), borderRadius: BorderRadius.circular(13)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ));
  }
  Widget toggle(String key, String label, String description) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero, activeTrackColor: _teal,
    title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
    subtitle: Text(description, style: const TextStyle(fontSize: 12, color: _muted)),
    value: data[key] == true, onChanged: busy ? null : (v) => setState(() => data[key] = v));
  Color parseColor(String key, Color fallback) {
    final hex = (fields[key]?.text ?? data[key] ?? '').toString().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return fallback;
    return Color(int.parse('FF$hex', radix: 16));
  }
  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    try {
      for (final entry in fields.entries) { data[entry.key] = entry.value.text.trim(); }
      await widget.api.save(widget.section, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved successfully'), behavior: SnackBarBehavior.floating));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to save: $e'), behavior: SnackBarBehavior.floating));
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> uploadLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 1600);
    if (picked == null || !mounted) return;
    setState(() => busy = true);
    try {
      final uploaded = await widget.api.uploadLogo(picked.path);
      if (!mounted) return;
      setState(() { logo = uploaded; data['logo_url'] = uploaded; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo uploaded successfully')));
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logo upload failed: $e'))); }
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) {
    final general = widget.section == 'general';
    final appearance = widget.section == 'appearance';
    return Scaffold(backgroundColor: _cream,
      appBar: AppBar(backgroundColor: _teal, foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      bottomNavigationBar: SafeArea(top: false, child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEAEAE5)))),
        child: FilledButton.icon(onPressed: busy ? null : save, icon: Icon(busy ? Icons.hourglass_top : Icons.check_rounded),
          label: Text(busy ? 'Saving changes...' : 'Save Changes'),
          style: FilledButton.styleFrom(backgroundColor: _teal, minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))))),
      body: Form(key: formKey, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 15, 18, 26), children: [
          if (general) ...[
            heading('Brand identity', 'How your platform is presented', Icons.auto_awesome_outlined),
            panel([
              Container(height: 120, decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(14)),
                child: Center(child: (logo ?? '').isNotEmpty
                  ? FutureBuilder<String>(future: widget.api.displayLogoUrl(logo!), builder: (context, snapshot) {
                      final url = snapshot.data;
                      return url == null ? const CircularProgressIndicator(color: _teal)
                        : Image.network(url, height: 92, width: 240, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.broken_image_outlined, color: _muted), Text('Logo preview unavailable', style: TextStyle(color: _muted, fontSize: 12))]));
                    })
                  : const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.landscape_rounded, color: _teal, size: 38), SizedBox(height: 7), Text('No logo uploaded', style: TextStyle(color: _muted, fontSize: 12))]))),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: busy ? null : uploadLogo, icon: const Icon(Icons.upload_rounded),
                label: Text((logo ?? '').isEmpty ? 'Upload App Logo' : 'Change App Logo'),
                style: OutlinedButton.styleFrom(foregroundColor: _teal, side: const BorderSide(color: _teal), minimumSize: const Size.fromHeight(47))),
              const SizedBox(height: 8),
              const Text('PNG, JPG or WebP · Maximum 2 MB', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: _muted)),
              const SizedBox(height: 16), field('app_name', 'App name', required: true),
            ]),
            heading('Contact information', 'Official contact details for the platform', Icons.contact_mail_outlined),
            panel([
              field('support_email', 'Support email', type: TextInputType.emailAddress),
              field('phone', 'Contact phone', type: TextInputType.phone),
              field('whatsapp', 'WhatsApp number', type: TextInputType.phone),
              field('website', 'Website URL', type: TextInputType.url, hint: 'https://example.com'),
              field('address', 'Business address', maxLines: 2),
            ]),
          ] else if (appearance) ...[
            heading('Brand palette', 'Edit the saved colours and preview them', Icons.palette_outlined),
            panel([
              Container(height: 88, decoration: BoxDecoration(color: parseColor('background_color', _cream), borderRadius: BorderRadius.circular(13)),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: parseColor('primary_color', _teal), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.landscape, color: Colors.white)),
                  const SizedBox(width: 10), const Text('Tourism Portal', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(width: 10), Container(width: 9, height: 9, decoration: BoxDecoration(color: parseColor('secondary_color', _orange), shape: BoxShape.circle)),
                ]))),
              const SizedBox(height: 16),
              field('primary_color', 'Primary colour (HEX)', required: true),
              field('secondary_color', 'Accent colour (HEX)', required: true),
              field('background_color', 'Background colour (HEX)', required: true),
              const SizedBox(height: 3),
              const Text('Display preference', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(value: ['system','light','dark'].contains(data['display_mode']) ? data['display_mode'].toString() : 'system',
                decoration: InputDecoration(filled: true, fillColor: const Color(0xFFFAFAF8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(13))),
                items: const [DropdownMenuItem(value: 'system', child: Text('Follow device')), DropdownMenuItem(value: 'light', child: Text('Light')), DropdownMenuItem(value: 'dark', child: Text('Dark'))],
                onChanged: busy ? null : (v) { if (v != null) setState(() => data['display_mode'] = v); }),
            ]),
            const SizedBox(height: 15), const Text('These preferences save to the server. Applying them across all app screens is a separate integration step.', style: TextStyle(color: _muted, fontSize: 12, height: 1.5)),
          ] else ...[
            heading('Verification preferences', 'Saved policy for guides and tour operators', Icons.verified_user_outlined),
            panel([
              toggle('require_verification', 'Require administrator verification', 'Providers should be reviewed by an administrator.'),
              const Divider(height: 20),
              toggle('require_document_review', 'Require document review', 'Review supporting documentation during verification.'),
              const SizedBox(height: 12), field('verification_notes', 'Internal policy notes', maxLines: 4),
            ]),
            const SizedBox(height: 15), const Text('Existing provider approval rules are unchanged until these preferences are connected to the verification backend.', style: TextStyle(color: _muted, fontSize: 12, height: 1.5)),
          ],
        ])))),
    );
  }
}

class _UsersPage extends StatefulWidget {
  const _UsersPage({required this.api});
  final AdminPlatformSettingsService api;
  @override State<_UsersPage> createState() => _UsersPageState();
}
class _UsersPageState extends State<_UsersPage> {
  late Future<List<dynamic>> future;
  @override void initState() { super.initState(); reload(); }
  void reload() => setState(() => future = widget.api.users());
  Future<void> add() async {
    final name = TextEditingController(), email = TextEditingController(), password = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('New administrator'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address')),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password (12+ characters)')),
          const SizedBox(height: 10), const Text('Requires uppercase, lowercase and a number.', style: TextStyle(fontSize: 12, color: _muted)),
        ])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Create'))]));
      if (confirmed != true) return;
      if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.length < 12) {
        throw Exception('Enter a name, email and password of at least 12 characters.');
      }
      await widget.api.addAdmin(name.text.trim(), email.text.trim(), password.text);
      if (mounted) { reload(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrator created'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to create administrator: $e'))); }
    finally { name.dispose(); email.dispose(); password.dispose(); }
  }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: _cream,
    appBar: AppBar(backgroundColor: _teal, foregroundColor: Colors.white, title: const Text('User Management')),
    floatingActionButton: FloatingActionButton.extended(backgroundColor: _orange, foregroundColor: Colors.white,
      onPressed: add, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Add administrator')),
    body: FutureBuilder<List<dynamic>>(future: future, builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Could not load accounts: ${snapshot.error}', textAlign: TextAlign.center), const SizedBox(height: 12),
        FilledButton(onPressed: reload, child: const Text('Retry')),
      ])));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _teal));
      final users = snapshot.data!;
      return RefreshIndicator(onRefresh: () async { reload(); await future; }, child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100), children: [
          Text('${users.length} most recent accounts', style: const TextStyle(fontSize: 18, color: _deep, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6), const Text('Showing up to 30 accounts. Role editing is not yet available.', style: TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 14),
          for (final raw in users) Builder(builder: (context) {
            final user = Map<String, dynamic>.from(raw as Map);
            return Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 9), child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              leading: CircleAvatar(backgroundColor: _teal.withValues(alpha: .1), child: const Icon(Icons.person_outline, color: _teal)),
              title: Text((user['name'] ?? 'Unnamed').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
              subtitle: Text((user['email'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text((user['role'] ?? '').toString(), style: const TextStyle(fontSize: 11, color: _teal, fontWeight: FontWeight.w700)),
            ));
          }),
        ]));
    }),
  );
}
