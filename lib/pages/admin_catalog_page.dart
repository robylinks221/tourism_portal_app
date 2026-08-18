import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/supported_countries.dart';
import '../models/catalog_item.dart';
import '../models/operator_management.dart';
import '../models/safari_mood.dart';
import '../services/api_exception.dart';
import '../services/catalog_service.dart';
import '../services/operator_offerings_service.dart';
import '../utils/text_case.dart';
import 'admin_accommodations_page.dart';

class AdminCatalogPage extends StatefulWidget {
  const AdminCatalogPage({super.key});

  @override
  State<AdminCatalogPage> createState() => _AdminCatalogPageState();
}

class _AdminCatalogPageState extends State<AdminCatalogPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _activeTab = 0;
  TourismCatalog? _catalog;
  List<OperatorTour> _tours = const [];
  String? _error;
  String? _tourError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(_handleTabChange);
    _load();
  }

  void _handleTabChange() {
    if (_activeTab == _tabs.index || !mounted) return;
    setState(() => _activeTab = _tabs.index);
  }

  @override
  void dispose() {
    _tabs.removeListener(_handleTabChange);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _tourError = null;
    });

    try {
      final catalog = await CatalogService.instance.fetchCatalog(admin: true);
      var tours = <OperatorTour>[];
      String? tourError;

      try {
        final offerings = await OperatorOfferingsService.instance.fetch();
        tours = offerings.tours;
      } on ApiException catch (error) {
        tourError = error.message;
      }

      if (mounted) {
        setState(() {
          _catalog = catalog;
          _tours = tours;
          _tourError = tourError;
          _loading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _edit({CatalogItem? item}) async {
    final type = item?.type ?? (_activeTab == 0 ? 'activity' : 'destination');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _CatalogEditor(
            type: type,
            item: item,
            destinations: _catalog?.destinations ?? const [],
            activities: _catalog?.activities ?? const [],
            moods: _catalog?.moods ?? const [],
          ),
    );
    if (saved == true) await _load();
  }

  Future<void> _editMood({SafariMood? mood}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _MoodEditor(
            mood: mood,
            activities: _catalog?.activities ?? const [],
            destinations: _catalog?.destinations ?? const [],
            tours: _tours,
            tourError: _tourError,
            onEditCatalogItem: (item) => _edit(item: item),
          ),
    );
    if (saved == true) await _load();
  }

  Future<void> _toggleMood(SafariMood mood) async {
    try {
      await CatalogService.instance.saveMood(
        mood: mood,
        fields: {
          'name': mood.title,
          'subtitle': mood.subtitle,
          'icon_key': mood.iconKey,
          'primary_color': mood.primaryColorHex,
          'secondary_color': mood.secondaryColorHex,
          'is_active': mood.isActive ? '0' : '1',
        },
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _moveMood(SafariMood mood, int direction) async {
    final moods = [...?_catalog?.moods];
    final index = moods.indexWhere((item) => item.id == mood.id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= moods.length) return;
    final moved = moods.removeAt(index);
    moods.insert(target, moved);
    try {
      await CatalogService.instance.reorderMoods(
        moods.map((item) => item.id).toList(),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _deleteMood(SafariMood mood) async {
    if (mood.assignmentCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Remove ${mood.title} from its activities, destinations, and tours before deleting it.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete ${mood.title}?'),
            content: const Text(
              'This permanently removes the safari mood. This action cannot be undone.',
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
    );
    if (confirmed != true) return;
    try {
      await CatalogService.instance.deleteMood(mood);
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _delete(CatalogItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete ${item.name}?'),
            content: Text(
              item.isActivity
                  ? 'This removes the page and removes it from guide and operator profiles.'
                  : 'This removes the destination page, its accommodations, and its profile links.',
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
    );
    if (confirmed != true) return;
    try {
      await CatalogService.instance.delete(item);
      await _load();
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourism Catalog'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.local_activity_outlined), text: 'Activities'),
            Tab(icon: Icon(Icons.landscape_outlined), text: 'Destinations'),
            Tab(icon: Icon(Icons.auto_awesome_outlined), text: 'Safari Moods'),
            Tab(icon: Icon(Icons.hotel_outlined), text: 'Accommodations'),
          ],
        ),
      ),
      floatingActionButton:
          _activeTab == 3
              ? null
              : FloatingActionButton.extended(
                onPressed: _activeTab == 2 ? () => _editMood() : () => _edit(),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  _activeTab == 0
                      ? 'Add activity'
                      : _activeTab == 1
                      ? 'Add destination'
                      : 'Add safari mood',
                ),
              ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabs,
                children: [
                  _CatalogList(
                    items: _catalog!.activities,
                    onEdit: (item) => _edit(item: item),
                    onDelete: _delete,
                  ),
                  _CatalogList(
                    items: _catalog!.destinations,
                    onEdit: (item) => _edit(item: item),
                    onDelete: _delete,
                    onManageAccommodations:
                        (destination) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AdminAccommodationsPage(
                                  destination: destination,
                                ),
                          ),
                        ),
                  ),
                  _MoodList(
                    moods: _catalog!.moods,
                    onEdit: (mood) => _editMood(mood: mood),
                    onToggle: _toggleMood,
                    onDelete: _deleteMood,
                    onMoveUp: (mood) => _moveMood(mood, -1),
                    onMoveDown: (mood) => _moveMood(mood, 1),
                  ),
                  _AccommodationDestinations(
                    destinations: _catalog!.destinations,
                    onManage:
                        (destination) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AdminAccommodationsPage(
                                  destination: destination,
                                ),
                          ),
                        ),
                  ),
                ],
              ),
    );
  }
}

class _AccommodationDestinations extends StatelessWidget {
  const _AccommodationDestinations({
    required this.destinations,
    required this.onManage,
  });

  final List<CatalogItem> destinations;
  final ValueChanged<CatalogItem> onManage;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Add a destination first, then you can add its accommodation here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      itemCount: destinations.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.hotel_class_outlined,
                  color: colors.onPrimaryContainer,
                  size: 30,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accommodation by Destination',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Choose a destination to add, edit, publish, hide, or delete its places to stay.',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final destination = destinations[index - 1];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onManage(destination),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child:
                        destination.imageUrl.isEmpty
                            ? Container(
                              width: 76,
                              height: 76,
                              color: colors.secondaryContainer,
                              child: const Icon(
                                Icons.landscape_outlined,
                                size: 34,
                              ),
                            )
                            : Image.network(
                              destination.imageUrl,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 76,
                                    height: 76,
                                    color: colors.secondaryContainer,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                    ),
                                  ),
                            ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [destination.location, destination.country]
                              .where(
                                (value) => value?.trim().isNotEmpty == true,
                              )
                              .join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Manage accommodation',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    this.onManageAccommodations,
  });
  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onEdit;
  final ValueChanged<CatalogItem> onDelete;
  final ValueChanged<CatalogItem>? onManageAccommodations;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty)
      return const Center(child: Text('No items yet. Tap Add to create one.'));
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    item.imageUrl.isEmpty
                        ? Container(
                          width: 68,
                          height: 68,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.image_outlined),
                        )
                        : Image.network(
                          item.imageUrl,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                        ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                item.isActivity
                    ? '${item.isActive ? 'Published' : 'Hidden'} · ${item.destinations.isEmpty ? 'No destinations assigned' : item.destinations.map((destination) => destination.name).join(', ')}'
                    : '${item.isActive ? 'Published' : 'Hidden'} · ${item.activities.isEmpty ? 'No activities assigned' : item.activities.map((activity) => activity.name).join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'accommodation') {
                    onManageAccommodations?.call(item);
                  } else if (value == 'edit') {
                    onEdit(item);
                  } else {
                    onDelete(item);
                  }
                },
                itemBuilder:
                    (_) => [
                      if (onManageAccommodations != null)
                        const PopupMenuItem(
                          value: 'accommodation',
                          child: Text('Manage accommodation'),
                        ),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoodList extends StatelessWidget {
  const _MoodList({
    required this.moods,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final List<SafariMood> moods;
  final ValueChanged<SafariMood> onEdit;
  final ValueChanged<SafariMood> onToggle;
  final ValueChanged<SafariMood> onDelete;
  final ValueChanged<SafariMood> onMoveUp;
  final ValueChanged<SafariMood> onMoveDown;

  @override
  Widget build(BuildContext context) {
    if (moods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'No safari moods yet. Tap Add safari mood to create the first one.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
      itemCount: moods.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF123F38), Color(0xFF1F6B5C)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mood-Led Discovery',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create and order the choices travellers see on every discovery dashboard.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(.76),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final moodIndex = index - 1;
        final mood = moods[moodIndex];
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onEdit(mood),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MoodArtwork(mood: mood),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mood.title.toTitleCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mood.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _MoodStatusChip(
                                label: mood.isActive ? 'Published' : 'Hidden',
                                color:
                                    mood.isActive
                                        ? const Color(0xFF1F6B5C)
                                        : theme.colorScheme.outline,
                              ),
                              _MoodStatusChip(
                                label:
                                    '${mood.activityCount} activities · ${mood.destinationCount} destinations · ${mood.tourCount} tours',
                                color: mood.primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Move up',
                        onPressed: moodIndex == 0 ? null : () => onMoveUp(mood),
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                      IconButton(
                        tooltip: 'Move down',
                        onPressed:
                            moodIndex == moods.length - 1
                                ? null
                                : () => onMoveDown(mood),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Mood actions',
                        onSelected: (value) {
                          if (value == 'edit') onEdit(mood);
                          if (value == 'toggle') onToggle(mood);
                          if (value == 'delete') onDelete(mood);
                        },
                        itemBuilder:
                            (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit mood'),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  mood.isActive ? 'Hide mood' : 'Publish mood',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                enabled: mood.assignmentCount == 0,
                                child: Text(
                                  mood.assignmentCount == 0
                                      ? 'Delete mood'
                                      : 'Remove assignments before deleting',
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MoodArtwork extends StatelessWidget {
  const _MoodArtwork({required this.mood});

  final SafariMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 112,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mood.primaryColor, mood.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mood.imageUrl.isNotEmpty)
            Image.network(
              mood.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  mood.primaryColor.withOpacity(.08),
                  mood.secondaryColor.withOpacity(.86),
                ],
              ),
            ),
          ),
          Center(child: Icon(mood.icon, color: Colors.white, size: 31)),
        ],
      ),
    );
  }
}

class _MoodStatusChip extends StatelessWidget {
  const _MoodStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MoodEditor extends StatefulWidget {
  const _MoodEditor({
    this.mood,
    required this.activities,
    required this.destinations,
    required this.tours,
    required this.onEditCatalogItem,
    this.tourError,
  });

  final SafariMood? mood;
  final List<CatalogItem> activities;
  final List<CatalogItem> destinations;
  final List<OperatorTour> tours;
  final Future<void> Function(CatalogItem item) onEditCatalogItem;
  final String? tourError;

  @override
  State<_MoodEditor> createState() => _MoodEditorState();
}

class _MoodEditorState extends State<_MoodEditor> {
  static const _icons = <String, String>{
    'forest': 'Forest',
    'wildlife': 'Wildlife',
    'bird': 'Birding',
    'culture': 'Culture',
    'route': 'Route',
    'luxury': 'Luxury',
    'water': 'Water',
    'mountain': 'Mountain',
    'camera': 'Photography',
    'compass': 'Compass',
  };

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _subtitle;
  late final TextEditingController _primaryColor;
  late final TextEditingController _secondaryColor;
  late String _iconKey;
  late bool _active;
  String? _imagePath;
  bool _saving = false;
  int _selectedSection = 0;

  late Set<int> _activityAssignmentIds;
  late Set<int> _destinationAssignmentIds;

  bool _savingActivityAssignments = false;
  bool _savingDestinationAssignments = false;

  @override
  void initState() {
    super.initState();
    final mood = widget.mood;
    _name = TextEditingController(text: mood?.title);
    _subtitle = TextEditingController(text: mood?.subtitle);
    _primaryColor = TextEditingController(
      text: mood?.primaryColorHex ?? '#1F6B5C',
    );
    _secondaryColor = TextEditingController(
      text: mood?.secondaryColorHex ?? '#123F38',
    );
    _iconKey = _icons.containsKey(mood?.iconKey) ? mood!.iconKey : 'compass';
    _active = mood?.isActive ?? true;

    final moodId = mood?.id;
    _activityAssignmentIds =
        moodId == null
            ? <int>{}
            : widget.activities
                .where((item) => item.moodIds.contains(moodId))
                .map((item) => item.id)
                .toSet();

    _destinationAssignmentIds =
        moodId == null
            ? <int>{}
            : widget.destinations
                .where((item) => item.moodIds.contains(moodId))
                .map((item) => item.id)
                .toSet();
  }

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    _primaryColor.dispose();
    _secondaryColor.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 2200,
    );
    if (image != null && mounted) {
      setState(() => _imagePath = image.path);
    }
  }

  void _setColors(String primary, String secondary) {
    setState(() {
      _primaryColor.text = primary;
      _secondaryColor.text = secondary;
    });
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _hexColor(String? value) {
    final missing = _required(value);
    if (missing != null) return missing;
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value!.trim())
        ? null
        : 'Use a colour such as #1F6B5C.';
  }

  SafariMood get _previewMood => SafariMood(
    id: widget.mood?.id ?? 0,
    key: widget.mood?.key ?? 'preview',
    title: _name.text.trim().isEmpty ? 'Your safari mood' : _name.text.trim(),
    subtitle:
        _subtitle.text.trim().isEmpty
            ? 'Add a short, inspiring description.'
            : _subtitle.text.trim(),
    image: widget.mood?.image,
    iconKey: _iconKey,
    primaryColorHex: _primaryColor.text.trim(),
    secondaryColorHex: _secondaryColor.text.trim(),
    isActive: _active,
    sortOrder: widget.mood?.sortOrder ?? 0,
  );

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await CatalogService.instance.saveMood(
        mood: widget.mood,
        imagePath: _imagePath,
        fields: {
          'name': _name.text.trim(),
          'subtitle': _subtitle.text.trim(),
          'icon_key': _iconKey,
          'primary_color': _primaryColor.text.trim().toUpperCase(),
          'secondary_color': _secondaryColor.text.trim().toUpperCase(),
          'is_active': _active ? '1' : '0',
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveActivityAssignments() async {
    final mood = widget.mood;

    if (mood == null || _savingActivityAssignments) {
      return;
    }

    setState(() {
      _savingActivityAssignments = true;
    });

    try {
      final ids = _activityAssignmentIds.toList()..sort();

      await CatalogService.instance.syncMoodActivities(
        mood: mood,
        activityIds: ids,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safari Mood activities updated successfully.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _savingActivityAssignments = false;
        });
      }
    }
  }

  Future<void> _saveDestinationAssignments() async {
    final mood = widget.mood;

    if (mood == null || _savingDestinationAssignments) {
      return;
    }

    setState(() {
      _savingDestinationAssignments = true;
    });

    try {
      final ids = _destinationAssignmentIds.toList()..sort();

      await CatalogService.instance.syncMoodDestinations(
        mood: mood,
        destinationIds: ids,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safari Mood destinations updated successfully.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _savingDestinationAssignments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = widget.mood;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .94,
        minChildSize: .68,
        maxChildSize: .98,
        builder:
            (context, controller) => Form(
              key: _formKey,
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    mood == null
                        ? 'Create safari mood'
                        : mood.title.toTitleCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    mood == null
                        ? 'Create the mood first. You can then manage its activities, destinations and tours.'
                        : 'Manage the discovery card and review everything assigned to this Safari Mood.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.64),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MoodEditorTabBar(
                    selectedIndex: _selectedSection,
                    enabled: mood != null,
                    onChanged:
                        (index) => setState(() => _selectedSection = index),
                  ),
                  const SizedBox(height: 22),
                  if (_selectedSection == 0) ...[
                    _MoodEditorPreview(
                      mood: _previewMood,
                      imagePath: _imagePath,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _name,
                      validator: _required,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Mood name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subtitle,
                      validator: (value) {
                        final missing = _required(value);
                        if (missing != null) return missing;
                        return value!.trim().length < 5
                            ? 'Write at least 5 characters.'
                            : null;
                      },
                      onChanged: (_) => setState(() {}),
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Short discovery message',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _iconKey,
                      items:
                          _icons.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => _iconKey = value!),
                      decoration: const InputDecoration(labelText: 'Mood icon'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Quick Colour Palettes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PaletteChip(
                          label: 'Forest',
                          colors: const ['#2A6A4F', '#123B32'],
                          onTap: _setColors,
                        ),
                        _PaletteChip(
                          label: 'Savannah',
                          colors: const ['#B56B36', '#5E351F'],
                          onTap: _setColors,
                        ),
                        _PaletteChip(
                          label: 'Lake',
                          colors: const ['#3C8F9B', '#174854'],
                          onTap: _setColors,
                        ),
                        _PaletteChip(
                          label: 'Clay',
                          colors: const ['#B8573C', '#6B2F2B'],
                          onTap: _setColors,
                        ),
                        _PaletteChip(
                          label: 'Gold',
                          colors: const ['#9A7652', '#4E3827'],
                          onTap: _setColors,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _primaryColor,
                            validator: _hexColor,
                            onChanged: (_) => setState(() {}),
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Primary colour',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _secondaryColor,
                            validator: _hexColor,
                            onChanged: (_) => setState(() {}),
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Secondary colour',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _active,
                      onChanged: (value) => setState(() => _active = value),
                      title: const Text('Published'),
                      subtitle: const Text(
                        'Visible to travellers on discovery pages',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon:
                          _saving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save safari mood'),
                    ),
                  ] else if (mood == null) ...[
                    const _MoodNeedsSave(),
                  ] else if (_selectedSection == 1) ...[
                    _MoodCatalogManagementTab(
                      title: 'Activities',
                      helperText:
                          'Select the safari activities that belong to this mood, then save the assignments.',
                      items: widget.activities,
                      selectedIds: _activityAssignmentIds,
                      saving: _savingActivityAssignments,
                      saveLabel: 'Save Activity Assignments',
                      onChanged: (item, selected) {
                        setState(() {
                          if (selected) {
                            _activityAssignmentIds.add(item.id);
                          } else {
                            _activityAssignmentIds.remove(item.id);
                          }
                        });
                      },
                      onSave: _saveActivityAssignments,
                    ),
                  ] else if (_selectedSection == 2) ...[
                    _MoodCatalogManagementTab(
                      title: 'Destinations',
                      helperText:
                          'Select the safari destinations that belong to this mood, then save the assignments.',
                      items: widget.destinations,
                      selectedIds: _destinationAssignmentIds,
                      saving: _savingDestinationAssignments,
                      saveLabel: 'Save Destination Assignments',
                      onChanged: (item, selected) {
                        setState(() {
                          if (selected) {
                            _destinationAssignmentIds.add(item.id);
                          } else {
                            _destinationAssignmentIds.remove(item.id);
                          }
                        });
                      },
                      onSave: _saveDestinationAssignments,
                    ),
                  ] else ...[
                    _MoodTourManagementTab(
                      mood: mood,
                      tours: widget.tours,
                      error: widget.tourError,
                    ),
                  ],
                ],
              ),
            ),
      ),
    );
  }
}

