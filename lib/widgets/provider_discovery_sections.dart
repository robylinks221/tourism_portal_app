import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/supported_countries.dart';
import '../config/world_countries.dart';
import '../models/catalog_item.dart';
import '../models/community.dart';
import '../models/discovery_item.dart';
import '../models/operator_management.dart';
import '../pages/activity_details_page.dart';
import '../pages/destination_details_page.dart';
import '../pages/community_page.dart';
import '../pages/car_hire_page.dart';
import '../services/operator_offerings_service.dart';
import '../pages/tour_details_page.dart';
import '../pages/all_tourist_guides_page.dart';
import '../pages/all_tour_operators_page.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../services/community_service.dart';
import '../services/discovery_store.dart';
import '../utils/text_case.dart';
import 'app_ui.dart';
import 'guest_access_sheet.dart';
import 'premium_states.dart';

const double premiumProviderCardHeight = 224;

const double _premiumProviderCardWidth = 312;
const Color _providerForest = Color(0xFF0B2D1D);
const Color _providerForestDeep = Color(0xFF061B12);
const Color _providerGold = Color(0xFFD7A842);
const Color _providerOrange = Color(0xFFC44D12);

class ProviderDiscoverySections extends StatefulWidget {
  const ProviderDiscoverySections({
    super.key,
    this.enabled = true,
    this.isGuest = false,
    this.countryName,
  });

  final bool enabled;
  final bool isGuest;
  final String? countryName;

  @override
  State<ProviderDiscoverySections> createState() =>
      _ProviderDiscoverySectionsState();
}

class _ProviderDiscoverySectionsState extends State<ProviderDiscoverySections> {
  late Future<FeaturedProviders> _providers;
  bool _showOperators = false;

  @override
  void initState() {
    super.initState();
    _providers = _loadProviders();
  }

  @override
  void didUpdateWidget(covariant ProviderDiscoverySections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.isGuest != widget.isGuest) {
      _providers = _loadProviders();
    }
  }

  Future<FeaturedProviders> _loadProviders() {
    if (!widget.enabled) {
      return Future.value(const FeaturedProviders(guides: [], operators: []));
    }

    return widget.isGuest
        ? CommunityService.instance.fetchGuestProviders()
        : CommunityService.instance.fetchFeaturedProviders();
  }

  void _reload() {
    setState(() {
      _providers = _loadProviders();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return FutureBuilder<FeaturedProviders>(
      future: _providers,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingProviders();
        }
        if (snapshot.hasError) {
          return _ProviderLoadError(onRetry: _reload);
        }

        final rawProviders = snapshot.data!;
        final country = widget.countryName?.trim();
        final providers = country == null || country.isEmpty
            ? rawProviders
            : FeaturedProviders(
                guides: rawProviders.guides
                    .where((member) => member.operatesIn(country))
                    .toList(),
                operators: rawProviders.operators
                    .where((member) => member.operatesIn(country))
                    .toList(),
              );
        if (providers.guides.isEmpty && providers.operators.isEmpty) {
          return const AppStatePanel(
            title: 'No providers are available yet',
            message:
                'New tourist guides and tour operators will appear here after verification.',
            kind: AppStateKind.empty,
          );
        }

        final hasGuides = providers.guides.isNotEmpty;
        final hasOperators = providers.operators.isNotEmpty;

        final showOperators =
            _showOperators ? hasOperators : !hasGuides && hasOperators;

        final visibleMembers =
            showOperators ? providers.operators : providers.guides;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _LocalExpertsHeader(),
            const SizedBox(height: 18),
            _ProviderTypeTabs(
              showOperators: showOperators,
              guideCount: providers.guides.length,
              operatorCount: providers.operators.length,
              hasGuides: hasGuides,
              hasOperators: hasOperators,
              onChanged: (value) {
                setState(() {
                  _showOperators = value;
                });
              },
            ),
            const SizedBox(height: 18),
            _ProviderCarousel(
              members: visibleMembers,
              operatorStyle: showOperators,
              isGuest: widget.isGuest,
            ),
          ],
        );
      },
    );
  }
}

