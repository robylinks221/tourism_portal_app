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
  const OperatorManagePage({super.key, this.guideMode = false});

  final bool guideMode;

  @override
  State<OperatorManagePage> createState() => _OperatorManagePageState();
}

class _OperatorManagePageState extends State<OperatorManagePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  OperatorManagementData? _management;
  TourismCatalog? _catalog;
  String? _error;
  bool _loading = true;
  bool _changingCarHire = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.guideMode ? 1 : 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
      builder: (_) => _TourEditor(
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
          builder: (context) => AlertDialog(
            title: Text('Delete $name?'),
            content: const Text('This action permanently removes this item.'),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final toursSection = _ToursSection(
      tours: _management?.tours ?? const [],
      guideMode: widget.guideMode,
      onAdd: () => _editTour(),
      onEdit: _editTour,
      onDelete: _deleteTour,
      onRefresh: _load,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (widget.guideMode ? 'Manage guide tours' : 'Manage').toTitleCase(),
        ),
        bottom: widget.guideMode
            ? null
            : TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(icon: Icon(Icons.map_outlined), text: 'Tours'),
                  Tab(
                    icon: Icon(Icons.directions_car_outlined),
                    text: 'Car Hire',
                  ),
                ],
              ),
      ),
      floatingActionButton: widget.guideMode && !_loading && _error == null
          ? FloatingActionButton.extended(
              onPressed: () => _editTour(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add guide tour'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : widget.guideMode
          ? toursSection
          : TabBarView(
              controller: _tabs,
              children: [
                toursSection,
                _CarHireSection(
                  enabled: _management!.carHireEnabled,
                  changing: _changingCarHire,
                  vehicles: _management!.vehicles,
                  onToggle: _toggleCarHire,
                  onAdd: () => _editVehicle(),
                  onEdit: _editVehicle,
                  onDelete: _deleteVehicle,
                  onRefresh: _load,
                ),
              ],
            ),
    );
  }
}