class _MoodEditorTabBar extends StatelessWidget {
  const _MoodEditorTabBar({
    required this.selectedIndex,
    required this.enabled,
    required this.onChanged,
  });

  final int selectedIndex;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MoodEditorTabButton(
            label: 'Details',
            selected: selectedIndex == 0,
            enabled: true,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 8),
          _MoodEditorTabButton(
            label: 'Activities',
            selected: selectedIndex == 1,
            enabled: enabled,
            onTap: () => onChanged(1),
          ),
          const SizedBox(width: 8),
          _MoodEditorTabButton(
            label: 'Destinations',
            selected: selectedIndex == 2,
            enabled: enabled,
            onTap: () => onChanged(2),
          ),
          const SizedBox(width: 8),
          _MoodEditorTabButton(
            label: 'Tours',
            selected: selectedIndex == 3,
            enabled: enabled,
            onTap: () => onChanged(3),
          ),
        ],
      ),
    );
  }
}

class _MoodEditorTabButton extends StatelessWidget {
  const _MoodEditorTabButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  !enabled
                      ? colors.onSurface.withOpacity(.35)
                      : selected
                      ? colors.onPrimary
                      : colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodNeedsSave extends StatelessWidget {
  const _MoodNeedsSave();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withOpacity(.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Save this Safari Mood first. After it has been created, reopen it to manage Activities, Destinations and Tours.',
      ),
    );
  }
}

