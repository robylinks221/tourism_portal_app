import '../widgets/platform_brand_logo.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/account_management.dart';
import '../services/session_navigation.dart';
import '../utils/text_case.dart';
import '../widgets/catalog_home_sections.dart';
import '../widgets/current_user_avatar.dart';
import '../widgets/provider_discovery_sections.dart';
import 'awards_pages.dart';
import 'community_page.dart';
import 'guide_bookings_page.dart';
import 'guide_team_assignments_page.dart';
import 'guide_affiliations_page.dart';
import 'operator_manage_page.dart';
import 'operator_safari_opportunities_page.dart';
import 'provider_bookings_hub_page.dart';

class GuideHomePage extends StatefulWidget {
  const GuideHomePage({super.key});

  @override
  State<GuideHomePage> createState() => _GuideHomePageState();
}

class _GuideHomePageState extends State<GuideHomePage> {
  int _selectedNavigationIndex = 0;
  int _selectedDayIndex = 0;
  bool _acceptingBookings = true;
  bool _bookingRemindersEnabled = true;
  bool _travellerMessagesEnabled = true;
  bool _locationSharingEnabled = false;
  late _GuideProfileData _profile;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _profile = _GuideProfileData(
      fullName: user?.name ?? 'Tourist Guide',
      phone: '+256 700 123 456',
      email: user?.email ?? 'guide@tourismportal.ug',
      location: 'Kampala, Uganda',
      languages: 'English, Luganda, Swahili',
      bio:
          'Certified local guide specialising in Kampala culture, heritage, '
          'food experiences, and Nile adventures.',
    );
  }

  final List<_GuideTour> _tours = const [
    _GuideTour(
      title: 'Kampala City Walk',
      location: 'Kampala Central',
      time: '9:00 AM',
      duration: '3 hours',
      guests: 6,
      date: 'Tuesday, 11 August 2026',
      meetingPoint: 'Independence Monument, Speke Road',
      leadTraveller: 'Amina N.',
      bookingReference: 'TGU-81124',
      description:
          'Lead guests through Kampala’s historic centre, colourful markets, '
          'landmarks, and local food stops at a relaxed walking pace.',
      icon: Icons.location_city_rounded,
      lightColors: [Color(0xFFC8EEE6), Color(0xFF68BEA8)],
      darkColors: [Color(0xFF285048), Color(0xFF1C3834)],
    ),
    _GuideTour(
      title: 'Jinja Adventure',
      location: 'Jinja, Uganda',
      time: '2:00 PM',
      duration: '4 hours',
      guests: 4,
      date: 'Tuesday, 11 August 2026',
      meetingPoint: 'Source of the Nile Gardens entrance',
      leadTraveller: 'Daniel K.',
      bookingReference: 'TGU-81131',
      description:
          'Guide an energetic afternoon around Jinja with river viewpoints, '
          'local stories, photo stops, and a short kayaking introduction.',
      icon: Icons.kayaking_rounded,
      lightColors: [Color(0xFFBDEAF0), Color(0xFF55B6C7)],
      darkColors: [Color(0xFF244650), Color(0xFF19343B)],
    ),
    _GuideTour(
      title: 'Cultural Heritage Tour',
      location: 'Kasubi, Kampala',
      time: '10:30 AM',
      duration: '2 hours',
      guests: 8,
      date: 'Tuesday, 11 August 2026',
      meetingPoint: 'Kasubi Tombs visitor centre',
      leadTraveller: 'Grace M.',
      bookingReference: 'TGU-81142',
      description:
          'Introduce travellers to Buganda history, royal traditions, '
          'architecture, and respectful cultural practices at Kasubi.',
      icon: Icons.account_balance_rounded,
      lightColors: [Color(0xFFFFDEAD), Color(0xFFE8A96D)],
      darkColors: [Color(0xFF51402F), Color(0xFF382C23)],
    ),
  ];

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openTourDetails(_GuideTour tour) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => _GuideScheduleDetailsPage(
              tour: tour,
              onContactPressed: () {
                _showMessage('Contacting ${tour.leadTraveller}...');
              },
              onDirectionsPressed: () {
                _showMessage('Directions to ${tour.meetingPoint} opened.');
              },
            ),
      ),
    );
  }

  Future<void> _openTravellerReviews() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ReceivedRatingsPage()),
    );
  }

  Future<void> _openPersonalInformation() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _PersonalInformationSheet(
          profile: _profile,
          onSave: (updatedProfile) {
            setState(() {
              _profile = updatedProfile;
            });
            Navigator.pop(sheetContext);
            _showMessage('Personal information updated.');
          },
        );
      },
    );
  }

  Future<void> _openQualifications() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _QualificationsSheet(
          onCertificatePressed: (qualification) {
            Navigator.pop(sheetContext);
            _showMessage('$qualification is verified.');
          },
        );
      },
    );
  }

  Future<void> _openEarningsAndPayouts() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _EarningsAndPayoutsSheet(
          onRequestPayout: () async {
            Navigator.pop(sheetContext);

            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('Request payout?'),
                  content: const Text(
                    'UGX 420,000 will be sent to your saved Mobile Money '
                    'account within one business day.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, false);
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, true);
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            );

            if (confirmed == true && mounted) {
              _showMessage('Payout request submitted successfully.');
            }
          },
        );
      },
    );
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _GuideSettingsSheet(
          bookingRemindersEnabled: _bookingRemindersEnabled,
          travellerMessagesEnabled: _travellerMessagesEnabled,
          locationSharingEnabled: _locationSharingEnabled,
          onBookingRemindersChanged: (value) {
            setState(() {
              _bookingRemindersEnabled = value;
            });
          },
          onTravellerMessagesChanged: (value) {
            setState(() {
              _travellerMessagesEnabled = value;
            });
          },
          onLocationSharingChanged: (value) {
            setState(() {
              _locationSharingEnabled = value;
            });
          },
        );
      },
    );
  }

  Future<void> _openAwards() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AwardsHomePage()),
    );
  }

  Future<void> _openSafariOpportunities() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const OperatorSafariOpportunitiesPage(),
      ),
    );
  }

  Future<void> _openGuideBookings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const ProviderBookingsHubPage()),
    );
  }

  Future<void> _openTeamAssignments() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const GuideTeamAssignmentsPage()),
    );
  }

  Future<void> _openGuideAffiliations() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const GuideAffiliationsPage()),
    );
  }

  Future<void> _openCarHireVehicles() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => const OperatorManagePage(guideMode: true, initialTab: 1),
      ),
    );
  }

  Widget _selectedPage() {
    if (_selectedNavigationIndex == 1) {
      return const OperatorManagePage(guideMode: true, initialTab: 0);
    }

    if (_selectedNavigationIndex == 2) {
      return _SchedulePage(
        tours: _tours,
        selectedDayIndex: _selectedDayIndex,
        onDaySelected: (index) {
          setState(() {
            _selectedDayIndex = index;
          });
        },
        onTourPressed: _openTourDetails,
      );
    }

    if (_selectedNavigationIndex == 3) {
      return const CommunityPage();
    }

    if (_selectedNavigationIndex == 4) {
      return _GuideProfilePage(
        guideName: _profile.fullName,
        acceptingBookings: _acceptingBookings,
        onAvailabilityChanged: (value) {
          setState(() {
            _acceptingBookings = value;
          });
        },
        onSafariOpportunitiesPressed: _openSafariOpportunities,
        onBookingsPressed: _openGuideBookings,
        onTeamAssignmentsPressed: _openTeamAssignments,
        onAffiliationsPressed: _openGuideAffiliations,
        onLogout: () {
          signOutAndShowLogin(context);
        },
        onPersonalInformationPressed: _openPersonalInformation,
        onQualificationsPressed: _openQualifications,
        onEarningsPressed: _openEarningsAndPayouts,
        onReviewsPressed: _openTravellerReviews,
        onSettingsPressed: _openSettings,
        onEditAccount: () => openEditAccount(context),
        onDeleteAccount: () => confirmDeleteAccount(context),
      );
    }

    return _GuideDashboard(
      tours: _tours,
      acceptingBookings: _acceptingBookings,
      onAvailabilityChanged: (value) {
        setState(() {
          _acceptingBookings = value;
        });
      },
      onNotificationPressed: () {
        _showMessage('You have no new notifications.');
      },
      onTourPressed: _openTourDetails,
      onViewSchedulePressed: () {
        setState(() {
          _selectedNavigationIndex = 2;
        });
      },
      onManageToursPressed: () {
        setState(() {
          _selectedNavigationIndex = 1;
        });
      },
      onSafariOpportunitiesPressed: _openSafariOpportunities,
      onBookingsPressed: _openGuideBookings,
      onCarHireVehiclesPressed: _openCarHireVehicles,
      onTeamAssignmentsPressed: _openTeamAssignments,
      onAwardsPressed: _openAwards,
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
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Manage',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
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

class _GuideDashboard extends StatelessWidget {
  const _GuideDashboard({
    required this.tours,
    required this.acceptingBookings,
    required this.onAvailabilityChanged,
    required this.onNotificationPressed,
    required this.onTourPressed,
    required this.onViewSchedulePressed,
    required this.onManageToursPressed,
    required this.onSafariOpportunitiesPressed,
    required this.onBookingsPressed,
    required this.onCarHireVehiclesPressed,
    required this.onTeamAssignmentsPressed,
    required this.onAwardsPressed,
  });

  final List<_GuideTour> tours;
  final bool acceptingBookings;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onNotificationPressed;
  final ValueChanged<_GuideTour> onTourPressed;
  final VoidCallback onViewSchedulePressed;
  final VoidCallback onManageToursPressed;
  final VoidCallback onSafariOpportunitiesPressed;
  final VoidCallback onBookingsPressed;
  final VoidCallback onCarHireVehiclesPressed;
  final VoidCallback onTeamAssignmentsPressed;
  final VoidCallback onAwardsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = colors.onSurface.withOpacity(0.62);
    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CurrentUserAvatar(
                  radius: 25,
                  backgroundColor: colors.primary.withOpacity(
                    isDark ? 0.18 : 0.13,
                  ),
                  foregroundColor: colors.primary,
                ),
                  const SizedBox(width: 7),
                  const PlatformBrandLogo(size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, ${(AuthService.instance.currentUser?.name?.trim().split(RegExp(r'\s+')).firstWhere((part) => part.isNotEmpty, orElse: () => 'Guide') ?? 'Guide')}!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: colors.secondary,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Kampala, Uganda',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedText,
                            ),
                          ),
                        ],
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
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(isDark ? 0.10 : 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -45,
                    right: -30,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.04 : 0.20),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Column(
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
                              color: colors.surface.withOpacity(0.88),
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
                                      ? 'Available'
                                      : 'Unavailable',
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
                        'Ready to lead another\nunforgettable journey?',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w300,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Top-rated local guide',
                            style: theme.textTheme.labelMedium?.copyWith(
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
            const SizedBox(height: 14),
            _GuideManageServicesCard(onPressed: onManageToursPressed),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _GuideProviderAction(
                    icon: Icons.travel_explore_rounded,
                    title: 'Safari Opportunities',
                    subtitle: 'Traveller requests',
                    onPressed: onSafariOpportunitiesPressed,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _GuideProviderAction(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Bookings',
                    subtitle: 'Independent bookings',
                    onPressed: onBookingsPressed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            _GuideProviderAction(
              icon: Icons.directions_car_outlined,
              title: 'Car Hire / Vehicles',
              subtitle: 'Manage your vehicles',
              onPressed: onCarHireVehiclesPressed,
            ),
            const SizedBox(height: 11),
            _GuideTeamAssignmentAction(onPressed: onTeamAssignmentsPressed),
            const SizedBox(height: 11),
            _GuideAwardsAction(onPressed: onAwardsPressed),
            const SizedBox(height: 27),
            Text(
              'Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w300,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.map_rounded,
                    value: '24',
                    label: 'Tours',
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _StatCard(
                    icon: Icons.groups_rounded,
                    value: '186',
                    label: 'Travellers',
                    color: Color(0xFFDD8B43),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: _StatCard(
                    icon: Icons.star_rounded,
                    value: 'Live',
                    label: 'Ratings in Connect',
                    color: Color(0xFFFFB548),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.payments_outlined,
                    value: 'UGX 840K',
                    label: 'This month',
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 29),
            _SectionHeading(
              title: 'Today’s assignments',
              actionLabel: 'View schedule',
              onPressed: onViewSchedulePressed,
            ),
            const SizedBox(height: 14),
            ...tours
                .take(2)
                .map(
                  (tour) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _TourListCard(
                      tour: tour,
                      onPressed: () {
                        onTourPressed(tour);
                      },
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            const CatalogHomeSections(),
            const SizedBox(height: 30),
            const ProviderDiscoverySections(),
          ],
        ),
      ),
    );
  }
}

class _SchedulePage extends StatelessWidget {
  const _SchedulePage({
    required this.tours,
    required this.selectedDayIndex,
    required this.onDaySelected,
    required this.onTourPressed,
  });

  final List<_GuideTour> tours;
  final int selectedDayIndex;
  final ValueChanged<int> onDaySelected;
  final ValueChanged<_GuideTour> onTourPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mutedText = colors.onSurface.withOpacity(0.62);

    const days = [
      _ScheduleDay(day: 'MON', date: '11'),
      _ScheduleDay(day: 'TUE', date: '12'),
      _ScheduleDay(day: 'WED', date: '13'),
      _ScheduleDay(day: 'THU', date: '14'),
      _ScheduleDay(day: 'FRI', date: '15'),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'August 2026',
              style: theme.textTheme.bodyMedium?.copyWith(color: mutedText),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 10);
                },
                itemBuilder: (context, index) {
                  final item = days[index];
                  final isSelected = selectedDayIndex == index;

                  return InkWell(
                    onTap: () => onDaySelected(index),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 59,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              isSelected
                                  ? colors.primary
                                  : colors.outline.withOpacity(0.55),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.day,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected ? colors.onPrimary : mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.date,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  isSelected
                                      ? colors.onPrimary
                                      : colors.onSurface,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            Text(
              selectedDayIndex == 0
                  ? '3 assignments scheduled'
                  : 'No assignments scheduled',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 15),
            if (selectedDayIndex == 0)
              ...tours.map(
                (tour) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TourListCard(
                    tour: tour,
                    onPressed: () {
                      onTourPressed(tour);
                    },
                  ),
                ),
              )
            else
              const _InlineEmptyState(),
          ],
        ),
      ),
    );
  }
}

