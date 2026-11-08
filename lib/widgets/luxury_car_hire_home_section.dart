import 'package:flutter/material.dart';

import '../models/operator_management.dart';
import '../pages/car_hire_page.dart';
import '../services/operator_offerings_service.dart';

/// Shared luxury car-hire discovery on all three user homepages.
class LuxuryCarHireHomeSection extends StatefulWidget {
  const LuxuryCarHireHomeSection({super.key});

  @override
  State<LuxuryCarHireHomeSection> createState() => _LuxuryCarHireHomeSectionState();
}

class _LuxuryCarHireHomeSectionState extends State<LuxuryCarHireHomeSection> {
  static const Color ink = Color(0xFF173C3D);
  late Future<CarHireVehiclePage> _vehicles;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _vehicles = OperatorOfferingsService.instance.fetchVehicles(perPage: 8);
  }

  void _browse([CarHireVehicle? vehicle]) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CarHirePage(
        initialVehicleId: vehicle?.id,
        vehicles: vehicle == null ? const <CarHireVehicle>[] : [vehicle],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .60);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TRAVEL IN COMFORT', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 7),
          Text('Safari Car Hire', style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800, letterSpacing: -.6)),
          const SizedBox(height: 5),
          Text('Find the right vehicle for every journey.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ])),
        TextButton(onPressed: _browse, child: const Text('View all')),
      ]),
      const SizedBox(height: 17),
      FutureBuilder<CarHireVehiclePage>(future: _vehicles, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(height: 292, child: ListView.separated(
            scrollDirection: Axis.horizontal, itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Container(width: 260, decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(22))),
          ));
        }
        if (snapshot.hasError) {
          return _NoticeCard(
            title: 'Explore safari vehicles',
            subtitle: 'Vehicles could not be loaded right now.',
            buttonLabel: 'Try again',
            onPressed: () => setState(_reload),
          );
        }
        final vehicles = snapshot.data?.vehicles.where((v) => v.isAvailable).toList()
            ?? <CarHireVehicle>[];
        if (vehicles.isEmpty) {
          return _NoticeCard(
            title: 'Find your safari vehicle',
            subtitle: 'Browse available vehicles and hire options.',
            buttonLabel: 'Explore Car Hire', onPressed: _browse,
          );
        }
        return SizedBox(height: 324, child: ListView.separated(
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          itemCount: vehicles.length,
          separatorBuilder: (_, __) => const SizedBox(width: 15),
          itemBuilder: (context, index) => _VehicleCard(
            vehicle: vehicles[index], onTap: () => _browse(vehicles[index])),
        ));
      }),
    ]);
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onTap});
  final CarHireVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final muted = theme.colorScheme.onSurface.withValues(alpha: .62);
    final image = vehicle.imageUrl.trim();
    return SizedBox(width: 274, child: Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(23),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(23),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: .14))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 192, width: double.infinity, child: Stack(fit: StackFit.expand, children: [
            Container(color: dark ? const Color(0xFF293837) : const Color(0xFFECEBE6),
              child: image.isEmpty ? const Icon(Icons.directions_car_filled_outlined,
                  color: Color(0xFF8C9892), size: 54) :
                Image.network(image, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_car_filled_outlined, color: Color(0xFF8C9892), size: 54))),
            Positioned(top: 12, left: 12, child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(30)),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: const Text('CAR HIRE', style: TextStyle(color: Colors.white,
                  fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w700))))),
          ])),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vehicle.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text([
                if (vehicle.seats != null && vehicle.seats! > 0) '${vehicle.seats} seats',
                if ((vehicle.transmission ?? '').trim().isNotEmpty) vehicle.transmission!.trim(),
                if ((vehicle.fuelType ?? '').trim().isNotEmpty) vehicle.fuelType!.trim(),
              ].join('  ·  '), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              const Spacer(),
              Row(children: [
                Expanded(child: Text(vehicle.pricePerDay > 0
                  ? '${vehicle.currency} ${vehicle.pricePerDay.toStringAsFixed(vehicle.pricePerDay % 1 == 0 ? 0 : 2)} / day'
                  : 'View rental details', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary))),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_outward_rounded, size: 19),
              ]),
            ]))),
        ]),
      )),
    ));
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.title, required this.subtitle,
    required this.buttonLabel, required this.onPressed});
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .16))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 5), Text(subtitle), const SizedBox(height: 10),
      TextButton(onPressed: onPressed, child: Text(buttonLabel)),
    ]),
  );
}