class _MoodCatalogManagementTab extends StatelessWidget {
  const _MoodCatalogManagementTab({
    required this.title,
    required this.helperText,
    required this.items,
    required this.selectedIds,
    required this.saving,
    required this.saveLabel,
    required this.onChanged,
    required this.onSave,
  });

  final String title;
  final String helperText;
  final List<CatalogItem> items;
  final Set<int> selectedIds;
  final bool saving;
  final String saveLabel;
  final void Function(CatalogItem item, bool selected) onChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final sortedItems = [...items]..sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );

    final selectedCount =
        sortedItems.where((item) => selectedIds.contains(item.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          helperText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withOpacity(.64),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        _MoodAssignmentSummary(
          assigned: selectedCount,
          total: sortedItems.length,
        ),
        const SizedBox(height: 16),

        if (sortedItems.isEmpty)
          _MoodAssignmentEmpty(
            message:
                'No ${title.toLowerCase()} are available yet. Create them in the Tourism Catalog first.',
          )
        else ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < sortedItems.length; index++) ...[
                  _MoodCatalogAssignmentCheckbox(
                    item: sortedItems[index],
                    selected: selectedIds.contains(sortedItems[index].id),
                    onChanged: (selected) {
                      onChanged(sortedItems[index], selected);
                    },
                  ),
                  if (index != sortedItems.length - 1)
                    Divider(
                      height: 1,
                      color: colors.outlineVariant.withOpacity(.72),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon:
                  saving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              label: Text(
                saving ? 'Saving Assignments...' : saveLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Only this Safari Mood relationship will be changed. The item name, image, description and other catalog information will remain untouched.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(.58),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _MoodAssignmentSummary extends StatelessWidget {
  const _MoodAssignmentSummary({required this.assigned, required this.total});

  final int assigned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(.14)),
      ),
      child: Text(
        '$assigned of $total assigned',
        style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MoodCatalogAssignmentCheckbox extends StatelessWidget {
  const _MoodCatalogAssignmentCheckbox({
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final CatalogItem item;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 10, 8, 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  item.imageUrl.isEmpty
                      ? Container(
                        width: 52,
                        height: 52,
                        color: colors.primaryContainer,
                        child: Icon(
                          item.isActivity
                              ? Icons.hiking_rounded
                              : Icons.landscape_outlined,
                          color: colors.onPrimaryContainer,
                        ),
                      )
                      : Image.network(
                        item.imageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: colors.primaryContainer,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                      ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.isActivity
                        ? item.name
                        : TourismCountries.destinationLabel(
                          destinationName: item.name,
                          countryName: item.country,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.isActivity
                        ? (item.isActive ? 'Published' : 'Hidden')
                        : [
                          if ((item.country ?? '').trim().isNotEmpty)
                            item.country!.trim(),
                          item.isActive ? 'Published' : 'Hidden',
                        ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(.60),
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (value) {
                onChanged(value ?? false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodAssignmentEmpty extends StatelessWidget {
  const _MoodAssignmentEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message),
    );
  }
}

class _MoodTourManagementTab extends StatelessWidget {
  const _MoodTourManagementTab({
    required this.mood,
    required this.tours,
    this.error,
  });

  final SafariMood mood;
  final List<OperatorTour> tours;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final assigned =
        tours.where((tour) => tour.moodIds.contains(mood.id)).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tours',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Tours are assigned to Safari Moods by their Tourist Guide or Tour Operator. Admin can review the assignments here without taking ownership of provider content.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withOpacity(.64),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        if (error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.errorContainer.withOpacity(.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(error!),
          )
        else if (assigned.isEmpty)
          const _MoodAssignmentEmpty(
            message:
                'No published guide or operator tours are assigned to this Safari Mood yet.',
          )
        else ...[
          _MoodAssignmentSummary(
            assigned: assigned.length,
            total: tours.length,
          ),
          const SizedBox(height: 14),
          ...assigned.map(
            (tour) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MoodTourAdminCard(tour: tour),
            ),
          ),
        ],
      ],
    );
  }
}

class _MoodTourAdminCard extends StatelessWidget {
  const _MoodTourAdminCard({required this.tour});

  final OperatorTour tour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final providerLabel = tour.isGuideLed ? 'Tourist Guide' : 'Tour Operator';
    final amount =
        tour.price == tour.price.roundToDouble()
            ? tour.price.toStringAsFixed(0)
            : tour.price.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child:
                tour.imageUrl.isEmpty
                    ? Container(
                      width: 68,
                      height: 68,
                      color: colors.primaryContainer,
                      child: const Icon(Icons.route_rounded),
                    )
                    : Image.network(
                      tour.imageUrl,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 68,
                            height: 68,
                            color: colors.primaryContainer,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tour.operatorName.isEmpty ? 'Safari provider' : tour.operatorName} · $providerLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    Text(
                      '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${tour.currency.isEmpty ? 'USD' : tour.currency} $amount',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

class _MoodEditorPreview extends StatelessWidget {
  const _MoodEditorPreview({
    required this.mood,
    required this.imagePath,
    required this.onTap,
  });

  final SafariMood mood;
  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mood.primaryColor, mood.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              if (imagePath != null)
                Image.file(File(imagePath!), fit: BoxFit.cover)
              else if (mood.imageUrl.isNotEmpty)
                Image.network(
                  mood.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      mood.primaryColor.withOpacity(.12),
                      mood.secondaryColor.withOpacity(.94),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(mood.icon, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.28),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Choose image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      mood.title.toTitleCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mood.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(.8),
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

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final List<String> colors;
  final void Function(String primary, String secondary) onTap;

  Color _color(String hex) => Color(
    0xFF000000 | (int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () => onTap(colors[0], colors[1]),
      avatar: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_color(colors[0]), _color(colors[1])],
          ),
          shape: BoxShape.circle,
        ),
      ),
      label: Text(label),
    );
  }
}

class _CatalogEditor extends StatefulWidget {
  const _CatalogEditor({
    required this.type,
    required this.destinations,
    required this.activities,
    required this.moods,
    this.item,
  });
  final String type;
  final List<CatalogItem> destinations;
  final List<CatalogItem> activities;
  final List<SafariMood> moods;
  final CatalogItem? item;

  @override
  State<_CatalogEditor> createState() => _CatalogEditorState();
}

class _CatalogEditorState extends State<_CatalogEditor> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _bestMonths;
  late final TextEditingController _tripLength;
  late final TextEditingController _weather;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _accessRoute;
  String _country = 'Uganda';
  String _difficulty = 'Moderate';
  String? _imagePath;
  late final Set<int> _selectedRelatedIds;
  late final Set<int> _selectedMoodIds;
  bool _active = true;
  bool _saving = false;

  bool get _isActivity => widget.type == 'activity';
  List<CatalogItem> get _relatedOptions =>
      _isActivity ? widget.destinations : widget.activities;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name);
    _tagline = TextEditingController(text: item?.tagline);
    _description = TextEditingController(text: item?.description);
    _location = TextEditingController(text: item?.location);
    _bestMonths = TextEditingController(text: item?.bestMonthsToVisit);
    _tripLength = TextEditingController(text: item?.recommendedTripLength);
    _weather = TextEditingController(text: item?.weatherSummary);
    _latitude = TextEditingController(text: item?.latitude?.toString());
    _longitude = TextEditingController(text: item?.longitude?.toString());
    _accessRoute = TextEditingController(text: item?.accessRoute);
    _country = item?.country ?? 'Uganda';
    const difficulties = ['Easy', 'Moderate', 'Challenging', 'Demanding'];
    final savedDifficulty = item?.difficulty?.trim();
    _difficulty =
        difficulties.contains(savedDifficulty) ? savedDifficulty! : 'Moderate';
    _selectedMoodIds = {...?item?.moodIds};
    final selectedItems = _isActivity ? item?.destinations : item?.activities;
    _selectedRelatedIds = {...?selectedItems?.map((related) => related.id)};
    _active = item?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _tagline,
      _description,
      _location,
      _bestMonths,
      _tripLength,
      _weather,
      _latitude,
      _longitude,
      _accessRoute,
    ]) {
      controller.dispose();
    }
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
    if (widget.item == null && _imagePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a page image.')));
      return;
    }
    if (_relatedOptions.isNotEmpty && _selectedRelatedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isActivity
                ? 'Select at least one destination for this activity.'
                : 'Select at least one activity for this destination.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await CatalogService.instance.save(
        item: widget.item,
        type: widget.type,
        imagePath: _imagePath,
        destinationIds:
            _isActivity ? (_selectedRelatedIds.toList()..sort()) : const [],
        activityIds:
            _isActivity ? const [] : (_selectedRelatedIds.toList()..sort()),
        moodIds:
            widget.moods
                .where((mood) => _selectedMoodIds.contains(mood.id))
                .map((mood) => mood.id)
                .toList(),
        fields: {
          'name': _name.text.trim(),
          'tagline': _tagline.text.trim(),
          'description': _description.text.trim(),
          'is_active': _active ? '1' : '0',
          if (!_isActivity) 'location': _location.text.trim(),
          if (!_isActivity) 'country': _country,
          if (!_isActivity) 'best_months_to_visit': _bestMonths.text.trim(),
          if (!_isActivity) 'recommended_trip_length': _tripLength.text.trim(),
          if (!_isActivity) 'weather_summary': _weather.text.trim(),
          if (!_isActivity) 'difficulty': _difficulty,
          if (!_isActivity) 'latitude': _latitude.text.trim(),
          if (!_isActivity) 'longitude': _longitude.text.trim(),
          if (!_isActivity) 'access_route': _accessRoute.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) {
    final existingImage = widget.item?.imageUrl ?? '';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .9,
        minChildSize: .65,
        builder:
            (context, controller) => Form(
              key: _formKey,
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    widget.item == null
                        ? 'Add ${widget.type}'
                        : 'Edit ${widget.type}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          _imagePath != null
                              ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                              : existingImage.isNotEmpty
                              ? Image.network(existingImage, fit: BoxFit.cover)
                              : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 42,
                                  ),
                                  Text('Select page image'),
                                ],
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    validator: _required,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tagline,
                    decoration: const InputDecoration(
                      labelText: 'Short introduction',
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MoodSelector(
                    moods: widget.moods,
                    selectedIds: _selectedMoodIds,
                    onChanged:
                        (mood, selected) => setState(() {
                          if (selected) {
                            _selectedMoodIds.add(mood.id);
                          } else {
                            _selectedMoodIds.remove(mood.id);
                          }
                        }),
                  ),
                  if (!_isActivity) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _location,
                      validator: _required,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value:
                          TourismCountries.isSupported(_country)
                              ? _country
                              : TourismCountries.uganda.name,
                      items:
                          TourismCountries.names
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _country = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Country'),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Destination Travel Guide',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'These details appear prominently on the public destination page.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bestMonths,
                      decoration: const InputDecoration(
                        labelText: 'Best months to visit',
                        hintText: 'e.g. June–September, December–February',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tripLength,
                      decoration: const InputDecoration(
                        labelText: 'Recommended trip length',
                        hintText: 'e.g. 3–4 days',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _difficulty,
                      items:
                          const ['Easy', 'Moderate', 'Challenging', 'Demanding']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => _difficulty = value!),
                      decoration: const InputDecoration(
                        labelText: 'Travel difficulty',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weather,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Weather guidance',
                        hintText:
                            'Describe typical temperature, rain and conditions',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitude,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              hintText: '-1.0521',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              final number = double.tryParse(text);
                              return number == null ||
                                      number < -90 ||
                                      number > 90
                                  ? 'Use -90 to 90'
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _longitude,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              hintText: '29.6220',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              final number = double.tryParse(text);
                              return number == null ||
                                      number < -180 ||
                                      number > 180
                                  ? 'Use -180 to 180'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accessRoute,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Route and access details',
                        hintText:
                            'Kampala → Kabale → Buhoma, approximately 8 hours',
                        prefixIcon: Icon(Icons.route_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SearchableCatalogSelector(
                    title:
                        _isActivity
                            ? 'Safari destinations'
                            : 'Safari activities',
                    helperText:
                        _isActivity
                            ? 'Type a destination name, select it, and it will appear below.'
                            : 'Type an activity name, select it, and it will appear below.',
                    searchLabel:
                        _isActivity
                            ? 'Search destinations'
                            : 'Search activities',
                    emptyMessage:
                        _isActivity
                            ? 'Add a safari destination first, then return here to link it.'
                            : 'Add a safari activity first, then return here to link it.',
                    options: _relatedOptions,
                    selectedIds: _selectedRelatedIds,
                    icon:
                        _isActivity
                            ? Icons.location_on_outlined
                            : Icons.hiking_rounded,
                    onAdd:
                        (item) =>
                            setState(() => _selectedRelatedIds.add(item.id)),
                    onRemove:
                        (item) =>
                            setState(() => _selectedRelatedIds.remove(item.id)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    validator: (value) {
                      final missing = _required(value);
                      if (missing != null) return missing;
                      return value!.trim().length < 20
                          ? 'Write at least 20 characters.'
                          : null;
                    },
                    minLines: 5,
                    maxLines: 9,
                    decoration: const InputDecoration(
                      labelText: 'Full page description',
                      alignLabelWithHint: true,
                    ),
                  ),
                  SwitchListTile(
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                    title: const Text('Published'),
                  ),
                  const SizedBox(height: 12),
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
                    label: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _MoodSelector extends StatelessWidget {
  const _MoodSelector({
    required this.moods,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<SafariMood> moods;
  final Set<int> selectedIds;
  final void Function(SafariMood mood, bool selected) onChanged;

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
        const SizedBox(height: 5),
        Text(
          'Choose one or more ways travellers can discover this page.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.65),
          ),
        ),
        const SizedBox(height: 11),
        if (moods.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Create a Safari Mood first, then return here to assign it.',
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                moods.map((mood) {
                  final isSelected = selectedIds.contains(mood.id);
                  return FilterChip(
                    selected: isSelected,
                    showCheckmark: true,
                    avatar: Icon(mood.icon, size: 18),
                    label: Text(mood.title),
                    onSelected: (value) => onChanged(mood, value),
                  );
                }).toList(),
          ),
      ],
    );
  }
}

class _SearchableCatalogSelector extends StatelessWidget {
  const _SearchableCatalogSelector({
    required this.title,
    required this.helperText,
    required this.searchLabel,
    required this.emptyMessage,
    required this.options,
    required this.selectedIds,
    required this.icon,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String helperText;
  final String searchLabel;
  final String emptyMessage;
  final List<CatalogItem> options;
  final Set<int> selectedIds;
  final IconData icon;
  final ValueChanged<CatalogItem> onAdd;
  final ValueChanged<CatalogItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected =
        options.where((item) => selectedIds.contains(item.id)).toList()..sort(
          (left, right) =>
              left.name.toLowerCase().compareTo(right.name.toLowerCase()),
        );
    TextEditingController? searchController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toTitleCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          helperText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.65),
          ),
        ),
        const SizedBox(height: 12),
        if (options.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(emptyMessage),
          )
        else ...[
          Autocomplete<CatalogItem>(
            displayStringForOption: (item) => item.name,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              return options
                  .where((item) {
                    if (selectedIds.contains(item.id)) return false;
                    return query.isEmpty ||
                        item.name.toLowerCase().contains(query);
                  })
                  .take(8);
            },
            onSelected: (item) {
              onAdd(item);
              searchController?.clear();
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              searchController = controller;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (_) => onSubmitted(),
                decoration: InputDecoration(
                  labelText: searchLabel,
                  hintText: 'Start typing a name',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon:
                      controller.text.isEmpty
                          ? null
                          : IconButton(
                            tooltip: 'Clear search',
                            onPressed: controller.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, matches) {
              final items = matches.toList();
              final availableWidth = MediaQuery.sizeOf(context).width - 40;
              final optionsWidth =
                  availableWidth < 420 ? availableWidth : 420.0;
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: optionsWidth,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            leading: Icon(icon),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              item.isActive ? 'Published' : 'Hidden',
                            ),
                            onTap: () => onSelected(item),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (selected.isEmpty)
            Text(
              'No selection yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  selected.map((item) {
                    return InputChip(
                      selected: true,
                      avatar: Icon(icon, size: 18),
                      label: Text(item.name),
                      tooltip: 'Remove ${item.name}',
                      onDeleted: () => onRemove(item),
                    );
                  }).toList(),
            ),
        ],
      ],
    );
  }
}