class _LocalExpertsHeader extends StatelessWidget {
  const _LocalExpertsHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Meet Local Safari Experts',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF165B5D),
                fontWeight: FontWeight.w800,
                height: 1.08,
                letterSpacing: -.55,
              ),
            ),
            const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFFD7A842),
              size: 25,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Knowledgeable. Verified. Trusted.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withOpacity(.62),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProviderTypeTabs extends StatelessWidget {
  const _ProviderTypeTabs({
    required this.showOperators,
    required this.guideCount,
    required this.operatorCount,
    required this.hasGuides,
    required this.hasOperators,
    required this.onChanged,
  });

  final bool showOperators;
  final int guideCount;
  final int operatorCount;
  final bool hasGuides;
  final bool hasOperators;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget tab({
      required String label,
      required bool selected,
      required bool enabled,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Opacity(
          opacity: enabled ? 1 : .46,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? const Color(0xFF165B5D)
                          : Colors.white.withOpacity(.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        selected
                            ? const Color(0xFF165B5D)
                            : colors.outlineVariant.withOpacity(.75),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(selected ? .10 : .045),
                      blurRadius: selected ? 14 : 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color:
                              selected
                                  ? Colors.white
                                  : colors.onSurface.withOpacity(.86),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final activeLabel = showOperators ? 'operators' : 'guides';

    return Column(
      children: [
        Row(
          children: [
            tab(
              label: 'Tourist Guides',
              selected: !showOperators,
              enabled: hasGuides,
              onTap: () => onChanged(false),
            ),
            const SizedBox(width: 10),
            tab(
              label: 'Tour Operators',
              selected: showOperators,
              enabled: hasOperators,
              onTap: () => onChanged(true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '$guideCount ${guideCount == 1 ? 'Tourist Guide' : 'Tourist Guides'}  •  '
                '$operatorCount ${operatorCount == 1 ? 'Tour Operator' : 'Tour Operators'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(.62),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => showOperators
                        ? const AllTourOperatorsPage()
                        : const AllTouristGuidesPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    showOperators
                        ? const Color(0xFF9A4B1D)
                        : const Color(0xFF165B5D),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              label: Text(
                'View all $activeLabel',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _openProviderProfile(
  BuildContext context,
  CommunityMember member, {
  bool isGuest = false,
}) async {
  if (isGuest) {
    await showGuestAccessSheet(
      context,
      title: 'View the full profile',
      message:
          'Login or create a free account to view the full profile, contact this provider, save tours and make bookings.',
    );
    return;
  }

  await DiscoveryStore.instance.recordView(
    DiscoveryRecord.fromProvider(member),
  );

  if (!context.mounted) {
    return;
  }

  Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => ProviderProfilePage(member: member)),
  );
}

class _ProviderCarousel extends StatefulWidget {
  const _ProviderCarousel({
    required this.members,
    required this.operatorStyle,
    required this.isGuest,
  });

  final List<CommunityMember> members;
  final bool operatorStyle;
  final bool isGuest;

  @override
  State<_ProviderCarousel> createState() => _ProviderCarouselState();
}

class _ProviderCarouselState extends State<_ProviderCarousel> {
  late final PageController _controller = PageController(viewportFraction: .88);

  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ProviderCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.operatorStyle != widget.operatorStyle ||
        oldWidget.members.length != widget.members.length) {
      _current = 0;

      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.members.length;

    return Column(
      children: [
        SizedBox(
          height: premiumProviderCardHeight,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            physics: const BouncingScrollPhysics(),
            itemCount: itemCount,
            onPageChanged: (index) {
              setState(() {
                _current = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == itemCount - 1 ? 0 : 13,
                  left: index == 0 ? 0 : 1,
                  bottom: 12,
                ),
                child: PremiumProviderCard(
                  member: widget.members[index],
                  isGuest: widget.isGuest,
                ),
              );
            },
          ),
        ),
        if (itemCount > 1) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(itemCount.clamp(0, 6), (index) {
              final selected = index == _current.clamp(0, 5);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 9 : 7,
                height: selected ? 9 : 7,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? const Color(0xFF0F4B32)
                          : const Color(0xFFD5D5D2),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class PremiumProviderCard extends StatelessWidget {
  const PremiumProviderCard({
    super.key,
    required this.member,
    this.isGuest = false,
    this.showOperatingCountries = false,
  });

  final CommunityMember member;
  final bool isGuest;
  final bool showOperatingCountries;

  @override
  Widget build(BuildContext context) {
    // The same premium card is used in two places:
    // 1. the fixed-height dashboard carousel, and
    // 2. the View All vertical ListView.
    //
    // A vertical ListView gives its children unbounded height. Giving the
    // reusable card an explicit height here guarantees finite constraints in
    // both places and prevents RenderFlex / child.hasSize failures.
    return SizedBox(
      width: double.infinity,
      height: premiumProviderCardHeight,
      child: _LocalExpertCard(
        member: member,
        isGuest: isGuest,
        showOperatingCountries: showOperatingCountries,
      ),
    );
  }
}

class _LocalExpertCard extends StatelessWidget {
  const _LocalExpertCard({
    required this.member,
    required this.isGuest,
    required this.showOperatingCountries,
  });

  final CommunityMember member;
  final bool isGuest;
  final bool showOperatingCountries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isOperator = member.isOperator;

    return Material(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(.16),
      child: InkWell(
        onTap: () => _openProviderProfile(
          context,
          member,
          isGuest: isGuest,
        ),
        splashColor: const Color(0xFF165B5D).withOpacity(.05),
        highlightColor: const Color(0xFF165B5D).withOpacity(.025),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFF165B5D).withOpacity(.075),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _PremiumProviderAvatar(
                            member: member,
                            size: 72,
                            borderColor: Colors.white,
                            borderWidth: 2,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        member.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: const Color(0xFF17211F),
                                          fontWeight: FontWeight.w900,
                                          height: 1.05,
                                          letterSpacing: -.35,
                                        ),
                                      ),
                                    ),
                                    if (member.isVerified) ...[
                                      const SizedBox(width: 5),
                                      const Tooltip(
                                        message: 'Verified provider',
                                        child: Icon(
                                          Icons.verified_rounded,
                                          color: Color(0xFF165B5D),
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isOperator ? 'Tour Operator' : 'Safari Guide',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF165B5D),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _PremiumRating(member: member),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _joinedAgoLabel(member.joinedAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withOpacity(.58),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _InlineSaveProviderButton(
                            member: member,
                            isGuest: isGuest,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Divider(
                        height: 1,
                        thickness: .8,
                        color: colors.outlineVariant.withOpacity(.62),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: Color(0xFF165B5D),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Based in',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(.60),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 7),
                          _RectangularCountryFlag(
                            countryName:
                                member.country.trim().isNotEmpty
                                    ? member.country.trim()
                                    : member.location.trim(),
                            width: 27,
                            height: 18,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              member.country.trim().isNotEmpty
                                  ? member.country.trim()
                                  : member.location.trim().isNotEmpty
                                  ? member.location.trim()
                                  : 'East Africa',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF17211F),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F4),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.visibility_outlined,
                                  size: 15,
                                  color: Color(0xFF165B5D),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${member.viewCount}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF165B5D),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (showOperatingCountries) ...[
                        const SizedBox(height: 12),

                        Divider(
                          height: 1,
                          thickness: .8,
                          color: colors.outlineVariant.withOpacity(.62),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'OPERATES IN',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurface.withOpacity(.58),
                            fontWeight: FontWeight.w900,
                            letterSpacing: .65,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Align(
                          alignment: Alignment.topLeft,
                          child: _PremiumOperatingCountryChips(member: member),
                        ),
                      ],
                    ],
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _InlineSaveProviderButton extends StatelessWidget {
  const _InlineSaveProviderButton({
    required this.member,
    required this.isGuest,
  });

  final CommunityMember member;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final record = DiscoveryRecord.fromProvider(member);

    return AnimatedBuilder(
      animation: DiscoveryStore.instance,
      builder: (context, _) {
        final saved = DiscoveryStore.instance.isSaved(record);

        return Material(
          color: saved
              ? const Color(0xFFF46627).withOpacity(.12)
              : const Color(0xFF165B5D).withOpacity(.07),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () async {
              if (isGuest) {
                await showGuestAccessSheet(
                  context,
                  title: 'Save this provider',
                  message:
                      'Login or create a free account to save guides and tour operators to your favourites.',
                );
                return;
              }

              DiscoveryStore.instance.toggleSaved(record);
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                saved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 20,
                color: saved
                    ? const Color(0xFFF46627)
                    : const Color(0xFF165B5D),
              ),
            ),
          ),
        );
      },
    );
  }
}


class _PremiumTypeBadge extends StatelessWidget {
  const _PremiumTypeBadge({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final isOperator = member.isOperator;
    final label =
        isOperator
            ? (member.isVerified ? 'VERIFIED OPERATOR' : 'TOUR OPERATOR')
            : (member.ratingCount > 0 ? 'TOP RATED GUIDE' : 'LOCAL GUIDE');

    final color =
        isOperator
            ? const Color(0xFFF46627)
            : const Color(0xFFD7A842);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.93),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOperator
                ? Icons.verified_user_outlined
                : Icons.star_rounded,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumRating extends StatelessWidget {
  const _PremiumRating({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final hasRatings = member.ratingCount > 0;

    if (!hasRatings) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F2E8),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'New',
          style: TextStyle(
            color: Color(0xFF8A6726),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              color: Color(0xFFD7A842),
              size: 19,
            ),
            const SizedBox(width: 4),
            Text(
              member.ratingAverage.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFF17211F),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          '(${member.ratingCount} ${member.ratingCount == 1 ? 'review' : 'reviews'})',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.58),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PremiumOperatingCountryChips extends StatelessWidget {
  const _PremiumOperatingCountryChips({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final countries = member.countriesServed;
    if (countries.isEmpty) {
      return const Text(
        'East Africa',
        style: TextStyle(
          color: Color(0xFF66716E),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    const maxVisible = 3;
    final visible = countries.take(maxVisible).toList();
    final hidden = countries.length - visible.length;

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        ...visible.map(
          (country) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF165B5D).withOpacity(.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RectangularCountryFlag(
                  countryName: country,
                  width: 21,
                  height: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  country,
                  style: const TextStyle(
                    color: Color(0xFF17211F),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hidden > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF165B5D).withOpacity(.14),
              ),
            ),
            child: Text(
              '+$hidden',
              style: const TextStyle(
                color: Color(0xFF165B5D),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _CoverRating extends StatelessWidget {
  const _CoverRating({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final hasRatings = member.ratingCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.20), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC107)),
          const SizedBox(width: 4),
          Text(
            hasRatings
                ? '${member.ratingAverage.toStringAsFixed(1)} (${member.ratingCount})'
                : 'New',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRating extends StatelessWidget {
  const _CompactRating({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (member.ratingCount <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'New',
          style: theme.textTheme.labelMedium?.copyWith(
            color: const Color(0xFF7A6538),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFE8AD2E), size: 19),
          const SizedBox(width: 4),
          Text(
            member.ratingAverage.toStringAsFixed(1),
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF171B18),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '(${member.ratingCount})',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF60635F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderBackdropImage extends StatelessWidget {
  const _ProviderBackdropImage({
    required this.member,
    required this.fallbackIcon,
  });

  final CommunityMember member;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        member.coverImageUrl.isNotEmpty
            ? member.coverImageUrl
            : member.profilePhotoUrl;
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF426A4D), _providerForestDeep],
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 98,
          color: _providerGold.withOpacity(.23),
        ),
      ),
    );
    if (imageUrl.isEmpty) return fallback;
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _PremiumProviderAvatar extends StatelessWidget {
  const _PremiumProviderAvatar({
    required this.member,
    required this.size,
    this.borderColor = _providerGold,
    this.borderWidth = 3,
  });

  final CommunityMember member;
  final double size;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      alignment: Alignment.center,
      color: _providerForest,
      child: Text(
        _initials(member.name),
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        color: borderColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipOval(
        child:
            member.profilePhotoUrl.isEmpty
                ? fallback
                : Image.network(
                  member.profilePhotoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                ),
      ),
    );
  }
}

class _ProviderTypeLabel extends StatelessWidget {
  const _ProviderTypeLabel({required this.label, this.color = _providerGold});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 14,
        letterSpacing: 1,
      ),
    );
  }
}

class _AdminVerifiedBadge extends StatelessWidget {
  const _AdminVerifiedBadge({
    this.compact = false,
    this.onLightSurface = false,
  });

  final bool compact;
  final bool onLightSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color:
            onLightSurface
                ? Colors.black.withOpacity(.04)
                : Colors.white.withOpacity(.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              onLightSurface
                  ? Colors.black.withOpacity(.18)
                  : Colors.white.withOpacity(.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: onLightSurface ? Colors.black : const Color(0xFFF8F1DF),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            'Admin Verified',
            style: TextStyle(
              color: onLightSurface ? Colors.black : const Color(0xFFF8F1DF),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: .45,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatingCountries extends StatelessWidget {
  const _OperatingCountries({
    required this.member,
    this.foregroundColor = Colors.white,
    this.showOperatorLogo = false,
  });

  final CommunityMember member;
  final Color foregroundColor;
  final bool showOperatorLogo;

  @override
  Widget build(BuildContext context) {
    final countries = member.countriesServed;

    if (countries.isEmpty && !showOperatorLogo) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showOperatorLogo) ...[
          _OperatorCardLogo(member: member),
          const SizedBox(width: 8),
        ],
        if (countries.isNotEmpty) ...[
          Text(
            'Operates in',
            style: TextStyle(
              color: foregroundColor.withOpacity(.72),
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: countries
                  .take(4)
                  .map(
                    (country) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF165B5D).withOpacity(.07),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF165B5D).withOpacity(.09),
                        ),
                      ),
                      child: Text(
                        country,
                        style: TextStyle(
                          color: foregroundColor.withOpacity(.88),
                          fontSize: 10.7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }
}

class _OperatorCardLogo extends StatelessWidget {
  const _OperatorCardLogo({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final initials =
        member.name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    final fallback = Container(
      alignment: Alignment.center,
      color: colors.primaryContainer.withOpacity(.55),
      child: Text(
        initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Container(
      width: 74,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(.72),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child:
            member.profilePhotoUrl.isEmpty
                ? fallback
                : Image.network(
                  member.profilePhotoUrl,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => fallback,
                ),
      ),
    );
  }
}

class _RectangularCountryFlag extends StatelessWidget {
  const _RectangularCountryFlag({
    required this.countryName,
    this.width = 30,
    this.height = 20,
  });

  final String countryName;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final country = TourismCountries.byName(countryName);

    if (country == null) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Text('🌍', style: TextStyle(fontSize: 13)),
      );
    }

    final code = country.code.toLowerCase();

    final fallback = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.7),
          width: 1,
        ),
      ),
      child: Text(
        TourismCountries.flagForCountry(country.name),
        style: TextStyle(fontSize: height * .66, height: 1),
      ),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.72),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        'https://flagcdn.com/w80/$code.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _ProviderLocation extends StatelessWidget {
  const _ProviderLocation({
    required this.member,
    this.foregroundColor = Colors.white,
    this.iconColor = _providerGold,
  });

  final CommunityMember member;
  final Color foregroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.location_on_rounded, color: iconColor, size: 16),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            member.location.isEmpty ? 'Uganda' : member.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor.withOpacity(.83),
              fontSize: 14,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _providerGold.withOpacity(.15),
            _providerGold.withOpacity(.72),
            _providerGold.withOpacity(.15),
          ],
        ),
      ),
    );
  }
}

class _ProviderMetricData {
  const _ProviderMetricData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _ProviderMetricRow extends StatelessWidget {
  const _ProviderMetricRow({
    required this.metrics,
    this.foregroundColor = Colors.white,
    this.accentColor = _providerGold,
    this.dividerColor,
    this.dividerHeight = 52,
  });

  final List<_ProviderMetricData> metrics;
  final Color foregroundColor;
  final Color accentColor;
  final Color? dividerColor;
  final double dividerHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          if (index > 0)
            Container(
              width: 1,
              height: dividerHeight,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: dividerColor ?? Colors.white.withOpacity(.17),
            ),
          Expanded(
            child: _ProviderMetric(
              metric: metrics[index],
              foregroundColor: foregroundColor,
              accentColor: accentColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProviderMetric extends StatelessWidget {
  const _ProviderMetric({
    required this.metric,
    required this.foregroundColor,
    required this.accentColor,
  });

  final _ProviderMetricData metric;
  final Color foregroundColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(metric.icon, color: accentColor, size: 14),
        const SizedBox(height: 4),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 14,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foregroundColor.withOpacity(.68),
            fontSize: 14,
            height: 1.05,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GuideCardStats extends StatelessWidget {
  const _GuideCardStats({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0x16000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.visibility_outlined,
                color: Colors.black,
                size: 16,
              ),
              const SizedBox(height: 3),
              Text(
                _compactCount(member.viewCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Viewed',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0x99000000),
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.map_outlined, color: Colors.black, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Tours',
                    style: TextStyle(
                      color: Color(0x99000000),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    '${_compactCount(member.publishedToursCount)} tours',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0x99000000),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _joinedAgoLabel(member.joinedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0x99000000),
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaveProviderButton extends StatelessWidget {
  const _SaveProviderButton({required this.member, required this.isGuest});

  final CommunityMember member;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final record = DiscoveryRecord.fromProvider(member);
    return AnimatedBuilder(
      animation: DiscoveryStore.instance,
      builder: (context, _) {
        final saved = DiscoveryStore.instance.isSaved(record);
        return Material(
          color: Colors.white.withOpacity(.94),
          shape: const CircleBorder(),
          elevation: 2,
          child: IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save provider',
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              if (isGuest) {
                await showGuestAccessSheet(
                  context,
                  title: 'Save this provider',
                  message:
                      'Login or create a free account to save guides and tour operators to your favourites.',
                );
                return;
              }
              DiscoveryStore.instance.toggleSaved(record);
            },
            icon: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: saved ? _providerOrange : Colors.black87,
            ),
          ),
        );
      },
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _compactCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(count >= 10000000 ? 0 : 1)}M';
  }
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 1)}K';
  }
  return '$count';
}

String _joinedCompactValue(DateTime? value) {
  if (value == null) return 'New';
  final elapsed = DateTime.now().difference(value.toLocal());
  if (elapsed.isNegative || elapsed.inDays == 0) return 'Today';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
  if (elapsed.inDays < 35) return '${elapsed.inDays ~/ 7}w ago';
  if (elapsed.inDays < 365) return '${elapsed.inDays ~/ 30}m ago';
  return '${elapsed.inDays ~/ 365}y ago';
}

String _joinedAgoLabel(DateTime? value) {
  if (value == null) return 'Joined recently';
  final elapsed = DateTime.now().difference(value.toLocal());
  if (elapsed.isNegative || elapsed.inDays == 0) return 'Joined today';
  if (elapsed.inDays < 7) {
    return 'Joined ${elapsed.inDays} day${elapsed.inDays == 1 ? '' : 's'} ago';
  }
  if (elapsed.inDays < 35) {
    final weeks = elapsed.inDays ~/ 7;
    return 'Joined $weeks week${weeks == 1 ? '' : 's'} ago';
  }
  if (elapsed.inDays < 365) {
    final months = elapsed.inDays ~/ 30;
    return 'Joined $months month${months == 1 ? '' : 's'} ago';
  }
  final years = elapsed.inDays ~/ 365;
  return 'Joined $years year${years == 1 ? '' : 's'} ago';
}

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key, required this.member});

  final CommunityMember member;

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  bool _working = false;
  late CommunityMember _member;
  late Future<CommunityMember> _profile;
  late Future<RatingSummary> _ratings;
  ExistingRating? _myRating;

  CommunityMember get member => _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _myRating = member.myRating;
    _profile = _loadProfile();
    _ratings = _loadRatings();
  }

  Future<CommunityMember> _loadProfile() async {
    final profile = await CommunityService.instance.fetchMember(member.id);
    if (mounted) setState(() => _member = profile);
    return profile;
  }

  void _reloadProfile() {
    setState(() => _profile = _loadProfile());
  }

  void _reloadRatings() {
    setState(() {
      _ratings = _loadRatings();
    });
  }

  Future<RatingSummary> _loadRatings() async {
    final summary = await CommunityService.instance.fetchMemberRatings(
      member.id,
    );
    final viewerId = AuthService.instance.currentUser?.id;
    final ownRatings = summary.ratings.where(
      (rating) => rating.reviewerId == viewerId,
    );
    if (ownRatings.isNotEmpty && mounted) {
      final own = ownRatings.first;
      setState(() {
        _myRating = ExistingRating(stars: own.stars, review: own.review);
      });
    }
    return summary;
  }

  Future<void> _message() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final conversation = await CommunityService.instance.startConversation(
        member.id,
      );
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(conversation: conversation)),
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _rate() async {
    final isProfessional =
        AuthService.instance.currentUser?.role == 'tour_operator';
    var stars = _myRating?.stars ?? 5;
    final review = TextEditingController(text: _myRating?.review ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    isProfessional
                        ? 'Rate ${member.name} professionally'
                        : 'Rate ${member.name}',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final value = index + 1;
                            return IconButton(
                              onPressed:
                                  () => setDialogState(() => stars = value),
                              icon: Icon(
                                value <= stars
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: const Color(0xFFF2A900),
                                size: 31,
                              ),
                            );
                          }),
                        ),
                        TextField(
                          controller: review,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            labelText:
                                isProfessional
                                    ? 'Professional feedback (optional)'
                                    : 'Review (optional)',
                            hintText:
                                isProfessional
                                    ? 'Share how the guide worked with your guests'
                                    : 'Share your safari experience',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Save rating'),
                    ),
                  ],
                ),
          ),
    );
    if (save != true) {
      review.dispose();
      return;
    }
    setState(() => _working = true);
    try {
      await CommunityService.instance.submitRating(
        memberId: member.id,
        stars: stars,
        review: review.text,
      );
      if (mounted) {
        setState(() {
          _myRating = ExistingRating(stars: stars, review: review.text.trim());
        });
        _reloadRatings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isProfessional
                  ? 'Professional guide rating saved.'
                  : 'Rating saved successfully.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      review.dispose();
      if (mounted) setState(() => _working = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewerRole = AuthService.instance.currentUser?.role;
    return FutureBuilder<CommunityMember>(
      future: _profile,
      builder: (context, snapshot) {
        final current = snapshot.data ?? member;
        final canMessage = AuthService.instance.currentUser != null;
        final canRate =
            viewerRole == 'tourist' ||
            (viewerRole == 'tour_operator' && current.isGuide);
        final isProfessionalRating = viewerRole == 'tour_operator';

        return Scaffold(
          backgroundColor: const Color(0xFFF4EEE1),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _ProviderProfileHero(member: current),
                    Transform.translate(
                      offset: const Offset(0, -58),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: Column(
                          children: [
                            _ProviderIdentityCard(member: current),
                            const SizedBox(height: 14),
                            _ProviderTrustPanel(member: current),
                            if (current.isGuide &&
                                current.publicAffiliations.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _GuidePublicAffiliationsSection(member: current),
                            ],
                            if (current.isOperator &&
                                current.safariTeam.isNotEmpty) ...[
                              const SizedBox(height: 26),
                              _OperatorSafariTeamSection(operator: current),
                            ],
                            if (snapshot.hasError) ...[
                              const SizedBox(height: 12),
                              _ProfileLoadNotice(onRetry: _reloadProfile),
                            ],
                            if (canMessage || canRate) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  if (canMessage)
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: _working ? null : _message,
                                        icon: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                        ),
                                        label: const Text('Message'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF165B5D),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(0, 54),
                                          elevation: 0,
                                          shape: const StadiumBorder(),
                                        ),
                                      ),
                                    ),
                                  if (canMessage && canRate)
                                    const SizedBox(width: 10),
                                  if (canRate)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _working ? null : _rate,
                                        icon: const Icon(
                                          Icons.star_outline_rounded,
                                        ),
                                        label: Text(
                                          _myRating == null
                                              ? isProfessionalRating
                                                  ? 'Rate guide'
                                                  : 'Rate profile'
                                              : 'Edit rating',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF165B5D),
                                          side: const BorderSide(
                                            color: Color(0xFF165B5D),
                                          ),
                                          minimumSize: const Size(0, 54),
                                          shape: const StadiumBorder(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            if (current.isGuide &&
                                current.galleryUrls.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _GuideGallerySlider(
                                guideName: current.name,
                                images: current.galleryUrls,
                              ),
                            ],
                            if (current.tours.isNotEmpty) ...[
                              const SizedBox(height: 30),
                              _ProviderToursSection(member: current),
                            ],
                            if ((current.isOperator || current.isGuide) &&
                                current.carHireEnabled) ...[
                              const SizedBox(height: 30),
                              _OperatorCarHireProfileSection(
                                operator: current,
                              ),
                            ],
                            if (current.biography.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _ProviderAboutSection(member: current),
                            ],
                            if (current.activityNames.isNotEmpty ||
                                current.destinationNames.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _ProviderExpertiseSection(member: current),
                            ],
                            const SizedBox(height: 28),
                            _ProviderDetailsSection(member: current),
                            if (current.socialLinks.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _ProviderSocialSection(member: current),
                            ],
                            const SizedBox(height: 32),
                            _ProfileRatingsSection(
                              ratings: _ratings,
                              onRetry: _reloadRatings,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Material(
                    color: const Color(0xFF165B5D).withOpacity(.90),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProviderProfileHero extends StatelessWidget {
  const _ProviderProfileHero({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);
    const secondary = Color(0xFFF46627);
    final accent = member.isOperator ? secondary : primary;

    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF315F60),
            Color(0xFF165B5D),
            Color(0xFF0B3D3F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -45,
            child: Icon(
              member.isOperator
                  ? Icons.business_center_rounded
                  : Icons.explore_rounded,
              size: 235,
              color: Colors.white.withOpacity(.07),
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      height: 318,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(38),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (member.coverImageUrl.isEmpty)
              fallback
            else
              Image.network(
                member.coverImageUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => fallback,
              ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x16000000),
                    Color(0x26000000),
                    Color(0x7A000000),
                    Color(0xD8001716),
                  ],
                  stops: [0, .42, .72, 1],
                ),
              ),
            ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 78,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                member.isVerified
                                    ? Icons.verified_user_rounded
                                    : member.isOperator
                                    ? Icons.business_center_outlined
                                    : Icons.hiking_rounded,
                                color: member.isVerified
                                    ? const Color(0xFFFFC75A)
                                    : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                member.isVerified
                                    ? member.isOperator
                                        ? 'VERIFIED TOUR OPERATOR'
                                        : 'VERIFIED SAFARI GUIDE'
                                    : member.isOperator
                                    ? 'TOUR OPERATOR'
                                    : 'SAFARI GUIDE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  letterSpacing: .55,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (member.country.trim().isNotEmpty ||
                            member.location.trim().isNotEmpty) ...[
                          const SizedBox(height: 11),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: 17,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  member.country.trim().isNotEmpty
                                      ? member.country.trim()
                                      : member.location.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.92),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.92),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(.32),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperatorProfileLogo extends StatelessWidget {
  const _OperatorProfileLogo({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (member.profilePhotoUrl.isEmpty) {
      return SizedBox(
        width: 106,
        height: 72,
        child: Icon(Icons.business_outlined, color: colors.primary, size: 42),
      );
    }

    return SizedBox(
      width: 106,
      height: 72,
      child: Image.network(
        member.profilePhotoUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder:
            (_, __, ___) =>
                Icon(Icons.business_outlined, color: colors.primary, size: 42),
      ),
    );
  }
}

class _ProviderIdentityCard extends StatelessWidget {
  const _ProviderIdentityCard({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF165B5D);
    const secondary = Color(0xFFF46627);
    final accent = member.isOperator ? secondary : primary;
    final baseCountry = member.country.trim().isNotEmpty
        ? member.country.trim()
        : member.location.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: primary.withOpacity(.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            blurRadius: 30,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Hero(
                tag: 'provider-${member.id}',
                child: member.isOperator
                    ? Container(
                        width: 102,
                        height: 102,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.13),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.center,
                            child: member.profilePhotoUrl.isEmpty
                                ? Icon(
                                    Icons.business_outlined,
                                    color: primary,
                                    size: 42,
                                  )
                                : Image.network(
                                    member.profilePhotoUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.business_outlined,
                                      color: primary,
                                      size: 42,
                                    ),
                                  ),
                          ),
                        ),
                      )
                    : _ProviderImage(
                        member: member,
                        operatorStyle: false,
                        size: 102,
                        borderWidth: 3,
                        borderColor: Colors.white,
                      ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF17211F),
                              fontWeight: FontWeight.w900,
                              height: 1.03,
                              letterSpacing: -.65,
                            ),
                          ),
                        ),
                        if (member.isVerified) ...[
                          const SizedBox(width: 6),
                          const Tooltip(
                            message:
                                'Verified by Tourism Portal administration',
                            child: Icon(
                              Icons.verified_rounded,
                              color: primary,
                              size: 25,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      member.isOperator ? 'Tour Operator' : 'Safari Guide',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    if (member.joinedAt != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        _joinedAgoLabel(member.joinedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF66716E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              if (baseCountry.isNotEmpty) ...[
                const Icon(
                  Icons.location_on_outlined,
                  color: primary,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  'Based in',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF66716E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 7),
                _RectangularCountryFlag(
                  countryName: baseCountry,
                  width: 28,
                  height: 18,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    baseCountry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF17211F),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: primary.withOpacity(.07),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      color: primary,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _compactCount(member.viewCount),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (member.countriesServed.isNotEmpty) ...[
            const SizedBox(height: 17),
            Divider(
              height: 1,
              color: primary.withOpacity(.10),
            ),
            const SizedBox(height: 13),
            Text(
              'OPERATES IN',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF66716E),
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: member.countriesServed.map((country) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4ED),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: primary.withOpacity(.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RectangularCountryFlag(
                        countryName: country,
                        width: 21,
                        height: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        country,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF17211F),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 17),

          Divider(
            height: 1,
            color: primary.withOpacity(.10),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _ProviderMiniStat(
                  value: member.ratingCount == 0
                      ? 'New'
                      : member.ratingAverage.toStringAsFixed(1),
                  label: member.ratingCount == 0
                      ? 'No reviews yet'
                      : '${member.ratingCount} ${member.ratingCount == 1 ? 'review' : 'reviews'}',
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFD7A842),
                ),
              ),
              Expanded(
                child: _ProviderMiniStat(
                  value: '${member.yearsExperience}',
                  label: 'Years',
                  icon: Icons.workspace_premium_outlined,
                  iconColor: primary,
                ),
              ),
              Expanded(
                child: _ProviderMiniStat(
                  value: '${member.publishedToursCount}',
                  label: 'Tours',
                  icon: Icons.route_rounded,
                  iconColor: accent,
                ),
              ),
              Expanded(
                child: _ProviderMiniStat(
                  value: '${member.destinationNames.length}',
                  label: 'Destinations',
                  icon: Icons.map_outlined,
                  iconColor: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderTrustPanel extends StatelessWidget {
  const _ProviderTrustPanel({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF165B5D);
    const secondary = Color(0xFFF46627);

    final items = <({IconData icon, String title, String subtitle})>[
      (
        icon: Icons.schedule_rounded,
        title: member.responseTimeLabel,
        subtitle: 'Typical response',
      ),
      (
        icon: Icons.translate_rounded,
        title: member.languages.isEmpty
            ? 'Local expert'
            : member.languages.take(2).join(' • '),
        subtitle: 'Languages',
      ),
      (
        icon: Icons.workspace_premium_outlined,
        title: '${member.yearsExperience} years',
        subtitle: 'Safari experience',
      ),
      (
        icon: Icons.route_rounded,
        title: '${member.publishedToursCount}',
        subtitle: 'Published safaris',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Professional profile',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      member.isVerified
                          ? 'Identity reviewed by Tourism Portal'
                          : 'Profile information supplied by this provider',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(.70),
                      ),
                    ),
                  ],
                ),
              ),
              if (member.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      letterSpacing: .45,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 15),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items.map((item) {
                  return SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.09),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(.10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: const Color(0xFFFFC75A),
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withOpacity(.62),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProviderMiniStat extends StatelessWidget {
  const _ProviderMiniStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 19),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.58),
          ),
        ),
      ],
    );
  }
}

class _GuidePublicAffiliationsSection extends StatelessWidget {
  const _GuidePublicAffiliationsSection({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (member.publicAffiliations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProviderSectionHeading(
          title: 'Professional affiliation',
          subtitle:
              'Tour operators this guide publicly works with on the platform.',
        ),
        const SizedBox(height: 14),
        ...member.publicAffiliations.map(
          (affiliation) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap:
                    () => _openProviderProfile(context, affiliation.operator),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.outlineVariant.withOpacity(.66),
                    ),
                  ),
                  child: Row(
                    children: [
                      _PublicOperatorLogo(operator: affiliation.operator),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Works with',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onSurface.withOpacity(.52),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    affiliation.operator.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -.2,
                                        ),
                                  ),
                                ),
                                if (affiliation.operator.isVerified) ...[
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.verified_rounded,
                                    color: colors.primary,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(.08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    affiliation.relationshipLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (affiliation.operator.country
                                    .trim()
                                    .isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _RectangularCountryFlag(
                                        countryName:
                                            affiliation.operator.country,
                                        width: 25,
                                        height: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        affiliation.operator.country,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: colors.onSurface
                                                  .withOpacity(.62),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 37,
                        height: 37,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withOpacity(.60),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.primary,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PublicOperatorLogo extends StatelessWidget {
  const _PublicOperatorLogo({required this.operator});

  final CommunityMember operator;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = _initials(operator.name);

    final fallback = Container(
      alignment: Alignment.center,
      color: colors.primaryContainer.withOpacity(.55),
      child: Text(
        initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Container(
      width: 76,
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.outlineVariant.withOpacity(.72)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child:
            operator.profilePhotoUrl.isEmpty
                ? fallback
                : Image.network(
                  operator.profilePhotoUrl,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => fallback,
                ),
      ),
    );
  }
}

class _OperatorSafariTeamSection extends StatefulWidget {
  const _OperatorSafariTeamSection({required this.operator});

  final CommunityMember operator;

  @override
  State<_OperatorSafariTeamSection> createState() =>
      _OperatorSafariTeamSectionState();
}

class _OperatorSafariTeamSectionState
    extends State<_OperatorSafariTeamSection> {
  late final PageController _controller = PageController(viewportFraction: .82);

  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final team = widget.operator.safariTeam;

    if (team.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: _ProviderSectionHeading(
                title: 'Our Safari Team',
                subtitle:
                    'Meet the local guides behind this operator’s journeys.',
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withOpacity(.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${team.length} ${team.length == 1 ? 'guide' : 'guides'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 286,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            physics: const BouncingScrollPhysics(),
            itemCount: team.length,
            onPageChanged: (index) {
              setState(() => _current = index);
            },
            itemBuilder: (context, index) {
              final teamMember = team[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == team.length - 1 ? 0 : 13,
                ),
                child: _SafariTeamGuideCard(teamMember: teamMember),
              );
            },
          ),
        ),
        if (team.length > 1) ...[
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              team.length.clamp(0, 7),
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == _current ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color:
                      index == _current
                          ? colors.primary
                          : colors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SafariTeamGuideCard extends StatelessWidget {
  const _SafariTeamGuideCard({required this.teamMember});

  final SafariTeamMember teamMember;

  CommunityMember get guide => teamMember.guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF165B5D), Color(0xFF0C3434)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.hiking_rounded,
        size: 62,
        color: Colors.white.withOpacity(.20),
      ),
    );

    final imageUrl =
        guide.coverImageUrl.isNotEmpty
            ? guide.coverImageUrl
            : guide.profilePhotoUrl;

    return Material(
      color: const Color(0xFF102825),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(.14),
      child: InkWell(
        onTap: () => _openProviderProfile(context, guide),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isEmpty
                ? fallback
                : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => fallback,
                ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x0A000000),
                    Color(0x30000000),
                    Color(0xED071D18),
                  ],
                  stops: [0, .48, 1],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.40),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(.18)),
                ),
                child: Text(
                  teamMember.relationshipLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.92),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  color: Color(0xFF165B5D),
                  size: 18,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SafariTeamGuideAvatar(guide: guide),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                guide.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: -.3,
                                ),
                              ),
                            ),
                            if (guide.isVerified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF6CE4A5),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (guide.country.trim().isNotEmpty)
                          Row(
                            children: [
                              _RectangularCountryFlag(
                                countryName: guide.country,
                                width: 25,
                                height: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Based in ${guide.country}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.76),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (guide.languages.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            guide.languages.take(3).join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(.70),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafariTeamGuideAvatar extends StatelessWidget {
  const _SafariTeamGuideAvatar({required this.guide});

  final CommunityMember guide;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      alignment: Alignment.center,
      color: const Color(0xFF165B5D),
      child: Text(
        _initials(guide.name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child:
            guide.profilePhotoUrl.isEmpty
                ? fallback
                : Image.network(
                  guide.profilePhotoUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => fallback,
                ),
      ),
    );
  }
}

class _GuideGallerySlider extends StatefulWidget {
  const _GuideGallerySlider({required this.guideName, required this.images});

  final String guideName;
  final List<String> images;

  @override
  State<_GuideGallerySlider> createState() => _GuideGallerySliderState();
}

class _GuideGallerySliderState extends State<_GuideGallerySlider> {
  late final PageController _controller = PageController(viewportFraction: .94);
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(int index) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (_) => _GuideGalleryViewer(
              guideName: widget.guideName,
              images: widget.images,
              initialIndex: index,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProviderSectionHeading(
          title: 'Safari gallery',
          subtitle:
              'Swipe through moments from ${widget.guideName}\'s journeys.',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 238,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder:
                (context, index) => Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.images.length - 1 ? 0 : 10,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _open(index),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _GalleryNetworkImage(url: widget.images[index]),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(.58),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 14,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ('Journey ${index + 1}'),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(.42),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${index + 1} / ${widget.images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Positioned(
                            right: 14,
                            top: 14,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0x66000000),
                              child: Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.images.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: index == _current ? 24 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color:
                    index == _current
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideGalleryViewer extends StatefulWidget {
  const _GuideGalleryViewer({
    required this.guideName,
    required this.images,
    required this.initialIndex,
  });

  final String guideName;
  final List<String> images;
  final int initialIndex;

  @override
  State<_GuideGalleryViewer> createState() => _GuideGalleryViewerState();
}

class _GuideGalleryViewerState extends State<_GuideGalleryViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.guideName} · ${_current + 1}/${widget.images.length}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _current = index),
        itemBuilder:
            (context, index) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                ),
              ),
            ),
      ),
    );
  }
}

class _GalleryNetworkImage extends StatelessWidget {
  const _GalleryNetworkImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: const Icon(Icons.landscape_outlined, size: 54),
    );
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _ProviderToursSection extends StatelessWidget {
  const _ProviderToursSection({required this.member});

  final CommunityMember member;

  static const int _previewLimit = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final previewTours = member.tours.take(_previewLimit).toList();

    final totalTours = member.publishedToursCount > member.tours.length
        ? member.publishedToursCount
        : member.tours.length;

    final canViewAll = totalTours > previewTours.length ||
        member.tours.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.isGuide
                        ? 'Guided tours'
                        : 'Tours by this Operator',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF165B5D),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.isGuide
                        ? 'Published journeys personally led by ${member.name}'
                        : 'A selection of published safaris from ${member.name}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(.62),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (canViewAll)
              TextButton.icon(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => _OperatorAllToursPage(
                        member: member,
                      ),
                    ),
                  );
                },
                iconAlignment: IconAlignment.end,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                ),
                label: const Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF165B5D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF165B5D).withOpacity(.07),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$totalTours ${totalTours == 1 ? 'Published Tour' : 'Published Tours'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF165B5D),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (totalTours > previewTours.length) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing ${previewTours.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(.52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: previewTours.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _ProviderTourCard(
              tour: previewTours[index],
              member: member,
            ),
          ),
        ),
      ],
    );
  }
}

class _OperatorAllToursPage extends StatefulWidget {
  const _OperatorAllToursPage({
    required this.member,
  });

  final CommunityMember member;

  @override
  State<_OperatorAllToursPage> createState() =>
      _OperatorAllToursPageState();
}

enum _OperatorTourPriceSort {
  recommended,
  lowToHigh,
  highToLow,
}

class _OperatorAllToursPageState extends State<_OperatorAllToursPage> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);

  final TextEditingController _searchController =
      TextEditingController();

  String _query = '';
  String _country = 'All';
  String _activity = 'All Activities';
  int _duration = 0;
  _OperatorTourPriceSort _sort =
      _OperatorTourPriceSort.recommended;

  CommunityMember get member => widget.member;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _countries {
    final values = member.tours
        .expand((tour) => tour.countryNames)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  List<String> get _activities {
    final values = member.tours
        .expand((tour) => tour.activityNames)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All Activities', ...values];
  }

  bool _matchesDuration(OperatorTour tour) {
    switch (_duration) {
      case 1:
        return tour.days <= 3;
      case 2:
        return tour.days >= 4 && tour.days <= 7;
      case 3:
        return tour.days >= 8 && tour.days <= 14;
      case 4:
        return tour.days >= 15;
      default:
        return true;
    }
  }

  List<OperatorTour> get _filteredTours {
    final query = _query.trim().toLowerCase();

    final tours = member.tours.where((tour) {
      if (!_matchesDuration(tour)) return false;

      if (_country != 'All' &&
          !tour.countryNames
              .map((e) => e.toLowerCase())
              .contains(_country.toLowerCase())) {
        return false;
      }

      if (_activity != 'All Activities' &&
          !tour.activityNames
              .map((e) => e.toLowerCase())
              .contains(_activity.toLowerCase())) {
        return false;
      }

      if (query.isEmpty) return true;

      return <String>[
        tour.name,
        tour.overview,
        ...tour.countryNames,
        ...tour.destinationNames,
        ...tour.activityNames,
      ].join(' ').toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case _OperatorTourPriceSort.lowToHigh:
        tours.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _OperatorTourPriceSort.highToLow:
        tours.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _OperatorTourPriceSort.recommended:
        break;
    }

    return tours;
  }

  void _reset() {
    _searchController.clear();
    setState(() {
      _query = '';
      _country = 'All';
      _activity = 'All Activities';
      _duration = 0;
      _sort = _OperatorTourPriceSort.recommended;
    });
  }

  Future<void> _showSort() async {
    final value = await showModalBottomSheet<_OperatorTourPriceSort>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEDA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort Tours',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _OperatorSortTile(
                  title: 'Recommended',
                  selected:
                      _sort == _OperatorTourPriceSort.recommended,
                  onTap: () => Navigator.pop(
                    context,
                    _OperatorTourPriceSort.recommended,
                  ),
                ),
                _OperatorSortTile(
                  title: 'Price: Low to High',
                  selected:
                      _sort == _OperatorTourPriceSort.lowToHigh,
                  onTap: () => Navigator.pop(
                    context,
                    _OperatorTourPriceSort.lowToHigh,
                  ),
                ),
                _OperatorSortTile(
                  title: 'Price: High to Low',
                  selected:
                      _sort == _OperatorTourPriceSort.highToLow,
                  onTap: () => Navigator.pop(
                    context,
                    _OperatorTourPriceSort.highToLow,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (value != null && mounted) {
      setState(() => _sort = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tours = _filteredTours;

    final hasFilters = _query.isNotEmpty ||
        _country != 'All' ||
        _activity != 'All Activities' ||
        _duration != 0 ||
        _sort != _OperatorTourPriceSort.recommended;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${member.name} Tours',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Sort tours',
            onPressed: _showSort,
            icon: const Icon(
              Icons.swap_vert_rounded,
              color: _primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: Column(
              children: [
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _primary.withOpacity(.09),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search tours, countries or activities',
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _primary,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                _OperatorFilterStrip(
                  values: _countries,
                  selected: _country,
                  onChanged: (value) =>
                      setState(() => _country = value),
                ),

                if (_activities.length > 1) ...[
                  const SizedBox(height: 8),
                  _OperatorFilterStrip(
                    values: _activities,
                    selected: _activity,
                    accent: true,
                    onChanged: (value) =>
                        setState(() => _activity = value),
                  ),
                ],

                const SizedBox(height: 8),

                _OperatorFilterStrip(
                  values: const [
                    'Any Duration',
                    '1–3 Days',
                    '4–7 Days',
                    '8–14 Days',
                    '15+ Days',
                  ],
                  selected: const [
                    'Any Duration',
                    '1–3 Days',
                    '4–7 Days',
                    '8–14 Days',
                    '15+ Days',
                  ][_duration],
                  onChanged: (value) {
                    const values = [
                      'Any Duration',
                      '1–3 Days',
                      '4–7 Days',
                      '8–14 Days',
                      '15+ Days',
                    ];
                    setState(() => _duration = values.indexOf(value));
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 18, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${tours.length} ${tours.length == 1 ? 'tour' : 'tours'}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showSort,
                  icon: const Icon(
                    Icons.swap_vert_rounded,
                    size: 17,
                  ),
                  label: Text(
                    _sort == _OperatorTourPriceSort.lowToHigh
                        ? 'Low to High'
                        : _sort ==
                                _OperatorTourPriceSort.highToLow
                            ? 'High to Low'
                            : 'Sort',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                  ),
                ),
                if (hasFilters)
                  TextButton(
                    onPressed: _reset,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: _secondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: tours.isEmpty
                ? const Center(
                    child: Text(
                      'No matching tours found.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                    itemCount: tours.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tour = tours[index];

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(.08),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showProviderTour(
                            context,
                            tour,
                            member,
                          ),
                          child: SizedBox(
                            height: 142,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 126,
                                  height: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.all(9),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      child: _ProviderTourImage(
                                        tour: tour,
                                        accent: _primary,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      13,
                                      8,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tour.name,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: theme
                                              .textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight:
                                                FontWeight.w900,
                                            height: 1.12,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          tour.countryNames.isNotEmpty
                                              ? tour.countryNames.join(' • ')
                                              : '${(tour.destinationIds.toSet().isNotEmpty ? tour.destinationIds.toSet().length : tour.destinationNames.map((name) => name.trim().toLowerCase()).where((name) => name.isNotEmpty).toSet().length)} ${(tour.destinationIds.toSet().isNotEmpty ? tour.destinationIds.toSet().length : tour.destinationNames.map((name) => name.trim().toLowerCase()).where((name) => name.isNotEmpty).toSet().length) == 1 ? 'Destination' : 'Destinations'}',
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: theme
                                              .textTheme.bodySmall
                                              ?.copyWith(
                                            color: const Color(
                                              0xFF66716E,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Text(
                                              '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              _tourPrice(tour),
                                              style: theme
                                                  .textTheme.labelLarge
                                                  ?.copyWith(
                                                color: _primary,
                                                fontWeight:
                                                    FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(right: 9),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _OperatorFilterStrip extends StatelessWidget {
  const _OperatorFilterStrip({
    required this.values,
    required this.selected,
    required this.onChanged,
    this.accent = false,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final activeColor = accent
        ? const Color(0xFFF46627)
        : const Color(0xFF165B5D);

    return SizedBox(
      height: 39,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final value = values[index];
          final isSelected = value == selected;

          return Material(
            color: isSelected
                ? activeColor.withOpacity(accent ? .12 : 1)
                : Colors.white,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => onChanged(value),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? activeColor.withOpacity(accent ? .28 : 1)
                        : const Color(0xFF165B5D).withOpacity(.08),
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: isSelected
                        ? (accent ? activeColor : Colors.white)
                        : const Color(0xFF3D4845),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OperatorSortTile extends StatelessWidget {
  const _OperatorSortTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          color: selected
              ? const Color(0xFF165B5D)
              : const Color(0xFF27322F),
          fontWeight:
              selected ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF165B5D),
            )
          : null,
    );
  }
}

class _ProviderTourCard extends StatelessWidget {
  const _ProviderTourCard({
    required this.tour,
    required this.member,
  });

  final OperatorTour tour;
  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF165B5D);
    const secondary = Color(0xFFF46627);

    final place = tour.countryNames.isNotEmpty
        ? tour.countryNames.join(' • ')
        : '${(tour.destinationIds.toSet().isNotEmpty ? tour.destinationIds.toSet().length : tour.destinationNames.map((name) => name.trim().toLowerCase()).where((name) => name.isNotEmpty).toSet().length)} ${(tour.destinationIds.toSet().isNotEmpty ? tour.destinationIds.toSet().length : tour.destinationNames.map((name) => name.trim().toLowerCase()).where((name) => name.isNotEmpty).toSet().length) == 1 ? 'Destination' : 'Destinations'}';

    return SizedBox(
      width: 268,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        clipBehavior: Clip.antiAlias,
        elevation: 5,
        shadowColor: Colors.black.withOpacity(.11),
        child: InkWell(
          onTap: () => _showProviderTour(
            context,
            tour,
            member,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 154,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProviderTourImage(
                      tour: tour,
                      accent: primary,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x22000000),
                            Color(0xC9000000),
                          ],
                          stops: [0, .58, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 13,
                      top: 13,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.42),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(.18),
                          ),
                        ),
                        child: Text(
                          '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 13,
                      top: 13,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.94),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_outward_rounded,
                          color: primary,
                          size: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 13,
                      child: Text(
                        tour.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          letterSpacing: -.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    10,
                    14,
                    11,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF66716E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (tour.activityNames.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tour.activityNames
                              .take(2)
                              .map(
                                (activity) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(.06),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    activity,
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 10),

                      Divider(
                        height: 1,
                        thickness: .7,
                        color: primary.withOpacity(.075),
                      ),

                      const SizedBox(height: 9),

                      Row(
                        children: [
                          Text(
                            member.isGuide ? 'Guide-led' : 'Operator safari',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: secondary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _tourPrice(tour),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderTourImage extends StatelessWidget {
  const _ProviderTourImage({required this.tour, required this.accent});

  final OperatorTour tour;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, const Color(0xFF123C35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.landscape_outlined,
        color: Colors.white.withOpacity(.3),
        size: 82,
      ),
    );
    if (tour.imageUrl.isEmpty) return fallback;

    return Image.network(
      tour.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _TourImageBadge extends StatelessWidget {
  const _TourImageBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showProviderTour(
  BuildContext context,
  OperatorTour tour,
  CommunityMember member,
) async {
  await DiscoveryStore.instance.recordView(DiscoveryRecord.fromTour(tour));

  if (!context.mounted) {
    return;
  }

  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(builder: (_) => TourDetailsPage(tour: tour)),
  );
}

class _TourDetailGroup extends StatelessWidget {
  const _TourDetailGroup({
    required this.title,
    required this.icon,
    required this.values,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final List<String> values;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 19),
            const SizedBox(width: 7),
            Text(
              title.toTitleCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              values
                  .map(
                    (value) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(.09),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: accent.withOpacity(.14)),
                      ),
                      child: Text(
                        value,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

String _tourPrice(OperatorTour tour) {
  final amount = tour.price.toStringAsFixed(
    tour.price == tour.price.roundToDouble() ? 0 : 2,
  );
  final parts = amount.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  final decimals = parts.length == 2 ? '.${parts[1]}' : '';
  return '${tour.currency.isEmpty ? 'USD' : tour.currency} $buffer$decimals';
}


class _OperatorCarHireProfileSection extends StatefulWidget {
  const _OperatorCarHireProfileSection({
    required this.operator,
  });

  final CommunityMember operator;

  @override
  State<_OperatorCarHireProfileSection> createState() =>
      _OperatorCarHireProfileSectionState();
}

class _OperatorCarHireProfileSectionState
    extends State<_OperatorCarHireProfileSection> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);

  late Future<List<CarHireVehicle>> _vehicles;

  @override
  void initState() {
    super.initState();
    _vehicles = _load();
  }

  Future<List<CarHireVehicle>> _load() async {
    final result =
        await OperatorOfferingsService.instance.fetchVehicles(
      page: 1,
      perPage: 20,
      query: widget.operator.name,
    );

    final exact = result.vehicles.where((vehicle) {
      if (vehicle.operatorId > 0) {
        return vehicle.operatorId == widget.operator.id;
      }

      return vehicle.operatorName.trim().toLowerCase() ==
          widget.operator.name.trim().toLowerCase();
    }).toList();

    return exact;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CarHireVehicle>>(
      future: _vehicles,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ProviderSectionHeading(
                title: 'Safari Car Hire',
                subtitle:
                    'Vehicles available directly from this safari provider.',
              ),
              const SizedBox(height: 14),
              const PremiumSkeleton(height: 180),
            ],
          );
        }

        final vehicles = snapshot.data ?? const <CarHireVehicle>[];

        if (snapshot.hasError || vehicles.isEmpty) {
          return const SizedBox.shrink();
        }

        final preview = vehicles.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: _ProviderSectionHeading(
                    title: 'Safari Car Hire',
                    subtitle:
                        'Hire a safari-ready vehicle directly from this safari provider.',
                  ),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => CarHirePage(
                          initialQuery:
                              widget.operator.name,
                        ),
                      ),
                    );
                  },
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                  ),
                  label: const Text(
                    'View All',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(.16),
                    blurRadius: 20,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${vehicles.length} ${vehicles.length == 1 ? 'vehicle' : 'vehicles'} currently available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 13),

            SizedBox(
              height: 224,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: preview.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _OperatorVehiclePreviewCard(
                    vehicle: preview[index],
                    onTap: () {
                      Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => CarHireVehicleDetailsPage(
                          vehicle: preview[index],
                        ),
                      ),
                    );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OperatorVehiclePreviewCard extends StatelessWidget {
  const _OperatorVehiclePreviewCard({
    required this.vehicle,
    required this.onTap,
  });

  final CarHireVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 230,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(.10),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 128,
                width: double.infinity,
                child: vehicle.imageUrl.isEmpty
                    ? Container(
                        color: const Color(0xFF165B5D)
                            .withOpacity(.08),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          size: 44,
                          color: Color(0xFF165B5D),
                        ),
                      )
                    : Image.network(
                        vehicle.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF165B5D)
                              .withOpacity(.08),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.directions_car_filled_rounded,
                            size: 44,
                            color: Color(0xFF165B5D),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    11,
                    13,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        <String>[
                          if ((vehicle.transmission ?? '')
                              .trim()
                              .isNotEmpty)
                            vehicle.transmission!.trim(),
                          if (vehicle.seats != null)
                            '${vehicle.seats} seats',
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: const Color(0xFF66716E),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _vehiclePrice(vehicle),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(
                          color: const Color(0xFF165B5D),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _vehiclePrice(CarHireVehicle vehicle) {
  final currency = vehicle.currency.trim().isEmpty
      ? 'USD'
      : vehicle.currency.toUpperCase();

  final amount = vehicle.pricePerDay.toStringAsFixed(
    vehicle.pricePerDay ==
            vehicle.pricePerDay.roundToDouble()
        ? 0
        : 2,
  );

  return '$currency $amount / day';
}

class _ProviderAboutSection extends StatelessWidget {
  const _ProviderAboutSection({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProviderSectionHeading(
          title: member.isOperator ? 'About the company' : 'Meet your guide',
          subtitle:
              member.isOperator
                  ? 'The story and experience behind this safari company.'
                  : 'Experience, personality, and local knowledge.',
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant.withOpacity(.65)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -4,
                top: -10,
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 74,
                  color: colors.primary.withOpacity(.08),
                ),
              ),
              Text(
                member.biography,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.58,
                  color: colors.onSurface.withOpacity(.82),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderExpertiseSection extends StatelessWidget {
  const _ProviderExpertiseSection({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProviderSectionHeading(
          title: 'Safari expertise',
          subtitle: 'Activities and destinations selected on this profile.',
        ),
        if (member.activityLinks.isNotEmpty) ...[
          const SizedBox(height: 15),
          _ProviderTagGroup(
            title: 'Activities',
            icon: Icons.explore_outlined,
            values: member.activityLinks,
          ),
        ],
        if (member.destinationLinks.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ProviderTagGroup(
            title: 'Destinations',
            icon: Icons.location_on_outlined,
            values: member.destinationLinks,
          ),
        ],
      ],
    );
  }
}

class _ProviderTagGroup extends StatelessWidget {
  const _ProviderTagGroup({
    required this.title,
    required this.icon,
    required this.values,
  });

  final String title;
  final IconData icon;
  final List<ProviderCatalogLink> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withOpacity(.62)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(width: 7),
              Text(
                title.toTitleCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                values.map((value) {
                  return Material(
                    color: colors.primaryContainer.withOpacity(.62),
                    borderRadius: BorderRadius.circular(15),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap:
                          () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => _CatalogReferencePage(link: value),
                            ),
                          ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 9, 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value.name,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.arrow_outward_rounded,
                              size: 15,
                              color: colors.onPrimaryContainer.withOpacity(.72),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CatalogReferencePage extends StatefulWidget {
  const _CatalogReferencePage({required this.link});

  final ProviderCatalogLink link;

  @override
  State<_CatalogReferencePage> createState() => _CatalogReferencePageState();
}

class _CatalogReferencePageState extends State<_CatalogReferencePage> {
  late Future<CatalogItem> _item;

  @override
  void initState() {
    super.initState();
    _item = _load();
  }

  Future<CatalogItem> _load() {
    if (widget.link.slug.isEmpty) {
      return Future.error('This catalogue page is not available.');
    }
    return widget.link.isActivity
        ? CatalogService.instance.fetchActivity(widget.link.slug)
        : CatalogService.instance.fetchDestination(widget.link.slug);
  }

  void _retry() {
    setState(() => _item = _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<CatalogItem>(
      future: _item,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final item = snapshot.data!;
          return item.isActivity
              ? ActivityDetailsPage(item: item)
              : DestinationDetailsPage(item: item);
        }

        return Scaffold(
          appBar: AppBar(title: Text(widget.link.name)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child:
                  snapshot.hasError
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 42,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This catalogue page could not be opened.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      )
                      : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class _ProviderDetailsSection extends StatelessWidget {
  const _ProviderDetailsSection({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (member.isOperator && member.contactPerson.isNotEmpty)
        _ProviderDetailRow(
          icon: Icons.person_outline_rounded,
          label: 'Contact person',
          value: member.contactPerson,
        ),
      if (member.isGuide && member.gender.isNotEmpty)
        _ProviderDetailRow(
          icon: Icons.person_pin_outlined,
          label: 'Gender',
          value: member.gender,
        ),
      if (member.address.isNotEmpty)
        _ProviderDetailRow(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: member.address,
        ),
      if (member.languages.isNotEmpty)
        _ProviderDetailRow(
          icon: Icons.translate_rounded,
          label: 'Languages spoken',
          value: member.languages.join(', '),
        ),
      _ProviderDetailRow(
        icon: Icons.workspace_premium_outlined,
        label: 'Years of experience',
        value: '${member.yearsExperience} years',
      ),
      _ProviderDetailRow(
        icon: Icons.schedule_rounded,
        label: 'Typical response time',
        value: member.responseTimeLabel,
      ),
      if (member.phone.isNotEmpty)
        _ProviderDetailRow(
          icon: Icons.phone_outlined,
          label: 'Telephone',
          value: member.phone,
        ),
      if (member.email.isNotEmpty)
        _ProviderDetailRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: member.email,
        ),
      if (member.joinedAt != null)
        _ProviderDetailRow(
          icon: Icons.calendar_month_outlined,
          label: 'Member since',
          value: _joinedLabel(member.joinedAt),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProviderSectionHeading(
          title: member.isOperator ? 'Company details' : 'Guide details',
          subtitle: 'Information provided when this profile was completed.',
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(.62),
            ),
          ),
          child: Column(
            children: List.generate(rows.length, (index) {
              return Column(
                children: [
                  rows[index],
                  if (index != rows.length - 1)
                    Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withOpacity(.58),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ProviderDetailRow extends StatelessWidget {
  const _ProviderDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.leadingFlagCountry,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? leadingFlagCountry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(.62),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface.withOpacity(.56),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                if ((leadingFlagCountry ?? '').trim().isNotEmpty)
                  Row(
                    children: [
                      _RectangularCountryFlag(
                        countryName: leadingFlagCountry!,
                        width: 30,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SelectableText(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderSocialSection extends StatelessWidget {
  const _ProviderSocialSection({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final entries = member.socialLinks.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProviderSectionHeading(
          title: 'Connect online',
          subtitle: 'Social pages shared by this provider.',
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(.62),
            ),
          ),
          child: Column(
            children:
                entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _ProviderSocialLink(
                      icon: _socialIcon(entry.key),
                      label: _socialLabel(entry.key),
                      value: entry.value,
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProviderSocialLink extends StatelessWidget {
  const _ProviderSocialLink({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.primaryContainer.withOpacity(.42),
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openExternalLink(context, value),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(.62),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: colors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openExternalLink(BuildContext context, String value) async {
  final uri = _safeExternalUri(value);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This social link is not valid.')),
    );
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app could open this link.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This link could not be opened.')),
      );
    }
  }
}

Uri? _safeExternalUri(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final parsed = Uri.tryParse(
    trimmed.contains('://') ? trimmed : 'https://$trimmed',
  );
  if (parsed == null ||
      !parsed.hasAuthority ||
      !const {'http', 'https'}.contains(parsed.scheme.toLowerCase())) {
    return null;
  }
  return parsed;
}

String _socialLabel(String key) {
  if (key == 'facebook') return 'Facebook';
  if (key == 'instagram') return 'Instagram';
  if (key == 'x') return 'X / Twitter';
  return key;
}

IconData _socialIcon(String key) {
  if (key == 'facebook') return Icons.facebook_rounded;
  if (key == 'instagram') return Icons.camera_alt_outlined;
  if (key == 'x') return Icons.alternate_email_rounded;
  return Icons.link_rounded;
}

class _ProviderSectionHeading extends StatelessWidget {
  const _ProviderSectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFF46627),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF165B5D),
            fontWeight: FontWeight.w900,
            letterSpacing: -.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF66716E),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ProfileLoadNotice extends StatelessWidget {
  const _ProfileLoadNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: colors.errorContainer.withOpacity(.56),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Some profile details could not be refreshed.',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _joinedLabel(DateTime? value) {
  if (value == null) return 'Recently';
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final local = value.toLocal();
  return '${months[local.month - 1]} ${local.year}';
}

class _ProfileRatingsSection extends StatelessWidget {
  const _ProfileRatingsSection({required this.ratings, required this.onRetry});

  final Future<RatingSummary> ratings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ratings & Reviews',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Traveller experiences and professional feedback from tour operators.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.62),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<RatingSummary>(
          future: ratings,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _RatingsLoadingCard();
            }
            if (snapshot.hasError) {
              return _RatingsErrorCard(onRetry: onRetry);
            }

            final summary = snapshot.data!;
            if (summary.ratings.isEmpty) {
              return const _NoRatingsCard();
            }
            return Column(
              children: [
                _RatingOverviewCard(summary: summary),
                const SizedBox(height: 14),
                ...summary.ratings.map(
                  (rating) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ProfileRatingCard(rating: rating),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RatingOverviewCard extends StatelessWidget {
  const _RatingOverviewCard({required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer.withOpacity(.9),
            colors.secondaryContainer.withOpacity(.68),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withOpacity(.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _RatingCategoryMetric(
              label: 'Traveller rating',
              average: summary.travellerAverage,
              count: summary.travellerCount,
            ),
          ),
          Container(
            width: 1,
            height: 90,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: colors.onPrimaryContainer.withOpacity(.15),
          ),
          Expanded(
            child: _RatingCategoryMetric(
              label: 'Operator rating',
              average: summary.operatorAverage,
              count: summary.operatorCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCategoryMetric extends StatelessWidget {
  const _RatingCategoryMetric({
    required this.label,
    required this.average,
    required this.count,
  });

  final String label;
  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foreground.withOpacity(.72),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              count == 0 ? '—' : average.toStringAsFixed(1),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 3),
              const Icon(
                Icons.star_rounded,
                size: 22,
                color: Color(0xFFF2A900),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          count == 0
              ? 'No ratings yet'
              : '$count rating${count == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: foreground.withOpacity(.68),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileRatingCard extends StatelessWidget {
  const _ProfileRatingCard({required this.rating});

  final ReceivedRating rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withOpacity(.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .12 : .055),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TappableReviewerPhoto(rating: rating),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.reviewerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _timeAgo(rating.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(.58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            rating.isOperatorReview
                                ? colors.primaryContainer.withOpacity(.75)
                                : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        rating.reviewerTypeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              rating.isOperatorReview
                                  ? colors.onPrimaryContainer
                                  : colors.onSurface.withOpacity(.68),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 17,
                      color: Color(0xFFF2A900),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${rating.stars}.0',
                      style: const TextStyle(
                        color: Color(0xFF765000),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Stars(value: rating.stars, size: 18),
          const SizedBox(height: 11),
          Text(
            rating.review.trim().isEmpty
                ? rating.isOperatorReview
                    ? 'The tour operator left a professional star rating without written feedback.'
                    : 'The traveller left a star rating without a written review.'
                : rating.review,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.48,
              color: colors.onSurface.withOpacity(
                rating.review.trim().isEmpty ? .58 : .86,
              ),
              fontStyle:
                  rating.review.trim().isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _TappableReviewerPhoto extends StatelessWidget {
  const _TappableReviewerPhoto({required this.rating});

  final ReceivedRating rating;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${rating.reviewerName} profile',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openReviewerProfile(context, rating),
          customBorder:
              rating.isOperatorReview
                  ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  )
                  : const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: _ReviewerPhoto(rating: rating),
          ),
        ),
      ),
    );
  }
}

Future<void> _openReviewerProfile(
  BuildContext context,
  ReceivedRating rating,
) async {
  if (rating.reviewerRole == 'tour_operator') {
    final member = CommunityMember(
      id: rating.reviewerId,
      name: rating.reviewerName,
      role: 'tour_operator',
      profilePhoto: rating.reviewerPhoto,
      location: '',
      biography: '',
      ratingAverage: 0,
      ratingCount: 0,
      joinedAt: null,
    );

    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ProviderProfilePage(member: member)),
    );
    return;
  }

  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder:
          (_) => TouristPublicProfilePage(
            touristId: rating.reviewerId,
            initialName: rating.reviewerName,
            initialPhoto: rating.reviewerPhoto,
          ),
    ),
  );
}

class TouristPublicProfilePage extends StatefulWidget {
  const TouristPublicProfilePage({
    super.key,
    required this.touristId,
    required this.initialName,
    required this.initialPhoto,
  });

  final int touristId;
  final String initialName;
  final String initialPhoto;

  @override
  State<TouristPublicProfilePage> createState() =>
      _TouristPublicProfilePageState();
}

class _TouristPublicProfilePageState extends State<TouristPublicProfilePage> {
  late Future<CommunityMember> _profile;

  @override
  void initState() {
    super.initState();
    _profile = CommunityService.instance.fetchTourist(widget.touristId);
  }

  void _retry() {
    setState(() {
      _profile = CommunityService.instance.fetchTourist(widget.touristId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4EEE1),
      body: FutureBuilder<CommunityMember>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_search_outlined,
                        size: 52,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tourist profile could not be loaded.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 15),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final tourist = snapshot.data!;
          final displayName =
              tourist.name.trim().isNotEmpty
                  ? tourist.name.trim()
                  : widget.initialName.trim();
          final photoUrl =
              tourist.profilePhotoUrl.isNotEmpty
                  ? tourist.profilePhotoUrl
                  : AuthService.storageUrl(widget.initialPhoto);
          final country = tourist.country.trim();
          final about = tourist.biography.trim();
          final joinedLabel = _joinedAgoLabel(tourist.joinedAt);

          final initials =
              displayName
                  .split(RegExp(r'\s+'))
                  .where((part) => part.isNotEmpty)
                  .take(2)
                  .map((part) => part[0].toUpperCase())
                  .join();

          Widget photoFallback() {
            return Container(
              alignment: Alignment.center,
              color: colors.primaryContainer,
              child: Text(
                initials,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 292,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF165B5D),
                foregroundColor: Colors.white,
                title: const Text('Traveller Profile'),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0E4446),
                              Color(0xFF165B5D),
                              Color(0xFF2E7472),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -52,
                        top: 64,
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(.07),
                              width: 28,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -35,
                        bottom: -46,
                        child: Container(
                          width: 155,
                          height: 155,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(.035),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        right: 22,
                        bottom: 24,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 116,
                              height: 116,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.primary,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.20),
                                    blurRadius: 22,
                                    offset: const Offset(0, 9),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child:
                                    photoUrl.isEmpty
                                        ? photoFallback()
                                        : Image.network(
                                          photoUrl,
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.medium,
                                          errorBuilder:
                                              (_, __, ___) => photoFallback(),
                                        ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            height: 1.08,
                                            letterSpacing: -.45,
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Traveller',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withOpacity(
                                              .76,
                                            ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (country.isNotEmpty)
                      _TravellerLocationCard(
                        country: country,
                        joinedLabel: joinedLabel,
                      )
                    else
                      _TravellerMemberCard(joinedLabel: joinedLabel),
                    const SizedBox(height: 18),
                    _TravellerPassportCard(
                      name: displayName,
                      country: country,
                      joinedLabel: joinedLabel,
                    ),
                    const SizedBox(height: 18),
                    _TravellerSectionCard(
                      icon: Icons.person_outline_rounded,
                      title: 'About Me',
                      child: Text(
                        about.isNotEmpty
                            ? about
                            : 'This traveller has not added a public bio yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: colors.onSurface.withOpacity(.76),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF165B5D),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.airplane_ticket_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Traveller Passport',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'A public travel identity for safari reviews and community activity.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.72),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TravellerLocationCard extends StatelessWidget {
  const _TravellerLocationCard({
    required this.country,
    required this.joinedLabel,
  });

  final String country;
  final String joinedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withOpacity(.55)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _WorldTravellerFlag(countryName: country),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Based in',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface.withOpacity(.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  country,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              joinedLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF165B5D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravellerMemberCard extends StatelessWidget {
  const _TravellerMemberCard({required this.joinedLabel});

  final String joinedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined),
          const SizedBox(width: 10),
          Text(
            joinedLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TravellerPassportCard extends StatelessWidget {
  const _TravellerPassportCard({
    required this.name,
    required this.country,
    required this.joinedLabel,
  });

  final String name;
  final String country;
  final String joinedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F3E8), Color(0xFFEDE4D3)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9CDB8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.airplane_ticket_outlined,
                color: Color(0xFF165B5D),
              ),
              const SizedBox(width: 9),
              Text(
                'TRAVELLER PASSPORT',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF165B5D),
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.public_outlined,
                size: 18,
                color: Color(0xFF165B5D),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  country.isEmpty ? 'Global traveller' : country,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 17,
                color: Color(0xFF165B5D),
              ),
              const SizedBox(width: 7),
              Text(
                joinedLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TravellerSectionCard extends StatelessWidget {
  const _TravellerSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withOpacity(.55)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0EC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF165B5D), size: 21),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _WorldTravellerFlag extends StatelessWidget {
  const _WorldTravellerFlag({required this.countryName});

  final String countryName;

  @override
  Widget build(BuildContext context) {
    final country = WorldCountries.byName(countryName);

    if (country == null) {
      return Container(
        width: 42,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECE3),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Icon(Icons.public_rounded, size: 18),
      );
    }

    return Container(
      width: 42,
      height: 28,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black.withOpacity(.08), width: 1),
      ),
      child: Image.network(
        country.flagUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.flag_outlined, size: 18),
      ),
    );
  }
}

class _ReviewerPhoto extends StatelessWidget {
  const _ReviewerPhoto({required this.rating});

  final ReceivedRating rating;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isOperator = rating.isOperatorReview;

    final initials =
        rating.reviewerName
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    if (isOperator) {
      final fallback = Container(
        width: 62,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          initials,
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

      if (rating.reviewerPhotoUrl.isEmpty) {
        return fallback;
      }

      return Container(
        width: 62,
        height: 44,
        padding: const EdgeInsets.all(3),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            rating.reviewerPhotoUrl,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => fallback,
          ),
        ),
      );
    }

    final fallback = Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (rating.reviewerPhotoUrl.isEmpty) {
      return fallback;
    }

    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          rating.reviewerPhotoUrl,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.size});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            index < value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: const Color(0xFFF2A900),
          ),
        ),
      ),
    );
  }
}

class _RatingsLoadingCard extends StatelessWidget {
  const _RatingsLoadingCard();

  @override
  Widget build(BuildContext context) => const PremiumSkeleton(height: 116);
}

class _RatingsErrorCard extends StatelessWidget {
  const _RatingsErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text('Ratings could not be loaded.'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _NoRatingsCard extends StatelessWidget {
  const _NoRatingsCard();

  @override
  Widget build(BuildContext context) {
    return const IllustratedEmptyState(
      title: 'No ratings yet',
      message: 'Traveller and tour operator reviews will appear here.',
      icon: Icons.reviews_outlined,
    );
  }
}

String _timeAgo(DateTime? value) {
  if (value == null) return 'Recently';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'} ago';
  }
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }
  if (difference.inDays < 7) {
    final days = difference.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }
  if (difference.inDays < 30) {
    final weeks = difference.inDays ~/ 7;
    return '$weeks week${weeks == 1 ? '' : 's'} ago';
  }
  if (difference.inDays < 365) {
    final months = difference.inDays ~/ 30;
    return '$months month${months == 1 ? '' : 's'} ago';
  }
  final years = difference.inDays ~/ 365;
  return '$years year${years == 1 ? '' : 's'} ago';
}

class _ProviderImage extends StatelessWidget {
  const _ProviderImage({
    required this.member,
    required this.operatorStyle,
    required this.size,
    this.borderWidth = 4,
    this.borderColor = Colors.white,
  });

  final CommunityMember member;
  final bool operatorStyle;
  final double size;
  final double borderWidth;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            operatorStyle ? const Color(0xFF4967C6) : const Color(0xFF147D64),
        shape: operatorStyle ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: operatorStyle ? BorderRadius.circular(size * 0.23) : null,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Text(
        _initials(member.name),
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (member.profilePhotoUrl.isEmpty) return fallback;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: operatorStyle ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: operatorStyle ? BorderRadius.circular(size * 0.23) : null,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Image.network(
        member.profilePhotoUrl,
        fit: operatorStyle ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _LoadingProviders extends StatelessWidget {
  const _LoadingProviders();

  @override
  Widget build(BuildContext context) => const AppDiscoverySkeleton();
}

class _ProviderLoadError extends StatelessWidget {
  const _ProviderLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppStatePanel(
      title: 'New providers could not be loaded',
      message: 'Check your connection and try loading the provider list again.',
      kind: AppStateKind.offline,
      onRetry: onRetry,
    );
  }
}
