import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/catalog_item.dart';
import '../models/operator_management.dart';
import '../models/safari_mood.dart';
import '../services/api_exception.dart';
import '../services/catalog_service.dart';
import '../services/operator_management_service.dart';
import '../utils/text_case.dart';

class OperatorManagePage extends StatefulWidget {
  const OperatorManagePage({
    super.key,
    this.guideMode = false,
    this.initialTab = 0,
  });

  final bool guideMode;
  final int initialTab;

  @override
  State<OperatorManagePage> createState() => _OperatorManagePageState();
}

class _OperatorManagePageState extends State<OperatorManagePage> {
  late int _selectedManageTab;
  OperatorManagementData? _management;
  TourismCatalog? _catalog;
  String? _error;
  bool _loading = true;
  bool _changingCarHire = false;

  @override
  void initState() {
    super.initState();
    _selectedManageTab = widget.initialTab.clamp(0, 1);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        OperatorManagementService.instance.fetch(),
        CatalogService.instance.fetchCatalog(),
      ]);
      if (!mounted) return;
      setState(() {
        _management = results[0] as OperatorManagementData;
        _catalog = results[1] as TourismCatalog;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleCarHire(bool enabled) async {
    if (_changingCarHire) return;
    setState(() => _changingCarHire = true);
    try {
      await OperatorManagementService.instance.setCarHireEnabled(enabled);
      await _load();
      if (mounted) {
        _message(enabled ? 'Car hire activated.' : 'Car hire deactivated.');
      }
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _changingCarHire = false);
    }
  }

  Future<void> _editTour([OperatorTour? tour]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _TourEditor(
            tour: tour,
            catalog: _catalog!,
            guideMode: widget.guideMode,
          ),
    );
    if (saved == true) await _load();
  }

  Future<void> _editVehicle([CarHireVehicle? vehicle]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _VehicleEditor(vehicle: vehicle),
    );
    if (saved == true) await _load();
  }

  Future<void> _deleteTour(OperatorTour tour) async {
    if (!await _confirmDelete(tour.name)) return;
    try {
      await OperatorManagementService.instance.deleteTour(tour);
      await _load();
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _deleteVehicle(CarHireVehicle vehicle) async {
    if (!await _confirmDelete(vehicle.name)) return;
    try {
      await OperatorManagementService.instance.deleteVehicle(vehicle);
      await _load();
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Delete $name?'),
                content: const Text(
                  'This action permanently removes this item.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final toursSection = _ToursSection(
      tours: _management?.tours ?? const [],
      guideMode: widget.guideMode,
      publishing: _management?.tourPublishing,
      onAdd: () => _editTour(),
      onEdit: _editTour,
      onDelete: _deleteTour,
      onRefresh: _load,
    );

    final colors = Theme.of(context).colorScheme;
    final title = widget.guideMode ? 'Manage Services' : 'Manage Services';

    return Scaffold(
      backgroundColor: const Color(0xFFF4EEE1),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _ManagePremiumHeader(
                title: title,
                subtitle: widget.guideMode
                    ? 'Control the services travellers can discover and book from you.'
                    : 'Manage your published safaris and car hire services.',
                onBack: () => Navigator.maybePop(context),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _ManageSegmentedTabs(
                selectedIndex: _selectedManageTab,
                firstLabel: 'Tours',
                secondLabel: 'Car Hire',
                onChanged: (index) {
                  setState(() {
                    _selectedManageTab = index;
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF165B5D),
                      ),
                    )
                  : _error != null
                      ? _ErrorState(
                          message: _error!,
                          onRetry: _load,
                        )
                      : _selectedManageTab == 0
                          ? toursSection
                          : _CarHireSection(
                              enabled: _management!.carHireEnabled,
                              changing: _changingCarHire,
                              vehicles: _management!.vehicles,
                              onToggle: _toggleCarHire,
                              onAdd: () => _editVehicle(),
                              onEdit: _editVehicle,
                              onDelete: _deleteVehicle,
                              onRefresh: _load,
                            ),
            ),
          ],
        ),
      ),
    );
  }

}


class _ManagePremiumHeader extends StatelessWidget {
  const _ManagePremiumHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primary.withOpacity(.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.055),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: primary.withOpacity(.07),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF17211F),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.55,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F7975),
                    height: 1.42,
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