class _ToursSection extends StatelessWidget {
  const _ToursSection({
    required this.tours,
    required this.guideMode,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<OperatorTour> tours;
  final bool guideMode;
  final VoidCallback onAdd;
  final ValueChanged<OperatorTour> onEdit;
  final ValueChanged<OperatorTour> onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
        children: [
          _IntroCard(
            icon: Icons.luggage_rounded,
            title: guideMode ? 'Your guide-led tours' : 'Your safari tours',
            description: guideMode
                ? 'Publish experiences using activities and destinations approved by the admin.'
                : 'Build tours using only activities and destinations published by the admin.',
            actionLabel: guideMode ? 'Add guide tour' : 'Add tour',
            onAction: onAdd,
          ),
          const SizedBox(height: 20),
          if (tours.isEmpty)
            _EmptyState(
              icon: Icons.map_outlined,
              title: guideMode ? 'No guide tours yet' : 'No tours yet',
              message: guideMode
                  ? 'Tap Add guide tour to publish your first guide-led experience.'
                  : 'Tap Add tour to publish your first safari package.',
            )
          else
            ...tours.map(
              (tour) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
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
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.outline.withOpacity(.5)),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: changing ? null : onToggle,
              secondary: CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Icon(Icons.car_rental_rounded, color: colors.primary),
              ),
              title: const Text(
                'Car hire services',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                enabled
                    ? 'Active — travellers can see your available vehicles.'
                    : 'Turn this on only when your company offers vehicle hire.',
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (!enabled)
            const _EmptyState(
              icon: Icons.no_transfer_rounded,
              title: 'Car hire is off',
              message:
                  'Your saved vehicles stay private until you activate this service.',
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add vehicle'),
              ),
            ),
            const SizedBox(height: 18),
            if (vehicles.isEmpty)
              const _EmptyState(
                icon: Icons.directions_car_outlined,
                title: 'No vehicles yet',
                message: 'Add the first vehicle available for daily hire.',
              )
            else
              ...vehicles.map(
                (vehicle) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _VehicleCard(
                    vehicle: vehicle,
                    onEdit: () => onEdit(vehicle),
                    onDelete: () => onDelete(vehicle),
                  ),
                ),
              ),
          ],
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
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NetworkImage(url: tour.imageUrl, height: 170),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        tour.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    _ItemMenu(onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${tour.days} ${tour.days == 1 ? 'day' : 'days'} • ${_money(tour.currency, tour.price)}',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tour.destinationNames.join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _StatusBadge(active: tour.isActive),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NetworkImage(url: vehicle.imageUrl, height: 165),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vehicle.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    _ItemMenu(onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
                Text(
                  '${_money(vehicle.currency, vehicle.pricePerDay)} / day',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (vehicle.seats != null) '${vehicle.seats} seats',
                    if (vehicle.transmission?.isNotEmpty == true)
                      vehicle.transmission!,
                    if (vehicle.fuelType?.isNotEmpty == true) vehicle.fuelType!,
                  ].join(' • '),
                ),
                if (vehicle.amenities.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: vehicle.amenities
                        .map((amenity) => Chip(label: Text(amenity)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 8),
                _StatusBadge(
                  active: vehicle.isAvailable,
                  activeLabel: 'Available',
                  inactiveLabel: 'Unavailable',
                ),
              ],
            ),
          ),
        ],
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
    _activityIds = {...?tour?.activityIds};
    _destinationIds = {...?tour?.destinationIds};
    _moodIds = {...?tour?.moodIds};
    _itinerary = (tour?.itinerary ?? const <TourItineraryStop>[])
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
      };
      for (var index = 0; index < _itinerary.length; index++) {
        final stop = _itinerary[index];
        fields['itinerary[$index][day]'] = '${index + 1}';
        fields['itinerary[$index][title]'] = stop.title.text.trim();
        fields['itinerary[$index][description]'] = stop.description.text
            .trim();
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
      title: widget.tour == null
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
            return days == null || days < 1 ? 'Enter the number of days.' : null;
          },
          decoration: const InputDecoration(labelText: 'Number of days'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _overview,
          minLines: 5,
          maxLines: 9,
          validator: (value) => (value?.trim().length ?? 0) < 30
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
        const SizedBox(height: 18),
        _SelectionField(
          title: 'Tour activities',
          hint: 'Select from admin activities',
          items: widget.catalog.activities,
          selectedIds: _activityIds,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 18),
        _SelectionField(
          title: 'Safari destinations',
          hint: 'Select where this tour goes',
          items: widget.catalog.destinations,
          selectedIds: _destinationIds,
          onChanged: () => setState(() {}),
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
          icon: _saving
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
            return seats == null || seats < 1 ? 'Enter a valid seat count.' : null;
          },
          decoration: const InputDecoration(labelText: 'Number of seats'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _transmission,
          decoration: const InputDecoration(labelText: 'Transmission'),
          items: const ['Automatic', 'Manual']
              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: (value) => setState(() => _transmission = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _fuelType,
          decoration: const InputDecoration(labelText: 'Fuel type'),
          items: const ['Petrol', 'Diesel', 'Electric', 'Hybrid']
              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: (value) => setState(() => _fuelType = value),
        ),
        const SizedBox(height: 18),
        Text(
          'Amenities',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _amenityOptions.map((amenity) {
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
          icon: _saving
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
        builder: (context, controller) => Form(
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w300,
          ),
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
            children: items.map((item) {
              return FilterChip(
                label: Text(item.name),
                selected: selectedIds.contains(item.id),
                onSelected: (selected) {
                  selected ? selectedIds.add(item.id) : selectedIds.remove(item.id);
                  onChanged();
                },
              );
            }).toList(),
          ),
      ],
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
            children: moods.map((mood) {
              final selected = selectedIds.contains(mood.id);
              return FilterChip(
                selected: selected,
                showCheckmark: true,
                avatar: Icon(mood.icon, size: 18),
                label: Text(mood.title),
                selectedColor: mood.primaryColor.withOpacity(.18),
                side: BorderSide(
                  color: selected
                      ? mood.primaryColor
                      : theme.colorScheme.outlineVariant,
                ),
                onSelected: (value) {
                  value ? selectedIds.add(mood.id) : selectedIds.remove(mood.id);
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
        child: localPath != null
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
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 44)),
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
      itemBuilder: (_) => const [
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
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w300,
            ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w300,
            ),
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

String _editablePrice(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