class _GuideProfilePage extends StatelessWidget {
  const _GuideProfilePage({
    required this.guideName,
    required this.acceptingBookings,
    required this.onAvailabilityChanged,
    required this.onSafariOpportunitiesPressed,
    required this.onBookingsPressed,
    required this.onTeamAssignmentsPressed,
    required this.onAffiliationsPressed,
    required this.onLogout,
    required this.onPersonalInformationPressed,
    required this.onQualificationsPressed,
    required this.onEarningsPressed,
    required this.onReviewsPressed,
    required this.onSettingsPressed,
    required this.onEditAccount,
    required this.onDeleteAccount,
  });

  final String guideName;
  final bool acceptingBookings;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onSafariOpportunitiesPressed;
  final VoidCallback onBookingsPressed;
  final VoidCallback onTeamAssignmentsPressed;
  final VoidCallback onAffiliationsPressed;
  final VoidCallback onLogout;
  final VoidCallback onPersonalInformationPressed;
  final VoidCallback onQualificationsPressed;
  final VoidCallback onEarningsPressed;
  final VoidCallback onReviewsPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onEditAccount;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = colors.onSurface.withOpacity(0.62);
    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(isDark ? 0.18 : 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_pin_rounded,
                color: colors.primary,
                size: 49,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              guideName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Certified local experience guide',
              style: theme.textTheme.bodySmall?.copyWith(color: mutedText),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Live tourist ratings in Connect',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 27),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: acceptingBookings,
                    onChanged: onAvailabilityChanged,
                    secondary: Icon(
                      Icons.event_available_rounded,
                      color: colors.primary,
                    ),
                    title: Text(
                      'Accept new bookings',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      acceptingBookings ? 'Available' : 'Unavailable',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedText,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.travel_explore_outlined,
                    title: 'Safari Opportunities',
                    onTap: onSafariOpportunitiesPressed,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Bookings',
                    onTap: onBookingsPressed,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.groups_2_outlined,
                    title: 'Team Assignments',
                    onTap: onTeamAssignmentsPressed,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.handshake_outlined,
                    title: 'My Work & Affiliations',
                    onTap: onAffiliationsPressed,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Account',
                    onTap: onEditAccount,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Qualifications',
                    onTap: onQualificationsPressed,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.payments_outlined,
                    title: 'Earnings and payouts',
                    onTap: onEarningsPressed,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.star_outline_rounded,
                    title: 'Traveller reviews',
                    onTap: onReviewsPressed,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: onSettingsPressed,
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  _ProfileTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Account',
                    onTap: onDeleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourListCard extends StatelessWidget {
  const _TourListCard({required this.tour, required this.onPressed});

  final _GuideTour tour;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = colors.onSurface.withOpacity(0.62);
    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);
    final gradientColors = isDark ? tour.darkColors : tour.lightColors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  tour.icon,
                  color: Colors.white.withOpacity(0.86),
                  size: 39,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: colors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            tour.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      children: [
                        _TourDetail(
                          icon: Icons.schedule_rounded,
                          text: tour.time,
                        ),
                        _TourDetail(
                          icon: Icons.groups_rounded,
                          text: '${tour.guests} guests',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: mutedText, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideScheduleDetailsPage extends StatelessWidget {
  const _GuideScheduleDetailsPage({
    required this.tour,
    required this.onContactPressed,
    required this.onDirectionsPressed,
  });

  final _GuideTour tour;
  final VoidCallback onContactPressed;
  final VoidCallback onDirectionsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = colors.onSurface.withOpacity(0.62);
    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);
    final gradientColors = isDark ? tour.darkColors : tour.lightColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Safari Assignment',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(tour.icon, color: Colors.white, size: 29),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2BB673),
                            size: 15,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Confirmed',
                            style: TextStyle(
                              color: Color(0xFF195D40),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  tour.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tour.location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.90),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Assignment Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            tour.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: mutedText,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _TourInfoTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Date',
                      value: tour.date,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _TourInfoTile(
                      icon: Icons.schedule_rounded,
                      label: 'Start time',
                      value: tour.time,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _TourInfoTile(
                      icon: Icons.timelapse_rounded,
                      label: 'Duration',
                      value: tour.duration,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _TourInfoTile(
                      icon: Icons.groups_rounded,
                      label: 'Group size',
                      value: '${tour.guests} guests',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Meeting Point',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary.withOpacity(0.20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.pin_drop_outlined, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tour.meetingPoint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: colors.secondary.withOpacity(0.13),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: colors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.leadTraveller,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lead traveller • ${tour.bookingReference}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: onContactPressed,
              icon: const Icon(Icons.call_outlined),
              label: const Text(
                'Contact Traveller',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onDirectionsPressed,
              icon: const Icon(Icons.directions_outlined),
              label: const Text(
                'Open Directions',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInformationSheet extends StatefulWidget {
  const _PersonalInformationSheet({
    required this.profile,
    required this.onSave,
  });

  final _GuideProfileData profile;
  final ValueChanged<_GuideProfileData> onSave;

  @override
  State<_PersonalInformationSheet> createState() =>
      _PersonalInformationSheetState();
}

class _PersonalInformationSheetState extends State<_PersonalInformationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _locationController;
  late final TextEditingController _languagesController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _emailController = TextEditingController(text: widget.profile.email);
    _locationController = TextEditingController(text: widget.profile.location);
    _languagesController = TextEditingController(
      text: widget.profile.languages,
    );
    _bioController = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _languagesController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }

    if (!value!.contains('@') || !value.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _save() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.onSave(
      _GuideProfileData(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        location: _locationController.text.trim(),
        languages: _languagesController.text.trim(),
        bio: _bioController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mutedText = colors.onSurface.withOpacity(0.62);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.70,
        maxChildSize: 0.97,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const _BottomSheetHandle(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SheetHeader(
                            title: 'Personal information',
                            subtitle: 'Keep your public guide profile current.',
                            onClose: () {
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 43,
                                  backgroundColor: colors.primary.withOpacity(
                                    0.13,
                                  ),
                                  child: Icon(
                                    Icons.person_pin_rounded,
                                    color: colors.primary,
                                    size: 43,
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: colors.onPrimary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            validator: _requiredValidator,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: _requiredValidator,
                            decoration: const InputDecoration(
                              labelText: 'Phone number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _emailValidator,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _locationController,
                            textInputAction: TextInputAction.next,
                            validator: _requiredValidator,
                            decoration: const InputDecoration(
                              labelText: 'Base location',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _languagesController,
                            textInputAction: TextInputAction.next,
                            validator: _requiredValidator,
                            decoration: const InputDecoration(
                              labelText: 'Languages',
                              hintText: 'English, Luganda, Swahili',
                              prefixIcon: Icon(Icons.translate_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _bioController,
                            minLines: 3,
                            maxLines: 5,
                            validator: _requiredValidator,
                            decoration: const InputDecoration(
                              labelText: 'Short bio',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'These details are visible to travellers who book '
                            'your tours.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedText,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _save,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _QualificationsSheet extends StatelessWidget {
  const _QualificationsSheet({required this.onCertificatePressed});

  final ValueChanged<String> onCertificatePressed;

  static const List<_GuideQualification> _qualifications = [
    _GuideQualification(
      title: 'Uganda Tourism Board Guide Licence',
      issuer: 'Uganda Tourism Board',
      detail: 'Licence UTB-GD-20418 • Valid until May 2028',
      icon: Icons.workspace_premium_outlined,
    ),
    _GuideQualification(
      title: 'First Aid and CPR',
      issuer: 'Uganda Red Cross Society',
      detail: 'Certificate URCS-FA-9031 • Valid until January 2027',
      icon: Icons.medical_services_outlined,
    ),
    _GuideQualification(
      title: 'Cultural Heritage Interpretation',
      issuer: 'Makerere University',
      detail: 'Completed November 2024',
      icon: Icons.account_balance_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mutedText = colors.onSurface.withOpacity(0.62);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.64,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _BottomSheetHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetHeader(
                        title: 'Qualifications',
                        subtitle:
                            'Licences and training on your guide profile.',
                        onClose: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.verified_user_rounded,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fully Verified Guide',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'All 3 credentials are active.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.check_circle_rounded,
                              color: colors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Verified Credentials',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ..._qualifications.map(
                        (qualification) => Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: _QualificationCard(
                            qualification: qualification,
                            onPressed: () {
                              onCertificatePressed(qualification.title);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
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

class _EarningsAndPayoutsSheet extends StatelessWidget {
  const _EarningsAndPayoutsSheet({required this.onRequestPayout});

  final VoidCallback onRequestPayout;

  static const List<_PayoutRecord> _payouts = [
    _PayoutRecord(
      date: '3 August 2026',
      reference: 'PAY-080326',
      amount: 'UGX 680,000',
      status: 'Paid',
    ),
    _PayoutRecord(
      date: '20 July 2026',
      reference: 'PAY-072026',
      amount: 'UGX 540,000',
      status: 'Paid',
    ),
    _PayoutRecord(
      date: '6 July 2026',
      reference: 'PAY-070626',
      amount: 'UGX 765,000',
      status: 'Paid',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = colors.onSurface.withOpacity(0.62);
    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.70,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _BottomSheetHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetHeader(
                        title: 'Earnings and payouts',
                        subtitle: 'Review earnings and request withdrawals.',
                        onClose: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isDark
                                    ? const [
                                      Color(0xFF24534E),
                                      Color(0xFF173936),
                                    ]
                                    : const [
                                      Color(0xFF26B5A5),
                                      Color(0xFF148D81),
                                    ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available to withdraw',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.84),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'UGX 420,000',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 19),
                            SizedBox(
                              width: double.infinity,
                              height: 49,
                              child: FilledButton.icon(
                                onPressed: onRequestPayout,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF126F66),
                                ),
                                icon: const Icon(Icons.arrow_upward_rounded),
                                label: const Text(
                                  'Request Payout',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _EarningMetric(
                              label: 'This month',
                              value: 'UGX 840K',
                              icon: Icons.calendar_month_outlined,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EarningMetric(
                              label: 'Completed tours',
                              value: '12',
                              icon: Icons.check_circle_outline_rounded,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Payout Method',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.secondary.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.phone_android_rounded,
                                color: colors.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MTN Mobile Money',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+256 700 ••• 456',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Primary',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recent Payouts',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < _payouts.length;
                              index++
                            ) ...[
                              _PayoutRecordTile(record: _payouts[index]),
                              if (index != _payouts.length - 1)
                                Divider(height: 1, color: theme.dividerColor),
                            ],
                          ],
                        ),
                      ),
                    ],
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toTitleCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.62),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
        ),
      ],
    );
  }
}

class _QualificationCard extends StatelessWidget {
  const _QualificationCard({
    required this.qualification,
    required this.onPressed,
  });

  final _GuideQualification qualification;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = colors.onSurface.withOpacity(0.62);
    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  qualification.icon,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            qualification.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF2BB673),
                          size: 19,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      qualification.issuer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      qualification.detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedText,
                        height: 1.35,
                      ),
                    ),
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

class _EarningMetric extends StatelessWidget {
  const _EarningMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.borderColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 21),
          const SizedBox(height: 11),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutRecordTile extends StatelessWidget {
  const _PayoutRecordTile({required this.record});

  final _PayoutRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mutedText = colors.onSurface.withOpacity(0.62);

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2BB673).withOpacity(0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.south_west_rounded,
              color: Color(0xFF2BB673),
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.reference,
                  style: theme.textTheme.labelSmall?.copyWith(color: mutedText),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.amount,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                record.status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF2BB673),
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

class _GuideSettingsSheet extends StatefulWidget {
  const _GuideSettingsSheet({
    required this.bookingRemindersEnabled,
    required this.travellerMessagesEnabled,
    required this.locationSharingEnabled,
    required this.onBookingRemindersChanged,
    required this.onTravellerMessagesChanged,
    required this.onLocationSharingChanged,
  });

  final bool bookingRemindersEnabled;
  final bool travellerMessagesEnabled;
  final bool locationSharingEnabled;
  final ValueChanged<bool> onBookingRemindersChanged;
  final ValueChanged<bool> onTravellerMessagesChanged;
  final ValueChanged<bool> onLocationSharingChanged;

  @override
  State<_GuideSettingsSheet> createState() => _GuideSettingsSheetState();
}

class _GuideSettingsSheetState extends State<_GuideSettingsSheet> {
  late bool _bookingRemindersEnabled;
  late bool _travellerMessagesEnabled;
  late bool _locationSharingEnabled;

  @override
  void initState() {
    super.initState();
    _bookingRemindersEnabled = widget.bookingRemindersEnabled;
    _travellerMessagesEnabled = widget.travellerMessagesEnabled;
    _locationSharingEnabled = widget.locationSharingEnabled;
  }

  void _setBookingReminders(bool value) {
    setState(() {
      _bookingRemindersEnabled = value;
    });
    widget.onBookingRemindersChanged(value);
  }

  void _setTravellerMessages(bool value) {
    setState(() {
      _travellerMessagesEnabled = value;
    });
    widget.onTravellerMessagesChanged(value);
  }

  void _setLocationSharing(bool value) {
    setState(() {
      _locationSharingEnabled = value;
    });
    widget.onLocationSharingChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mutedText = colors.onSurface.withOpacity(0.62);
    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.60,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _BottomSheetHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settings',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: -0.4,
                                      ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Choose how the guide app works for you.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SettingsSectionLabel(
                        label: 'Notifications',
                        color: mutedText,
                      ),
                      const SizedBox(height: 9),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              value: _bookingRemindersEnabled,
                              onChanged: _setBookingReminders,
                              secondary: Icon(
                                Icons.alarm_outlined,
                                color: colors.primary,
                              ),
                              title: const Text('Tour reminders'),
                              subtitle: Text(
                                'Get an alert before each scheduled tour.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedText,
                                ),
                              ),
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            SwitchListTile.adaptive(
                              value: _travellerMessagesEnabled,
                              onChanged: _setTravellerMessages,
                              secondary: Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: colors.primary,
                              ),
                              title: const Text('Traveller messages'),
                              subtitle: Text(
                                'Receive alerts when travellers contact you.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SettingsSectionLabel(
                        label: 'Privacy and safety',
                        color: mutedText,
                      ),
                      const SizedBox(height: 9),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor),
                        ),
                        child: SwitchListTile.adaptive(
                          value: _locationSharingEnabled,
                          onChanged: _setLocationSharing,
                          secondary: Icon(
                            Icons.location_on_outlined,
                            color: colors.primary,
                          ),
                          title: const Text('Live location during tours'),
                          subtitle: Text(
                            'Share your location only while a tour is active.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SettingsSectionLabel(
                        label: 'App preferences',
                        color: mutedText,
                      ),
                      const SizedBox(height: 9),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.brightness_6_outlined,
                                color: colors.primary,
                              ),
                              title: const Text('Appearance'),
                              subtitle: Text(
                                'Follows your device theme',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedText,
                                ),
                              ),
                              trailing: Text(
                                'System',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              leading: Icon(
                                Icons.language_rounded,
                                color: colors.primary,
                              ),
                              title: const Text('Language'),
                              trailing: Text(
                                'English',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
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

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: colors.onSurface.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toTitleCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _TourInfoTile extends StatelessWidget {
  const _TourInfoTile({
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
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 21),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withOpacity(0.58),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourDetail extends StatelessWidget {
  const _TourDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.secondary, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GuideAwardsAction extends StatelessWidget {
  const _GuideAwardsAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = colors.outline.withValues(alpha: isDark ? 0.62 : 0.72);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: colors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tourist Guide Awards',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'View categories, finalists and winners',
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

class _GuideManageServicesCard extends StatelessWidget {
  const _GuideManageServicesCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = colors.outline.withValues(alpha: isDark ? 0.62 : 0.72);

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
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: colors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Services',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manage your guide tours and car hire vehicles',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: .60),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.onSurface.withValues(alpha: .36),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideProviderAction extends StatelessWidget {
  const _GuideProviderAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = colors.outline.withValues(alpha: isDark ? 0.62 : 0.72);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 122),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: colors.primary, size: 21),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideTeamAssignmentAction extends StatelessWidget {
  const _GuideTeamAssignmentAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = colors.outline.withValues(alpha: isDark ? 0.62 : 0.72);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.groups_2_outlined,
                  color: colors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Assignments',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Safaris assigned to you by tour operators',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.onSurface.withValues(alpha: 0.38),
                size: 16,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 13),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.62),
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
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title.toTitleCase(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onPressed,
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: colors.primary, size: 21),
      ),
      title: Text(
        title.toTitleCase(),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: colors.onSurface.withOpacity(0.42),
        size: 16,
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withOpacity(0.55)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, color: colors.primary, size: 45),
          const SizedBox(height: 15),
          Text(
            'Your Day Is Open',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'There are no safari assignments scheduled for this day.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTour {
  const _GuideTour({
    required this.title,
    required this.location,
    required this.time,
    required this.duration,
    required this.guests,
    required this.date,
    required this.meetingPoint,
    required this.leadTraveller,
    required this.bookingReference,
    required this.description,
    required this.icon,
    required this.lightColors,
    required this.darkColors,
  });

  final String title;
  final String location;
  final String time;
  final String duration;
  final int guests;
  final String date;
  final String meetingPoint;
  final String leadTraveller;
  final String bookingReference;
  final String description;
  final IconData icon;
  final List<Color> lightColors;
  final List<Color> darkColors;
}

class _GuideProfileData {
  const _GuideProfileData({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.location,
    required this.languages,
    required this.bio,
  });

  final String fullName;
  final String phone;
  final String email;
  final String location;
  final String languages;
  final String bio;
}

class _GuideQualification {
  const _GuideQualification({
    required this.title,
    required this.issuer,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String issuer;
  final String detail;
  final IconData icon;
}

class _PayoutRecord {
  const _PayoutRecord({
    required this.date,
    required this.reference,
    required this.amount,
    required this.status,
  });

  final String date;
  final String reference;
  final String amount;
  final String status;
}

class _ScheduleDay {
  const _ScheduleDay({required this.day, required this.date});

  final String day;
  final String date;
}