class _ManageSegmentedTabs extends StatelessWidget {
  const _ManageSegmentedTabs({
    required this.selectedIndex,
    required this.firstLabel,
    required this.secondLabel,
    required this.onChanged,
  });

  final int selectedIndex;
  final String firstLabel;
  final String secondLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: primary.withOpacity(.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ManageTabButton(
              label: firstLabel,
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _ManageTabButton(
              label: secondLabel,
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageTabButton extends StatelessWidget {
  const _ManageTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);

    return Material(
      color: selected ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}


class _ToursSection extends StatelessWidget {
  const _ToursSection({
    required this.tours,
    required this.guideMode,
    required this.publishing,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<OperatorTour> tours;
  final bool guideMode;
  final TourPublishingContext? publishing;
  final VoidCallback onAdd;
  final ValueChanged<OperatorTour> onEdit;
  final ValueChanged<OperatorTour> onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF165B5D),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          if (guideMode && publishing != null) ...[
            _GuidePublishingStatusCard(
              publishing: publishing!,
            ),
            const SizedBox(height: 12),
          ],

          _PremiumServiceIntroCard(
            eyebrow: guideMode ? 'GUIDE TOURS' : 'SAFARI TOURS',
            title: guideMode
                ? 'Create experiences travellers can book with you'
                : 'Build and publish your safari packages',
            description: guideMode
                ? 'Add your own guide-led experiences, pricing, itinerary, activities and destinations.'
                : 'Keep your tours organised, current and ready for travellers.',
            actionLabel: guideMode ? 'Add Tour' : 'Add Tour',
            onAction: onAdd,
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Text(
                guideMode ? 'Your Tours' : 'Published Tours',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF17211F),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF165B5D).withOpacity(.07),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tours.length}',
                  style: const TextStyle(
                    color: Color(0xFF165B5D),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (tours.isEmpty)
            _PremiumEmptyState(
              title: guideMode ? 'No tours yet' : 'No safari tours yet',
              message: guideMode
                  ? 'Create your first guide-led experience and publish it when you are ready.'
                  : 'Add your first safari package to start building your catalogue.',
              actionLabel: 'Add Tour',
              onAction: onAdd,
            )
          else
            ...tours.map(
              (tour) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TourCard(
                  tour: tour,
                  onEdit: () => onEdit(tour),
                  onDelete: () => onDelete(tour),
                ),
              ),
            ),
        ],
      ),
    );
  }

}

