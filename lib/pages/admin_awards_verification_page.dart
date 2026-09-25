import 'package:flutter/material.dart';

import '../models/admin_award_nomination.dart';
import '../services/admin_awards_service.dart';
import '../services/auth_service.dart';

class AdminAwardsVerificationPage extends StatefulWidget {
  const AdminAwardsVerificationPage({super.key});

  @override
  State<AdminAwardsVerificationPage> createState() =>
      _AdminAwardsVerificationPageState();
}

class _AdminAwardsVerificationPageState
    extends State<AdminAwardsVerificationPage> {
  static const _green = Color(0xFF165B5D);
  static const _orange = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);

  String _filter = 'pending';
  bool _loading = true;
  String? _error;
  List<AdminAwardNomination> _nominations = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await AdminAwardsService.instance.nominations(
        status: _filter == 'all' ? null : _filter,
      );

      if (!mounted) return;
      setState(() => _nominations = items);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.toString().replaceFirst('ApiException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _photoUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return AuthService.storageUrl(path);
  }

  Future<void> _verify(AdminAwardNomination nomination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Verify nomination?'),
            content: Text(
              '${nomination.guideName} will be marked as verified for '
              '${nomination.categoryName}.\n\n'
              'Verification does not make the guide a finalist. '
              'The nomination will move forward for judging.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Verify'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    await _perform(
      () => AdminAwardsService.instance.verify(nomination.id),
      'Nomination verified.',
    );
  }

  Future<void> _reject(AdminAwardNomination nomination) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Reject nomination'),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'Enter an administrative review note.',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _orange),
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.length >= 3) {
                    Navigator.pop(dialogContext, value);
                  }
                },
                child: const Text('Reject'),
              ),
            ],
          ),
    );

    if (reason == null) return;

    await _perform(
      () => AdminAwardsService.instance.reject(nomination.id, notes: reason),
      'Nomination rejected.',
    );
  }

  Future<void> _perform(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Awards Verification'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.white,
                    size: 34,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tourist Guide Awards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Review nominations before they move to judging.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    ['pending', 'verified', 'rejected', 'all']
                        .map(
                          (value) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                value[0].toUpperCase() + value.substring(1),
                              ),
                              selected: _filter == value,
                              onSelected: (_) {
                                setState(() => _filter = value);
                                _load();
                              },
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _MessageCard(
                icon: Icons.error_outline,
                text: _error!,
                onRefresh: _load,
              )
            else if (_nominations.isEmpty)
              _MessageCard(
                icon: Icons.fact_check_outlined,
                text:
                    'No ${_filter == 'all' ? '' : '$_filter '}nominations found.',
                onRefresh: _load,
              )
            else
              ..._nominations.map(_nominationCard),
          ],
        ),
      ),
    );
  }

  Widget _nominationCard(AdminAwardNomination nomination) {
    final image = _photoUrl(nomination.profilePhoto);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: _green.withValues(alpha: .10),
                backgroundImage: image == null ? null : NetworkImage(image),
                child:
                    image == null
                        ? const Icon(Icons.person_outline, color: _green)
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nomination.guideName,
                            style: const TextStyle(
                              color: _green,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (nomination.verifiedGuide) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified, color: _green, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nomination.categoryName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${nomination.year} Awards • '
                      '${nomination.status.toUpperCase()}',
                      style: const TextStyle(
                        color: Color(0xFF778078),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((nomination.company ?? '').isNotEmpty ||
              (nomination.country ?? '').isNotEmpty ||
              nomination.yearsExperience > 0) ...[
            const SizedBox(height: 13),
            Text(
              [
                if ((nomination.company ?? '').isNotEmpty) nomination.company!,
                if ((nomination.country ?? '').isNotEmpty) nomination.country!,
                if (nomination.yearsExperience > 0)
                  '${nomination.yearsExperience} years experience',
              ].join(' • '),
              style: const TextStyle(color: Color(0xFF606A63), height: 1.4),
            ),
          ],
          if (nomination.ratings.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Nomination assessment',
              style: TextStyle(color: _green, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            ...nomination.ratings.map(
              (rating) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rating.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${rating.rating}/5',
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if ((nomination.supportingComment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Supporting comment',
              style: TextStyle(color: _green, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              nomination.supportingComment!,
              style: const TextStyle(height: 1.45),
            ),
          ],
          if ((nomination.adminNotes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Admin note: ${nomination.adminNotes!}',
              style: const TextStyle(
                color: Color(0xFF778078),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (nomination.status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(nomination),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _verify(nomination),
                    icon: const Icon(Icons.check),
                    label: const Text('Verify'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.text,
    required this.onRefresh,
  });

  final IconData icon;
  final String text;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF9EAAA1)),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
