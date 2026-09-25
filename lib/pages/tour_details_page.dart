import 'package:flutter/material.dart';

import '../models/community.dart';
import '../models/operator_management.dart';
import '../services/auth_service.dart';
import '../widgets/provider_discovery_sections.dart';
import '../widgets/safari_trail.dart';
import 'tour_booking_page.dart';

class TourDetailsPage extends StatelessWidget {
  const TourDetailsPage({
    super.key,
    required this.tour,
  });

  final OperatorTour tour;

  Future<void> _book(BuildContext context) async {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in as a tourist to book this safari.',
          ),
        ),
      );
      return;
    }

    if (user.id == tour.operatorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot book your own safari.',
          ),
        ),
      );
      return;
    }

    if (user.role != 'tourist') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Published safaris can be booked from a tourist account.',
          ),
        ),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TourBookingPage(tour: tour),
      ),
    );
  }

  void _openProvider(BuildContext context) {
    if (tour.operatorId <= 0) return;

    final member = CommunityMember(
      id: tour.operatorId,
      name: tour.operatorName,
      role: tour.providerRole,
      profilePhoto: tour.operatorLogo,
      location: tour.operatorLocation,
      biography: tour.operatorBiography,
      ratingAverage: tour.operatorRatingAverage,
      ratingCount: tour.operatorRatingCount,
      joinedAt: tour.operatorJoinedAt,
    );

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProviderProfilePage(member: member),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentUser = AuthService.instance.currentUser;
    final isOwner =
        currentUser != null &&
        tour.operatorId > 0 &&
        currentUser.id == tour.operatorId;
    final canShowBook =
        !isOwner &&
        (currentUser == null || currentUser.role == 'tourist');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 315,
            pinned: true,
            stretch: true,
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  tour.imageUrl.isEmpty
                      ? Container(
                          color: colors.primaryContainer,
                          child: const Icon(
                            Icons.landscape_rounded,
                            size: 72,
                          ),
                        )
                      : Image.network(
                          tour.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colors.primaryContainer,
                            child: const Icon(
                              Icons.landscape_rounded,
                              size: 72,
                            ),
                          ),
                        ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Color(0xB8000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              140,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  if (tour.operatorName.isNotEmpty)
                    _ProviderCard(
                      tour: tour,
                      onTap: () => _openProvider(context),
                    ),
                  if (tour.operatorName.isNotEmpty)
                    const SizedBox(height: 20),

                  _QuickFacts(tour: tour),

                  if (tour.destinationNames.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    const _SectionTitle(title: 'Destinations'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tour.destinationNames
                          .map((name) => _Tag(text: name))
                          .toList(),
                    ),
                  ],

                  if (tour.activityNames.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    const _SectionTitle(
                      title: 'Safari Activities',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tour.activityNames
                          .map((name) => _Tag(text: name))
                          .toList(),
                    ),
                  ],

                  if (tour.overview.trim().isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'About This Safari',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tour.overview,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.62,
                        color: colors.onSurface.withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                  ],

                  if (tour.itinerary.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Safari Itinerary',
                    ),
                    const SizedBox(height: 12),
                    SafariTrail(stops: tour.itinerary),
                  ],

                  if (tour.inclusions.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: "What's Included",
                    ),
                    const SizedBox(height: 12),
                    _PackageList(
                      items: tour.inclusions,
                      included: true,
                    ),
                  ],

                  if (tour.exclusions.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: "What's Not Included",
                    ),
                    const SizedBox(height: 12),
                    _PackageList(
                      items: tour.exclusions,
                      included: false,
                    ),
                  ],

                  const SizedBox(height: 26),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: 0.06,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isOwner
                                ? 'This is your published safari. Manage pricing, dates and content from your provider dashboard.'
                                : 'Your booking request is sent directly to the safari provider. The provider reviews and confirms the booking before the trip.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tour.currency} ${_money(tour.price)}',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'per traveller',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (canShowBook) ...[
                const SizedBox(width: 14),
                FilledButton(
                  onPressed:
                      tour.isActive ? () => _book(context) : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(156, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Book Safari',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ] else if (isOwner) ...[
                const SizedBox(width: 14),
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Your Safari',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.tour,
    required this.onTap,
  });

  final OperatorTour tour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = tour.isGuideLed ? 'Guided by' : 'Offered by';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.primaryContainer,
                backgroundImage:
                    tour.operatorLogoUrl.isNotEmpty
                        ? NetworkImage(tour.operatorLogoUrl)
                        : null,
                child: tour.operatorLogoUrl.isEmpty
                    ? Text(
                        tour.operatorName.isEmpty
                            ? 'S'
                            : tour.operatorName[0]
                                .toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      tour.operatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (tour.operatorLocation.isNotEmpty)
                      Text(
                        tour.operatorLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (tour.operatorRatingCount > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Color(0xFFFFA000),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      tour.operatorRatingAverage
                          .toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 5),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickFacts extends StatelessWidget {
  const _QuickFacts({required this.tour});

  final OperatorTour tour;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Fact(
            icon: Icons.schedule_rounded,
            value: '${tour.days}',
            label: tour.days == 1 ? 'Day' : 'Days',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Fact(
            icon: Icons.place_outlined,
            value: '${tour.destinationNames.length}',
            label: 'Destinations',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Fact(
            icon: Icons.explore_outlined,
            value: '${tour.activityNames.length}',
            label: 'Activities',
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _PackageList extends StatelessWidget {
  const _PackageList({
    required this.items,
    required this.included,
  });

  final List<String> items;
  final bool included;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: included
            ? colors.primary.withValues(alpha: 0.055)
            : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: included
              ? colors.primary.withValues(alpha: 0.14)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          for (var index = 0;
              index < items.length;
              index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: included
                        ? colors.primary.withValues(alpha: 0.11)
                        : colors.error.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    included
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 16,
                    color: included
                        ? colors.primary
                        : colors.error,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      items[index],
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (index != items.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

String _money(double value) {
  return value.toStringAsFixed(
    value == value.roundToDouble() ? 0 : 2,
  );
}
