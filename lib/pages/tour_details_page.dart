import 'package:flutter/material.dart';

import '../models/community.dart';
import '../models/catalog_item.dart';
import '../services/catalog_service.dart';
import 'destination_details_page.dart';
import 'activity_details_page.dart';
import '../models/operator_management.dart';
import '../services/auth_service.dart';
import '../widgets/provider_discovery_sections.dart';
import '../widgets/safari_trail.dart';
import 'tour_booking_page.dart';

class TourDetailsPage extends StatefulWidget {
  const TourDetailsPage({
    super.key,
    required this.tour,
  });

  final OperatorTour tour;

  @override
  State<TourDetailsPage> createState() => _TourDetailsPageState();
}

class _TourDetailsPageState extends State<TourDetailsPage> {
  final PageController _galleryController = PageController();
  int _photoIndex = 0;
  late final Future<TourismCatalog> _catalog = CatalogService.instance.fetchCatalog();

  String _normalized(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _openCatalogItem(String name, {required bool activity}) async {
    try {
      final catalog = await _catalog;
      if (!mounted) return;
      final items = activity ? catalog.activities : catalog.destinations;
      final target = _normalized(name);
      CatalogItem? found;
      for (final item in items) {
        if (_normalized(item.name) == target || _normalized(item.slug) == target) {
          found = item;
          break;
        }
      }
      if (found == null) {
        for (final item in items) {
          final candidate = _normalized(item.name);
          if (target.length >= 5 && (candidate.contains(target) || target.contains(candidate))) {
            found = item;
            break;
          }
        }
      }
      if (found == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Details for $name are not available yet.')));
        return;
      }
      final selected = found;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => activity ? ActivityDetailsPage(item: selected) : DestinationDetailsPage(item: selected),
      ));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to load this page right now.')));
    }
  }

  OperatorTour get tour => widget.tour;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

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

  void _openGallery(BuildContext context, int initial) {
    final controller = PageController(initialPage: initial);
    showDialog<void>(context: context, builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: const Color(0xFF101A19),
      child: SafeArea(child: Stack(children: [
        PageView.builder(controller: controller, itemCount: tour.galleryUrls.length,
          itemBuilder: (_, i) => InteractiveViewer(child: Center(child: Image.network(tour.galleryUrls[i], fit: BoxFit.contain)))),
        Positioned(top: 12, right: 12, child: IconButton.filledTonal(
          onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close_rounded))),
      ])),
    )).then((_) => controller.dispose());
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
      backgroundColor: const Color(0xFFF7F5EF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 460,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF102D2E),
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                PageView.builder(
                  controller: _galleryController,
                  itemCount: tour.galleryUrls.isEmpty ? 1 : tour.galleryUrls.length,
                  onPageChanged: (index) => setState(() => _photoIndex = index),
                  itemBuilder: (context, index) {
                    if (tour.galleryUrls.isEmpty) return Container(
                      color: const Color(0xFF165B5D),
                      child: const Icon(Icons.landscape_rounded, color: Colors.white, size: 70),
                    );
                    return GestureDetector(
                      onTap: () => _openGallery(context, index),
                      child: Image.network(tour.galleryUrls[index], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF165B5D), child: const Icon(Icons.landscape_rounded, color: Colors.white, size: 64))),
                    );
                  },
                ),
                const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x00000000), Color(0xE8122423)],
                  stops: [0, .42, 1],
                )))),
                Positioned(left: 24, right: 24, bottom: 35, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tour.isGuideLed ? 'PRIVATE GUIDE EXPERIENCE' : 'CURATED SAFARI EXPERIENCE',
                      style: const TextStyle(color: Color(0xFFFFC39F), letterSpacing: 2.1, fontSize: 10, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 9),
                    Text(tour.name, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w500, height: 1.1, letterSpacing: -.9)),
                    const SizedBox(height: 15),
                    Text('${tour.days} ${tour.days == 1 ? 'day' : 'days'}  •  ${tour.countryLabel}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    if (tour.galleryUrls.length > 1) ...[
                      const SizedBox(height: 14),
                      Row(children: [
                        for (var i = 0; i < tour.galleryUrls.length; i++) Container(
                          margin: const EdgeInsets.only(right: 6), height: 4, width: i == _photoIndex ? 25 : 9,
                          decoration: BoxDecoration(color: i == _photoIndex ? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(9))),
                        const Spacer(),
                        Text('${_photoIndex + 1} / ${tour.galleryUrls.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ]),
                    ],
                  ],
                )),
                if (tour.galleryUrls.length > 1) Positioned(right: 12, top: 110, child: Column(children: [
                  IconButton.filledTonal(onPressed: _photoIndex > 0 ? () => _galleryController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null, icon: const Icon(Icons.chevron_left_rounded)),
                  IconButton.filledTonal(onPressed: _photoIndex < tour.galleryUrls.length - 1 ? () => _galleryController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null, icon: const Icon(Icons.chevron_right_rounded)),
                ])),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              28,
              20,
              140,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _EditorialIntroduction(tour: tour),
                  const SizedBox(height: 24),
                  if (tour.operatorName.isNotEmpty)
                    _ProviderCard(
                      tour: tour,
                      onTap: () => _openProvider(context),
                    ),
                  if (tour.operatorName.isNotEmpty)
                    const SizedBox(height: 20),

                  _QuickFacts(tour: tour),
                  const SizedBox(height: 24),
                  _LuxuryDivider(),

                  if (tour.overview.trim().isNotEmpty) ...[
                    const SizedBox(height: 27),
                    const _SectionTitle(title: 'Overview'),
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 21, 20, 23),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: const Color(0xFFE7E4DC)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 36, height: 3, decoration: BoxDecoration(
                          color: const Color(0xFFF46627), borderRadius: BorderRadius.circular(8))),
                        const SizedBox(height: 16),
                        Text(tour.overview, style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.72, color: const Color(0xFF344B49), fontSize: 15)),
                      ]),
                    ),
                  ],

                  if (tour.destinationNames.isNotEmpty) ...[
                    const SizedBox(height: 31),
                    const _SectionTitle(title: 'THIS SAFARI TAKES YOU TO'),
                    const SizedBox(height: 8),
                    const Text('Discover the places that shape your journey.',
                      style: TextStyle(color: Color(0xFF667775), fontSize: 13)),
                    const SizedBox(height: 15),
                    ...tour.destinationNames.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ExploreLink(
                        name: entry.value,
                        number: entry.key + 1,
                        icon: Icons.landscape_outlined,
                        subtitle: 'Explore destination',
                        onTap: () => _openCatalogItem(entry.value, activity: false),
                      ),
                    )),
                  ],

                  if (tour.activityNames.isNotEmpty) ...[
                    const SizedBox(height: 29),
                    const _SectionTitle(title: 'Signature Experiences'),
                    const SizedBox(height: 8),
                    const Text('The moments and adventures awaiting you.',
                      style: TextStyle(color: Color(0xFF667775), fontSize: 13)),
                    const SizedBox(height: 15),
                    ...tour.activityNames.map((name) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ExploreLink(
                        name: name,
                        icon: Icons.explore_outlined,
                        subtitle: 'Discover experience',
                        onTap: () => _openCatalogItem(name, activity: true),
                      ),
                    )),
                  ],

                  if (tour.itinerary.isNotEmpty) ...[
                    const SizedBox(height: 32),
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

                  const SizedBox(height: 32),

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
            color: const Color(0xFF102F30),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'PER TRAVELLER',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color: const Color(0xFFB3CAC6),
                        fontSize: 10,
                        letterSpacing: 1,
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
                    minimumSize: const Size(146, 54),
                    backgroundColor: const Color(0xFFF46627),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Reserve Safari',
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
                    color: Colors.white.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Your Safari',
                    style: TextStyle(
                      color: Colors.white,
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

class _EditorialIntroduction extends StatelessWidget {
  const _EditorialIntroduction({required this.tour});
  final OperatorTour tour;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 23, 22, 23),
      decoration: BoxDecoration(
        color: const Color(0xFF153F40),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: const Color(0xFF153F40).withOpacity(.15), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('YOUR SAFARI, BEAUTIFULLY PLANNED', style: TextStyle(color: Color(0xFFFFB98D), fontSize: 10, letterSpacing: 2.1, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(tour.isGuideLed ? 'Discover more, with a local expert.' : 'Discover the extraordinary.',
          style: const TextStyle(color: Colors.white, fontSize: 25, height: 1.16, fontWeight: FontWeight.w400, letterSpacing: -.5)),
        const SizedBox(height: 12),
        Text(tour.destinationNames.isEmpty
          ? 'A thoughtfully planned journey with memorable experiences at every turn.'
          : 'Explore ${tour.destinationNames.take(2).join(' & ')} through a thoughtfully planned journey.',
          style: const TextStyle(color: Color(0xFFD4E0DC), fontSize: 13, height: 1.6)),
        const SizedBox(height: 17),
        Container(width: 52, height: 2, color: const Color(0xFFF46627)),
      ]),
    );
  }
}

