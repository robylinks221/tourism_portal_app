import 'package:flutter/material.dart';

import '../models/admin_provider.dart';
import '../services/admin_provider_service.dart';
import '../services/api_exception.dart';
import '../widgets/premium_states.dart';

class AdminProviderVerificationPage extends StatefulWidget {
  const AdminProviderVerificationPage({super.key});

  @override
  State<AdminProviderVerificationPage> createState() =>
      _AdminProviderVerificationPageState();
}

class _AdminProviderVerificationPageState
    extends State<AdminProviderVerificationPage> {
  late Future<AdminProviderQueue> _queue = AdminProviderService.instance.fetch();
  String _filter = 'pending';

  void _reload() {
    setState(() => _queue = AdminProviderService.instance.fetch());
  }

  Future<void> _review(AdminProvider provider) async {
    var status = provider.verificationStatus;
    if (!const {'pending', 'verified', 'rejected'}.contains(status)) {
      status = 'pending';
    }
    final notes = TextEditingController(text: provider.verificationNotes);
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review ${provider.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w300,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Confirm identity, licences and supplied professional information before approving.',
                ),
                const SizedBox(height: 20),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'pending', label: Text('Pending')),
                    ButtonSegment(value: 'verified', label: Text('Verify')),
                    ButtonSegment(value: 'rejected', label: Text('Reject')),
                  ],
                  selected: {status},
                  onSelectionChanged: (value) =>
                      setSheetState(() => status = value.first),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: notes,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Administrative review notes',
                    hintText: 'Record what was checked and why this decision was made.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Save review decision'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (save != true) {
      notes.dispose();
      return;
    }

    try {
      await AdminProviderService.instance.review(
        providerId: provider.id,
        status: status,
        notes: notes.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider review saved.')),
        );
        _reload();
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      notes.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Verification')),
      body: FutureBuilder<AdminProviderQueue>(
        future: _queue,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _VerificationLoading();
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text('Provider reviews could not be loaded.'),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _reload, child: const Text('Try again')),
                  ],
                ),
              ),
            );
          }

          final queue = snapshot.data!;
          final visible = queue.providers
              .where((provider) => _filter == 'all' || provider.verificationStatus == _filter)
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _queue;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
              children: [
                _VerificationOverview(queue: queue),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'pending', label: Text('Pending')),
                      ButtonSegment(value: 'verified', label: Text('Verified')),
                      ButtonSegment(value: 'rejected', label: Text('Rejected')),
                      ButtonSegment(value: 'all', label: Text('All')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) =>
                        setState(() => _filter = value.first),
                  ),
                ),
                const SizedBox(height: 18),
                if (visible.isEmpty)
                  const _VerificationEmpty()
                else
                  ...visible.map(
                    (provider) => Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: _ProviderReviewCard(
                        provider: provider,
                        onTap: () => _review(provider),
                      ),
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

class _VerificationOverview extends StatelessWidget {
  const _VerificationOverview({required this.queue});
  final AdminProviderQueue queue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12372A), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Colors.white, size: 38),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${queue.pending} pending  •  ${queue.verified} verified  •  ${queue.rejected} rejected',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderReviewCard extends StatelessWidget {
  const _ProviderReviewCard({required this.provider, required this.onTap});
  final AdminProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = switch (provider.verificationStatus) {
      'verified' => const Color(0xFF19734D),
      'rejected' => colors.error,
      _ => const Color(0xFFC47A00),
    };
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(23),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundImage:
                        provider.photoUrl.isEmpty ? null : NetworkImage(provider.photoUrl),
                    child: provider.photoUrl.isEmpty
                        ? Icon(provider.isGuide ? Icons.hiking_rounded : Icons.business_rounded)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(provider.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                        Text('${provider.roleLabel} • ${provider.country}'),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      provider.verificationStatus.isEmpty
                          ? ''
                          : '${provider.verificationStatus[0].toUpperCase()}'
                              '${provider.verificationStatus.substring(1).toLowerCase()}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                '${provider.yearsExperience} yrs experience  •  ${provider.publishedToursCount} tours  •  ${provider.responseTimeLabel} response',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 5),
              Text(
                provider.languages.isEmpty ? 'No languages supplied' : provider.languages.join(' • '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationLoading extends StatelessWidget {
  const _VerificationLoading();
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: 6,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: PremiumSkeleton(
            height: index == 0 ? 110 : 128,
          ),
        ),
      );
}

class _VerificationEmpty extends StatelessWidget {
  const _VerificationEmpty();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(Icons.fact_check_outlined, size: 54),
            SizedBox(height: 10),
            Text('No providers in this review state.'),
          ],
        ),
      );
}
