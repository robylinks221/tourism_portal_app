import 'package:flutter/material.dart';

import '../services/account_management.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/session_navigation.dart';
import '../utils/text_case.dart';
import '../widgets/catalog_home_sections.dart';
import '../widgets/luxury_car_hire_home_section.dart';
import '../widgets/country_discovery_section.dart';
import '../widgets/current_user_avatar.dart';
import '../widgets/provider_discovery_sections.dart';

import 'awards_pages.dart';
import 'community_page.dart';
import 'operator_booking_details_page.dart';
import 'operator_manage_page.dart';
import 'operator_guide_team_page.dart';
import 'operator_safari_opportunities_page.dart';
import 'provider_bookings_hub_page.dart';
import '../theme/field_guide_theme.dart';

class TourOperatorHomePage extends StatefulWidget {
  const TourOperatorHomePage({super.key});

  @override
  State<TourOperatorHomePage> createState() => _TourOperatorHomePageState();
}

class _TourOperatorHomePageState extends State<TourOperatorHomePage> {
  int _selectedNavigationIndex = 0;

  int _selectedBookingFilter = 0;

  bool _acceptingBookings = true;

  bool _loadingBookings = true;

  String? _bookingError;

  List<BookingItem> _bookings = [];

  OperatorBookingSummary _summary = const OperatorBookingSummary();

  @override
  void initState() {
    super.initState();

    _loadBookingData();
  }