class _CarHireSection extends StatelessWidget {
  const _CarHireSection({
    super.key,
    required this.enabled,
    required this.changing,
    required this.vehicles,
    required this.onToggle,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  final bool enabled;
  final bool changing;
  final List<CarHireVehicle> vehicles;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAdd;
  final ValueChanged<CarHireVehicle> onEdit;
  final ValueChanged<CarHireVehicle> onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF165B5D);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          const _ManageSectionEyebrow(
            text: 'CAR HIRE MANAGEMENT',
          ),
          const SizedBox(height: 10),
          _PremiumCarHireStatusCard(
            enabled: enabled,
            changing: changing,
            onToggle: onToggle,
          ),

          const SizedBox(height: 18),

          if (enabled) ...[
            _PremiumServiceIntroCard(
              eyebrow: 'CAR HIRE',
              title: 'Manage your available safari vehicles',
              description:
                  'Add vehicles, set daily pricing and control which vehicles travellers can request.',
              actionLabel: 'Add Vehicle',
              onAction: onAdd,
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Text(
                  'Your Vehicles',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF17211F),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(.07),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${vehicles.length}',
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (vehicles.isEmpty)
              _PremiumEmptyState(
                title: 'No vehicles added',
                message:
                    'Add your first vehicle to make it available for safari car hire.',
                actionLabel: 'Add Vehicle',
                onAction: onAdd,
              )
            else
              ...vehicles.map(
                (vehicle) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _VehicleCard(
                    vehicle: vehicle,
                    onEdit: () => onEdit(vehicle),
                    onDelete: () => onDelete(vehicle),
                  ),
                ),
              ),
          ] else
            _PremiumEmptyState(
              title: 'Car Hire is turned off',
              message:
                  'Activate Car Hire when you are ready for travellers to discover and request your vehicles.',
              actionLabel: 'Activate Car Hire',
              onAction: () => onToggle(true),
            ),
        ],
      ),
    );
  }

}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.tour,
    required this.onEdit,
    required this.onDelete,
  });

  final OperatorTour tour;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF165B5D);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary.withOpacity(.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _NetworkImage(
                  url: tour.imageUrl,
                  height: 150,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xB9000000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 54,
                  bottom: 13,
                  child: Text(
                    tour.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                ),
                Positioned(
                  top: 11,
                  right: 11,
                  child: _PremiumItemMenu(
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MiniInfoPill(
                      text:
                          '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _money(tour.currency, tour.price),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                if (tour.destinationNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
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
                          tour.destinationNames.join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF69736F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                Divider(
                  height: 1,
                  color: primary.withOpacity(.06),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _StatusBadge(
                      active: tour.isActive,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onEdit,
                      child: const Text(
                        'Edit Tour',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final CarHireVehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF165B5D);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary.withOpacity(.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            height: 168,
            child: _NetworkImage(
              url: vehicle.imageUrl,
              height: 168,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF17211F),
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                      ),
                      _PremiumItemMenu(
                        onEdit: onEdit,
                        onDelete: onDelete,
                        dark: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${_money(vehicle.currency, vehicle.pricePerDay)} / day',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    [
                      if (vehicle.seats != null)
                        '${vehicle.seats} seats',
                      if (vehicle.transmission?.isNotEmpty == true)
                        vehicle.transmission!,
                      if (vehicle.fuelType?.isNotEmpty == true)
                        vehicle.fuelType!,
                    ].join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6D7672),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _StatusBadge(
                        active: vehicle.isAvailable,
                        activeLabel: 'Available',
                        inactiveLabel: 'Unavailable',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onEdit,
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w900,
                          ),
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
    );
  }
}




class _ManageSectionEyebrow extends StatelessWidget {
  const _ManageSectionEyebrow({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF165B5D),
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _PremiumServiceIntroCard extends StatelessWidget {
  const _PremiumServiceIntroCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);
    const secondary = Color(0xFFF46627);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -28,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                  letterSpacing: -.35,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(.70),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumCarHireStatusCard extends StatelessWidget {
  const _PremiumCarHireStatusCard({
    required this.enabled,
    required this.changing,
    required this.onToggle,
  });

  final bool enabled;
  final bool changing;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary.withOpacity(.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.car_rental_rounded,
              color: primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Car Hire Service',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF17211F),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  enabled
                      ? 'Active and visible to travellers'
                      : 'Currently hidden from travellers',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: enabled
                        ? primary
                        : const Color(0xFF727B77),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: changing ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

class _PremiumEmptyState extends StatelessWidget {
  const _PremiumEmptyState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: primary.withOpacity(.06),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: primary.withOpacity(.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_business_outlined,
              color: primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF707A76),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              shape: const StadiumBorder(),
              side: BorderSide(
                color: primary.withOpacity(.26),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumItemMenu extends StatelessWidget {
  const _PremiumItemMenu({
    required this.onEdit,
    required this.onDelete,
    this.dark = true,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withOpacity(.92)
              : primary.withOpacity(.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: dark ? primary : primary,
          size: 20,
        ),
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: primary.withOpacity(.065),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TourEditor extends StatefulWidget {
  const _TourEditor({
    required this.catalog,
    required this.guideMode,
    this.tour,
  });

  final TourismCatalog catalog;
  final bool guideMode;
  final OperatorTour? tour;

  @override
  State<_TourEditor> createState() => _TourEditorState();
}

class _TourEditorState extends State<_TourEditor> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _days;
  late final TextEditingController _overview;
  late final TextEditingController _price;
  late final TextEditingController _inclusionEntry;
  late final TextEditingController _exclusionEntry;
  late final List<String> _inclusions;
  late final List<String> _exclusions;
  late final Set<int> _activityIds;
  late final Set<int> _destinationIds;
  late final Set<int> _moodIds;
  late final List<_ItineraryStopDraft> _itinerary;
  String? _imagePath;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tour = widget.tour;
    _name = TextEditingController(text: tour?.name);
    _days = TextEditingController(text: tour?.days.toString());
    _overview = TextEditingController(text: tour?.overview);
    _price = TextEditingController(
      text: tour == null ? null : _editablePrice(tour.price),
    );
    _inclusionEntry = TextEditingController();
    _exclusionEntry = TextEditingController();
    _inclusions = [...?tour?.inclusions];
    _exclusions = [...?tour?.exclusions];
    _activityIds = {...?tour?.activityIds};
    _destinationIds = {...?tour?.destinationIds};
    _moodIds = {...?tour?.moodIds};
    _itinerary =
        (tour?.itinerary ?? const <TourItineraryStop>[])
            .map(_ItineraryStopDraft.fromStop)
            .toList();
    _active = tour?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    _overview.dispose();
    _price.dispose();
    _inclusionEntry.dispose();
    _exclusionEntry.dispose();
    for (final stop in _itinerary) {
      stop.dispose();
    }
    super.dispose();
  }

  void _addItineraryStop() {
    final tourDays = int.tryParse(_days.text.trim()) ?? 0;
    final maximum = tourDays > 30 ? 30 : tourDays;
    if (maximum < 1) {
      _message('Enter the number of tour days first.');
      return;
    }
    if (_itinerary.length >= maximum) {
      _message(
        tourDays > 30
            ? 'Add up to 30 detailed itinerary days.'
            : 'The itinerary already covers every tour day.',
      );
      return;
    }
    setState(() => _itinerary.add(_ItineraryStopDraft()));
  }

  void _removeItineraryStop(int index) {
    final removed = _itinerary.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _addPackageItem({
    required TextEditingController controller,
    required List<String> target,
  }) {
    final value = controller.text.trim();
    if (value.isEmpty) return;

    final alreadyExists = target.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    if (alreadyExists) {
      _message('That item has already been added.');
      return;
    }

    setState(() {
      target.add(value);
      controller.clear();
    });
  }

  void _removePackageItem(List<String> target, int index) {
    setState(() => target.removeAt(index));
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2200,
    );
    if (image != null && mounted) setState(() => _imagePath = image.path);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (widget.tour == null && _imagePath == null) {
      _message('Select a tour image.');
      return;
    }
    if (_activityIds.isEmpty || _destinationIds.isEmpty) {
      _message('Select at least one activity and one destination.');
      return;
    }
    if (widget.catalog.moods.isNotEmpty && _moodIds.isEmpty) {
      _message('Select at least one Safari Mood for this tour.');
      return;
    }
    if (_inclusions.isEmpty) {
      _message('Add at least one item included in the tour price.');
      return;
    }
    if (_exclusions.isEmpty) {
      _message('Add at least one item not included in the tour price.');
      return;
    }
    final tourDays = int.tryParse(_days.text.trim()) ?? 0;
    if (_itinerary.length > tourDays) {
      _message('Remove itinerary days that are later than the tour duration.');
      return;
    }

    setState(() => _saving = true);
    try {
      final fields = <String, String>{
        'name': _name.text.trim(),
        'days': _days.text.trim(),
        'overview': _overview.text.trim(),
        'price': _price.text.trim(),
        'is_active': _active ? '1' : '0',
        'itinerary_present': '1',
        'inclusions_present': '1',
        'exclusions_present': '1',
      };
      for (var index = 0; index < _inclusions.length; index++) {
        fields['inclusions[$index]'] = _inclusions[index];
      }
      for (var index = 0; index < _exclusions.length; index++) {
        fields['exclusions[$index]'] = _exclusions[index];
      }
      for (var index = 0; index < _itinerary.length; index++) {
        final stop = _itinerary[index];
        fields['itinerary[$index][day]'] = '${index + 1}';
        fields['itinerary[$index][title]'] = stop.title.text.trim();
        fields['itinerary[$index][description]'] = stop.description.text.trim();
      }
      await OperatorManagementService.instance.saveTour(
        tour: widget.tour,
        imagePath: _imagePath,
        activityIds: _activityIds.toList(),
        destinationIds: _destinationIds.toList(),
        moodIds: _moodIds.toList(),
        fields: fields,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return _EditorSheet(
      title:
          widget.tour == null
              ? (widget.guideMode ? 'Add guide-led tour' : 'Add tour')
              : (widget.guideMode ? 'Edit guide-led tour' : 'Edit tour'),
      formKey: _formKey,
      children: [
        _ImagePickerField(
          localPath: _imagePath,
          existingUrl: widget.tour?.imageUrl ?? '',
          label: 'Select tour image',
          onTap: _pickImage,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _name,
          validator: _required,
          decoration: InputDecoration(
            labelText: widget.guideMode ? 'Experience name' : 'Tour name',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _days,
          keyboardType: TextInputType.number,
          validator: (value) {
            final days = int.tryParse(value ?? '');
            return days == null || days < 1
                ? 'Enter the number of days.'
                : null;
          },
          decoration: const InputDecoration(labelText: 'Number of days'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _overview,
          minLines: 5,
          maxLines: 9,
          validator:
              (value) =>
                  (value?.trim().length ?? 0) < 30
                      ? 'Write at least 30 characters.'
                      : null,
          decoration: const InputDecoration(
            labelText: 'Tour overview',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        _ItineraryBuilder(
          stops: _itinerary,
          onAdd: _addItineraryStop,
          onRemove: _removeItineraryStop,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _positiveNumber,
          decoration: const InputDecoration(
            labelText: 'Tour price',
            prefixText: 'USD ',
          ),
        ),
        const SizedBox(height: 22),
        _PackageItemsEditor(
          title: "What's Included",
          subtitle:
              'Add everything covered by the tour price, one item at a time.',
          hintText: 'Example: Park entrance fees',
          controller: _inclusionEntry,
          items: _inclusions,
          included: true,
          onAdd:
              () => _addPackageItem(
                controller: _inclusionEntry,
                target: _inclusions,
              ),
          onRemove: (index) => _removePackageItem(_inclusions, index),
        ),
        const SizedBox(height: 22),
        _PackageItemsEditor(
          title: "What's Not Included",
          subtitle: 'Add costs the traveller should expect to pay separately.',
          hintText: 'Example: International flights',
          controller: _exclusionEntry,
          items: _exclusions,
          included: false,
          onAdd:
              () => _addPackageItem(
                controller: _exclusionEntry,
                target: _exclusions,
              ),
          onRemove: (index) => _removePackageItem(_exclusions, index),
        ),
        const SizedBox(height: 22),
        _SelectionField(
          title: 'Tour activities',
          hint: 'Select from admin activities',
          items: widget.catalog.activities,
          selectedIds: _activityIds,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 18),
        _SearchableDestinationField(
          items: widget.catalog.destinations,
          selectedIds: _destinationIds,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 14),
        _CountriesCoveredSummary(
          destinations: widget.catalog.destinations,
          selectedIds: _destinationIds,
        ),
        const SizedBox(height: 18),
        _TourMoodSelectionField(
          moods: widget.catalog.moods,
          selectedIds: _moodIds,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _active,
          onChanged: (value) => setState(() => _active = value),
          title: const Text('Published'),
          subtitle: Text(
            widget.guideMode
                ? 'Travellers will see this as a guide-led tour.'
                : 'Travellers can see this tour when published.',
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save_outlined),
          label: Text(
            _saving
                ? 'Saving...'
                : widget.guideMode
                ? 'Save guide tour'
                : 'Save tour',
          ),
        ),
      ],
    );
  }
}

class _PackageItemsEditor extends StatelessWidget {
  const _PackageItemsEditor({
    required this.title,
    required this.subtitle,
    required this.hintText,
    required this.controller,
    required this.items,
    required this.included,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final String hintText;
  final TextEditingController controller;
  final List<String> items;
  final bool included;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            included
                ? colors.primaryContainer.withOpacity(.22)
                : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              included
                  ? colors.primary.withOpacity(.16)
                  : colors.outlineVariant,
        ),
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
                  color:
                      included
                          ? colors.primary.withOpacity(.12)
                          : colors.error.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  included ? Icons.check_rounded : Icons.close_rounded,
                  color: included ? colors.primary : colors.error,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAdd(),
                  decoration: InputDecoration(
                    hintText: hintText,
                    prefixIcon: Icon(
                      included
                          ? Icons.add_circle_outline_rounded
                          : Icons.remove_circle_outline_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: FilledButton(onPressed: onAdd, child: const Text('Add')),
              ),
            ],
          ),
          if (items.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              included
                  ? 'No included items added yet.'
                  : 'No excluded items added yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            for (var index = 0; index < items.length; index++) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      included
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      size: 20,
                      color: included ? colors.primary : colors.error,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        items[index],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              if (index != items.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _ItineraryStopDraft {
  _ItineraryStopDraft({String? title, String? description})
    : title = TextEditingController(text: title),
      description = TextEditingController(text: description);

  factory _ItineraryStopDraft.fromStop(TourItineraryStop stop) {
    return _ItineraryStopDraft(
      title: stop.title,
      description: stop.description,
    );
  }

  final TextEditingController title;
  final TextEditingController description;

  void dispose() {
    title.dispose();
    description.dispose();
  }
}

class _ItineraryBuilder extends StatelessWidget {
  const _ItineraryBuilder({
    required this.stops,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_ItineraryStopDraft> stops;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safari Trail',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Build the real journey, one day at a time.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add day'),
            ),
          ],
        ),
        if (stops.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(.28),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.primary.withOpacity(.15)),
            ),
            child: Text(
              'Add the places, experiences and overnight stops travellers can expect.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
        for (var index = 0; index < stops.length; index++) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(.045),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'DAY ${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remove day ${index + 1}',
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: stops[index].title,
                  validator: _required,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Day title',
                    hintText: 'Arrival and forest briefing',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: stops[index].description,
                  validator: _required,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'What happens this day?',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _VehicleEditor extends StatefulWidget {
  const _VehicleEditor({this.vehicle});

  final CarHireVehicle? vehicle;

  @override
  State<_VehicleEditor> createState() => _VehicleEditorState();
}

class _VehicleEditorState extends State<_VehicleEditor> {
  static const _amenityOptions = [
    'AC',
    'Wi-Fi',
    'Driver included',
    'Charging ports',
    'Fridge',
    'Large luggage space',
    'Child seat',
    'First aid kit',
  ];

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _seats;
  late final TextEditingController _description;
  late final Set<String> _amenities;
  String? _transmission;
  String? _fuelType;
  String? _imagePath;
  bool _available = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _name = TextEditingController(text: vehicle?.name);
    _price = TextEditingController(
      text: vehicle == null ? null : _editablePrice(vehicle.pricePerDay),
    );
    _seats = TextEditingController(text: vehicle?.seats?.toString());
    _description = TextEditingController(text: vehicle?.description);
    _amenities = {...?vehicle?.amenities};
    _transmission = vehicle?.transmission;
    _fuelType = vehicle?.fuelType;
    _available = vehicle?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _seats.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2200,
    );
    if (image != null && mounted) setState(() => _imagePath = image.path);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (widget.vehicle == null && _imagePath == null) {
      _message('Select a vehicle image.');
      return;
    }

    setState(() => _saving = true);
    try {
      await OperatorManagementService.instance.saveVehicle(
        vehicle: widget.vehicle,
        imagePath: _imagePath,
        amenities: _amenities.toList(),
        fields: {
          'name': _name.text.trim(),
          'price_per_day': _price.text.trim(),
          'seats': _seats.text.trim(),
          if (_transmission != null) 'transmission': _transmission!,
          if (_fuelType != null) 'fuel_type': _fuelType!,
          'description': _description.text.trim(),
          'is_available': _available ? '1' : '0',
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return _EditorSheet(
      title: widget.vehicle == null ? 'Add vehicle' : 'Edit vehicle',
      formKey: _formKey,
      children: [
        _ImagePickerField(
          localPath: _imagePath,
          existingUrl: widget.vehicle?.imageUrl ?? '',
          label: 'Select vehicle image',
          onTap: _pickImage,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _name,
          validator: _required,
          decoration: const InputDecoration(labelText: 'Vehicle name or type'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _positiveNumber,
          decoration: const InputDecoration(
            labelText: 'Price per day',
            prefixText: 'USD ',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _seats,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final seats = int.tryParse(value);
            return seats == null || seats < 1
                ? 'Enter a valid seat count.'
                : null;
          },
          decoration: const InputDecoration(labelText: 'Number of seats'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _transmission,
          decoration: const InputDecoration(labelText: 'Transmission'),
          items:
              const ['Automatic', 'Manual']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => _transmission = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _fuelType,
          decoration: const InputDecoration(labelText: 'Fuel type'),
          items:
              const ['Petrol', 'Diesel', 'Electric', 'Hybrid']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => _fuelType = value),
        ),
        const SizedBox(height: 18),
        Text(
          'Amenities',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _amenityOptions.map((amenity) {
                return FilterChip(
                  label: Text(amenity),
                  selected: _amenities.contains(amenity),
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _amenities.add(amenity)
                          : _amenities.remove(amenity);
                    });
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _description,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Vehicle description',
            alignLabelWithHint: true,
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _available,
          onChanged: (value) => setState(() => _available = value),
          title: const Text('Available for hire'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save vehicle'),
        ),
      ],
    );
  }
}

class _EditorSheet extends StatelessWidget {
  const _EditorSheet({
    required this.title,
    required this.formKey,
    required this.children,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .94,
        minChildSize: .68,
        builder:
            (context, controller) => Form(
              key: formKey,
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title.toTitleCase(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...children,
                ],
              ),
            ),
      ),
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.title,
    required this.hint,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
  });

  final String title;
  final String hint;
  final List<CatalogItem> items;
  final Set<int> selectedIds;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toTitleCase(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 3),
        Text(hint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 9),
        if (items.isEmpty)
          const Text('No published options are available yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items.map((item) {
                  return FilterChip(
                    label: Text(item.name),
                    selected: selectedIds.contains(item.id),
                    onSelected: (selected) {
                      selected
                          ? selectedIds.add(item.id)
                          : selectedIds.remove(item.id);
                      onChanged();
                    },
                  );
                }).toList(),
          ),
      ],
    );
  }
}


class _SearchableDestinationField extends StatefulWidget {
  const _SearchableDestinationField({
    required this.items,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<CatalogItem> items;
  final Set<int> selectedIds;
  final VoidCallback onChanged;

  @override
  State<_SearchableDestinationField> createState() =>
      _SearchableDestinationFieldState();
}

class _SearchableDestinationFieldState
    extends State<_SearchableDestinationField> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<CatalogItem> get _selected {
    return widget.items
        .where((item) => widget.selectedIds.contains(item.id))
        .toList();
  }

  List<CatalogItem> get _matches {
    final query = _query.trim().toLowerCase();
    if (query.length < 2) return const <CatalogItem>[];

    return widget.items
        .where((item) => !widget.selectedIds.contains(item.id))
        .where((item) {
          final searchable = [
            item.name,
            item.location ?? '',
            item.country ?? '',
          ].join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .take(8)
        .toList();
  }

  void _select(CatalogItem item) {
    widget.selectedIds.add(item.id);
    _search.clear();
    setState(() => _query = '');
    widget.onChanged();
    _focus.requestFocus();
  }

  void _remove(int id) {
    widget.selectedIds.remove(id);
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = _matches;
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safari Destinations',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Type at least 2 letters to find a destination. You can select several destinations.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),

        if (selected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected.map((item) {
              final country = item.country?.trim() ?? '';
              return InputChip(
                label: Text(
                  country.isEmpty ? item.name : '${item.name} • $country',
                ),
                onDeleted: () => _remove(item.id),
                deleteIcon: const Icon(Icons.close_rounded, size: 17),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        TextField(
          controller: _search,
          focusNode: _focus,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Search destination, e.g. Bwi or Serengeti',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),

        if (_query.trim().length == 1) ...[
          const SizedBox(height: 8),
          Text(
            'Type one more letter to search.',
            style: theme.textTheme.bodySmall,
          ),
        ],

        if (_query.trim().length >= 2) ...[
          const SizedBox(height: 8),
          if (matches.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('No matching destinations found.'),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 310),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 5),
                itemCount: matches.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final item = matches[index];
                  final country = item.country?.trim() ?? '';
                  final location = item.location?.trim() ?? '';

                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF165B5D).withOpacity(.09),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF165B5D),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        if (location.isNotEmpty) location,
                        if (country.isNotEmpty) country,
                      ].join(' • '),
                    ),
                    trailing: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFFF46627),
                    ),
                    onTap: () => _select(item),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _CountriesCoveredSummary extends StatelessWidget {
  const _CountriesCoveredSummary({
    required this.destinations,
    required this.selectedIds,
  });

  final List<CatalogItem> destinations;
  final Set<int> selectedIds;

  @override
  Widget build(BuildContext context) {
    final countries = destinations
        .where((item) => selectedIds.contains(item.id))
        .map((item) => item.country?.trim() ?? '')
        .where((country) => country.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (countries.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = countries.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF165B5D).withOpacity(.07),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFF165B5D).withOpacity(.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COUNTRIES COVERED',
            style: TextStyle(
              color: Color(0xFF165B5D),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: countries.map((country) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  country,
                  style: const TextStyle(
                    color: Color(0xFF165B5D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 9),
          Text(
            count == 1
                ? 'Single-country safari'
                : '$count-country safari',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(.62),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


class _TourMoodSelectionField extends StatelessWidget {
  const _TourMoodSelectionField({
    required this.moods,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<SafariMood> moods;
  final Set<int> selectedIds;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safari Moods',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Choose how travellers should discover this tour.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 9),
        if (moods.isEmpty)
          const Text('No published Safari Moods are available yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                moods.map((mood) {
                  final selected = selectedIds.contains(mood.id);
                  return FilterChip(
                    selected: selected,
                    showCheckmark: true,
                    avatar: Icon(mood.icon, size: 18),
                    label: Text(mood.title),
                    selectedColor: mood.primaryColor.withOpacity(.18),
                    side: BorderSide(
                      color:
                          selected
                              ? mood.primaryColor
                              : theme.colorScheme.outlineVariant,
                    ),
                    onSelected: (value) {
                      value
                          ? selectedIds.add(mood.id)
                          : selectedIds.remove(mood.id);
                      onChanged();
                    },
                  );
                }).toList(),
          ),
      ],
    );
  }
}

class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.localPath,
    required this.existingUrl,
    required this.label,
    required this.onTap,
  });

  final String? localPath;
  final String existingUrl;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 185,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child:
            localPath != null
                ? Image.file(File(localPath!), fit: BoxFit.cover)
                : existingUrl.isNotEmpty
                ? Image.network(existingUrl, fit: BoxFit.cover)
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, size: 42),
                    const SizedBox(height: 8),
                    Text(label),
                  ],
                ),
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: height,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Center(child: Icon(Icons.image_outlined, size: 44)),
      );
    }
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => Container(
            height: height,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, size: 44),
            ),
          ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
      itemBuilder:
          (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.active,
    this.activeLabel = 'Published',
    this.inactiveLabel = 'Hidden',
  });

  final bool active;
  final String activeLabel;
  final String inactiveLabel;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16845B) : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        active ? activeLabel : inactiveLabel,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GuidePublishingStatusCard extends StatelessWidget {
  const _GuidePublishingStatusCard({required this.publishing});

  final TourPublishingContext publishing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final icon =
        publishing.hasPrivateAffiliation
            ? Icons.lock_outline_rounded
            : publishing.hasPublicAffiliation
            ? Icons.hub_outlined
            : Icons.explore_rounded;

    final label =
        publishing.hasPrivateAffiliation
            ? 'PRIVATE WORK MODE'
            : publishing.hasPublicAffiliation
            ? 'AFFILIATED + INDEPENDENT'
            : 'INDEPENDENT GUIDE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.primary.withOpacity(.16)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(.045),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  publishing.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  publishing.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(.64),
                    height: 1.45,
                  ),
                ),
                if (publishing.hasPrivateAffiliation) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Your private operator relationship is not attached to these guide-led tours.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
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
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 34),
          const SizedBox(height: 12),
          Text(
            title.toTitleCase(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 6),
          Text(description),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      child: Column(
        children: [
          Icon(icon, size: 58, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 14),
          Text(
            title.toTitleCase(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

String? _positiveNumber(String? value) {
  final number = double.tryParse(value ?? '');
  return number == null || number <= 0 ? 'Enter a valid price.' : null;
}

String _money(String currency, double value) {
  final amount = _editablePrice(value);
  final parts = amount.split('.');
  final formatted = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$currency $formatted${parts.length == 2 ? '.${parts[1]}' : ''}';
}

String _editablePrice(double value) =>
    value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