class _LuxuryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Container(height: 1, color: const Color(0xFFD9D7CD))),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 13), child: Icon(Icons.auto_awesome_outlined, size: 17, color: Color(0xFFB48A60))),
    Expanded(child: Container(height: 1, color: const Color(0xFFD9D7CD))),
  ]);
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
  const _Tag({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
        text,
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        ),
        const SizedBox(width: 5),
        Icon(Icons.arrow_outward_rounded, size: 13, color: colors.primary),
      ]),
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

class _ExploreLink extends StatelessWidget {
  const _ExploreLink({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.number,
  });
  final String name;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final int? number;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E9E5)),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1ED),
                borderRadius: BorderRadius.circular(15),
              ),
              child: number != null
                  ? Text(number!.toString().padLeft(2, '0'),
                      style: const TextStyle(color: Color(0xFF165B5D),
                        fontWeight: FontWeight.w900, fontSize: 17))
                  : Icon(icon, color: const Color(0xFF165B5D), size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Color(0xFF1B3939),
                fontSize: 15, fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Color(0xFF71807C), fontSize: 11)),
            ])),
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: Color(0xFFF5EAE0), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_outward_rounded, size: 17, color: Color(0xFFB6531F)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final isUpper = title == title.toUpperCase();
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 3, height: 24,
        margin: const EdgeInsets.only(top: 2, right: 12),
        decoration: BoxDecoration(color: const Color(0xFFF46627),
          borderRadius: BorderRadius.circular(3))),
      Expanded(child: Text(title, style: TextStyle(
        color: const Color(0xFF183F40),
        fontWeight: FontWeight.w800,
        fontSize: isUpper ? 17 : 23,
        letterSpacing: isUpper ? 0.7 : -0.45,
        height: 1.2,
      ))),
    ]);
  }
}

String _money(double value) {
  return value.toStringAsFixed(
    value == value.roundToDouble() ? 0 : 2,
  );
}