  Future<void> _loadBookingData() async {
    if (mounted) {
      setState(() {
        _loadingBookings = true;
        _bookingError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        BookingService.instance.fetchOperatorBookings(),
        BookingService.instance.fetchOperatorSummary(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = results[0] as List<BookingItem>;

        _summary = results[1] as OperatorBookingSummary;

        _loadingBookings = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingBookings = false;
        _bookingError = error.toString();
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBooking(BookingItem booking) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OperatorBookingDetailsPage(booking: booking),
      ),
    );

    await _loadBookingData();
  }

  void _openAwards() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AwardsHomePage()),
    );
  }

  void _openSafariOpportunities() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const OperatorSafariOpportunitiesPage(),
      ),
    );
  }

  void _openGuideTeam() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const OperatorGuideTeamPage()),
    );
  }

  Widget _selectedPage() {
    if (_selectedNavigationIndex == 1) {
      return const OperatorManagePage();
    }

    if (_selectedNavigationIndex == 2) {
      return const ProviderBookingsHubPage();
    }

    if (_selectedNavigationIndex == 3) {
      return const CommunityPage();
    }

    if (_selectedNavigationIndex == 4) {
      return _OperatorProfilePage(
        acceptingBookings: _acceptingBookings,
        onAvailabilityChanged: (value) {
          setState(() {
            _acceptingBookings = value;
          });
        },
        onSafariOpportunities: _openSafariOpportunities,
        onGuideTeam: _openGuideTeam,
        onLogout: () {
          signOutAndShowLogin(context);
        },
        onEditAccount: () => openEditAccount(context),
        onDeleteAccount: () => confirmDeleteAccount(context),
      );
    }

    return _OperatorDashboard(
      bookings: _bookings,
      summary: _summary,
      loadingBookings: _loadingBookings,
      bookingError: _bookingError,
      acceptingBookings: _acceptingBookings,
      onAvailabilityChanged: (value) {
        setState(() {
          _acceptingBookings = value;
        });
      },
      onNotificationPressed: () {
        _showMessage('You have no new notifications.');
      },
      onViewBookingsPressed: () {
        setState(() {
          _selectedNavigationIndex = 2;
        });
      },
      onManagePressed: () {
        setState(() {
          _selectedNavigationIndex = 1;
        });
      },
      onSafariOpportunitiesPressed: _openSafariOpportunities,
      onAwardsPressed: _openAwards,
      onBookingPressed: _openBooking,
      onRefresh: _loadBookingData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavigationIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedNavigationIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Manage',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Connect',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _OperatorDashboard extends StatelessWidget {
  const _OperatorDashboard({
    required this.bookings,
    required this.summary,
    required this.loadingBookings,
    required this.bookingError,
    required this.acceptingBookings,
    required this.onAvailabilityChanged,
    required this.onNotificationPressed,
    required this.onViewBookingsPressed,
    required this.onManagePressed,
    required this.onSafariOpportunitiesPressed,
    required this.onAwardsPressed,
    required this.onBookingPressed,
    required this.onRefresh,
  });

  final List<BookingItem> bookings;

  final OperatorBookingSummary summary;

  final bool loadingBookings;

  final String? bookingError;

  final bool acceptingBookings;

  final ValueChanged<bool> onAvailabilityChanged;

  final VoidCallback onNotificationPressed;

  final VoidCallback onViewBookingsPressed;

  final VoidCallback onManagePressed;

  final VoidCallback onSafariOpportunitiesPressed;

  final VoidCallback onAwardsPressed;

  final ValueChanged<BookingItem> onBookingPressed;

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    final mutedText = colors.onSurface.withOpacity(.62);

    final borderColor = colors.outline.withOpacity(isDark ? .62 : .72);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: colors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CurrentUserAvatar(
                    radius: 25,
                    backgroundColor: colors.primary.withOpacity(
                      isDark ? .18 : .13,
                    ),
                    foregroundColor: colors.primary,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning, ${(AuthService.instance.currentUser?.name?.trim().split(RegExp(r'\s+')).firstWhere((part) => part.isNotEmpty, orElse: () => 'Operator') ?? 'Operator')}!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Tour Operator',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: onNotificationPressed,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: borderColor),
                    ),
                    icon: const Badge(
                      smallSize: 8,
                      child: Icon(Icons.notifications_outlined),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),
              const CountryDiscoverySection(),
              const SizedBox(height: 30),
              const CatalogHomeSections(),
              const SizedBox(height: 30),
              const LuxuryCarHireHomeSection(),
              const SizedBox(height: 30),
              const ProviderDiscoverySections(),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDark
                            ? const [Color(0xFF23423F), Color(0xFF182F35)]
                            : const [Color(0xFFC9F0E7), Color(0xFF8AD6C4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface.withOpacity(.88),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      acceptingBookings
                                          ? const Color(0xFF2BB673)
                                          : colors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                acceptingBookings
                                    ? 'Bookings open'
                                    : 'Bookings paused',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        Switch.adaptive(
                          value: acceptingBookings,
                          onChanged: onAvailabilityChanged,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Create memorable trips.\nGrow your travel business.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Material(
                      color: Colors.white.withOpacity(.94),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: onManagePressed,
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(.08),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: colors.primary,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manage Services',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF17211F),
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tours and car hire vehicles',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF66716E),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: colors.primary,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 27),

              _SectionHeading(
                title: 'Safari Opportunities',
                actionLabel: 'View all',
                onPressed: onSafariOpportunitiesPressed,
              ),

              const SizedBox(height: 13),

              _SafariOpportunityBanner(onPressed: onSafariOpportunitiesPressed),

              const SizedBox(height: 14),

              _OperatorAwardsCard(onPressed: onAwardsPressed),

              const SizedBox(height: 28),

              Text(
                'Business Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 14),

              if (loadingBookings)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt_long_rounded,
                            value: '${summary.totalBookings}',
                            label: 'Bookings',
                            color: colors.primary,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _StatCard(
                            icon: Icons.hourglass_top_rounded,
                            value: '${summary.pendingBookings}',
                            label: 'Pending',
                            color: colors.secondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.groups_rounded,
                            value: '${summary.travellers}',
                            label: 'Travellers',
                            color: const Color(0xFF55B6C7),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _StatCard(
                            icon: Icons.payments_outlined,
                            value:
                                'USD ${summary.bookingValue.toStringAsFixed(0)}',
                            label: 'Booking Value',
                            color: colors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 29),

              _SectionHeading(
                title: 'Recent bookings',
                actionLabel: 'View all',
                onPressed: onViewBookingsPressed,
              ),

              const SizedBox(height: 14),

              if (bookingError != null)
                _ErrorCard(message: bookingError!)
              else if (loadingBookings)
                const Center(child: CircularProgressIndicator())
              else if (bookings.isEmpty)
                const _NoBookingsCard()
              else
                ...bookings
                    .take(3)
                    .map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RealBookingCard(
                          booking: booking,
                          onPressed: () {
                            onBookingPressed(booking);
                          },
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

class _OperatorAwardsCard extends StatelessWidget {
  const _OperatorAwardsCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = colors.outline.withValues(alpha: isDark ? .62 : .72);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: colors.secondary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tourist Guide Awards',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Explore categories, finalists and award winners',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: .60),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.onSurface.withValues(alpha: .38),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingsPage extends StatelessWidget {
  const _BookingsPage({
    required this.bookings,
    required this.loading,
    required this.error,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onRefresh,
    required this.onBookingPressed,
  });

  final List<BookingItem> bookings;
  final bool loading;
  final String? error;

  final int selectedFilter;

  final ValueChanged<int> onFilterSelected;

  final Future<void> Function() onRefresh;

  final ValueChanged<BookingItem> onBookingPressed;

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled'];

    final selectedStatus = filters[selectedFilter].toLowerCase();

    final filtered =
        selectedFilter == 0
            ? bookings
            : bookings
                .where((booking) => booking.status == selectedStatus)
                .toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          children: [
            const Text(
              'Bookings',
              style: TextStyle(
                color: FieldGuidePalette.ink,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Manage real traveller bookings from your safari proposals.',
              style: TextStyle(
                color: FieldGuidePalette.mutedText,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ChoiceChip(
                    label: Text(filters[index]),
                    selected: selectedFilter == index,
                    onSelected: (_) {
                      onFilterSelected(index);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            if (loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              _ErrorCard(message: error!)
            else if (filtered.isEmpty)
              const _NoBookingsCard()
            else
              ...filtered.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RealBookingCard(
                    booking: booking,
                    onPressed: () {
                      onBookingPressed(booking);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RealBookingCard extends StatelessWidget {
  const _RealBookingCard({required this.booking, required this.onPressed});

  final BookingItem booking;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);

    return Material(
      color: Colors.white.withOpacity(.76),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: FieldGuidePalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: FieldGuidePalette.primary.withOpacity(.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: FieldGuidePalette.primary,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.tourist.name.isEmpty
                              ? 'Traveller'
                              : booking.tourist.name,
                          style: const TextStyle(
                            color: FieldGuidePalette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          booking.reference,
                          style: const TextStyle(
                            color: FieldGuidePalette.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _prettyStatus(booking.status),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              Text(
                booking.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FieldGuidePalette.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    color: FieldGuidePalette.secondary,
                    size: 15,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    '${booking.travellers} traveller${booking.travellers == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: FieldGuidePalette.mutedText,
                      fontSize: 11,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${booking.currency} ${booking.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: FieldGuidePalette.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafariOpportunityBanner extends StatelessWidget {
  const _SafariOpportunityBanner({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.76),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: FieldGuidePalette.border),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Color(0x12165B5D),
                child: Icon(
                  Icons.travel_explore_rounded,
                  color: FieldGuidePalette.primary,
                ),
              ),

              SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Traveller Safari Requests',
                      style: TextStyle(
                        color: FieldGuidePalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'View requests matching your destinations and activities.',
                      style: TextStyle(
                        color: FieldGuidePalette.mutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_rounded,
                color: FieldGuidePalette.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 11),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FieldGuidePalette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: FieldGuidePalette.mutedText,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.actionLabel,
    this.onPressed,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toTitleCase(),
            style: const TextStyle(
              color: FieldGuidePalette.ink,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onPressed, child: Text(actionLabel!)),
      ],
    );
  }
}

class _NoBookingsCard extends StatelessWidget {
  const _NoBookingsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: FieldGuidePalette.primary,
            size: 32,
          ),
          SizedBox(height: 10),
          Text(
            'No bookings yet',
            style: TextStyle(
              color: FieldGuidePalette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'A booking will appear here after a traveller accepts one of your safari proposals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FieldGuidePalette.mutedText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x109B4949),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF9B4949), fontSize: 12),
      ),
    );
  }
}

class _OperatorProfilePage extends StatelessWidget {
  const _OperatorProfilePage({
    required this.acceptingBookings,
    required this.onAvailabilityChanged,
    required this.onSafariOpportunities,
    required this.onGuideTeam,
    required this.onLogout,
    required this.onEditAccount,
    required this.onDeleteAccount,
  });

  final bool acceptingBookings;

  final ValueChanged<bool> onAvailabilityChanged;

  final VoidCallback onSafariOpportunities;

  final VoidCallback onGuideTeam;

  final VoidCallback onLogout;
  final VoidCallback onEditAccount;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Center(
            child: CurrentUserAvatar(
              radius: 47,
              backgroundColor: colors.primary.withOpacity(.12),
              foregroundColor: colors.primary,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            AuthService.instance.currentUser?.name ?? 'Tour Operator',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FieldGuidePalette.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 22),

          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: acceptingBookings,
                  onChanged: onAvailabilityChanged,
                  title: const Text('Accept new bookings'),
                ),

                _ProfileTile(
                  icon: Icons.travel_explore_outlined,
                  title: 'Safari Opportunities',
                  onTap: onSafariOpportunities,
                ),

                _ProfileTile(
                  icon: Icons.groups_2_outlined,
                  title: 'Our Safari Team',
                  onTap: onGuideTeam,
                ),

                _ProfileTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Account',
                  onTap: onEditAccount,
                ),

                _ProfileTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account',
                  onTap: onDeleteAccount,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: FieldGuidePalette.primary),
      title: Text(title.toTitleCase()),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return const Color(0xFF2E7D32);

    case 'completed':
      return FieldGuidePalette.primary;

    case 'cancelled':
      return const Color(0xFF9B4949);

    default:
      return FieldGuidePalette.secondary;
  }
}

String _prettyStatus(String status) {
  return status
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
