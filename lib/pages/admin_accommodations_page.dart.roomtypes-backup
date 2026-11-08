import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/catalog_item.dart';
import '../services/api_exception.dart';
import '../services/catalog_service.dart';

const _amenityOptions = <String>[
  'Wi-Fi',
  'Restaurant',
  'Swimming pool',
  'Parking',
  'Air conditioning',
  'Bar / lounge',
  'Room service',
  'Airport transfer',
  'Family rooms',
  'Spa',
  'Laundry',
  'Hot water',
  'Power backup',
  'Campfire',
  'Guided activities',
  'Accessible rooms',
];

class AdminAccommodationsPage extends StatefulWidget {
  const AdminAccommodationsPage({super.key, required this.destination});

  final CatalogItem destination;

  @override
  State<AdminAccommodationsPage> createState() =>
      _AdminAccommodationsPageState();
}

class _AdminAccommodationsPageState extends State<AdminAccommodationsPage> {
  List<Accommodation> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await CatalogService.instance.fetchAccommodations(
        widget.destination,
      );
      if (mounted)
        setState(() {
          _items = items;
          _loading = false;
        });
    } on ApiException catch (error) {
      if (mounted)
        setState(() {
          _error = error.message;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Accommodations could not be loaded.';
          _loading = false;
        });
    }
  }

  Future<void> _edit([Accommodation? accommodation]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _AccommodationEditor(
            destination: widget.destination,
            accommodation: accommodation,
          ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(Accommodation accommodation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete ${accommodation.name}?'),
            content: const Text(
              'This accommodation will be removed from the destination page.',
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
      await CatalogService.instance.deleteAccommodation(accommodation);
      if (mounted) await _load();
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
      appBar: AppBar(title: Text('${widget.destination.name} accommodation')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add accommodation'),
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
              : _items.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'No accommodation has been added to this destination yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _edit(item),
                        child: Row(
                          children: [
                            item.imageUrl.isEmpty
                                ? Container(
                                  width: 112,
                                  height: 112,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                  child: const Icon(
                                    Icons.hotel_rounded,
                                    size: 40,
                                  ),
                                )
                                : Image.network(
                                  item.imageUrl,
                                  width: 112,
                                  height: 112,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => const SizedBox(
                                        width: 112,
                                        height: 112,
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      ),
                                ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(13),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.formattedPrice,
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item.isActive ? 'Published' : 'Hidden',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected:
                                  (value) =>
                                      value == 'edit'
                                          ? _edit(item)
                                          : _delete(item),
                              itemBuilder:
                                  (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

class _AccommodationEditor extends StatefulWidget {
  const _AccommodationEditor({required this.destination, this.accommodation});

  final CatalogItem destination;
  final Accommodation? accommodation;

  @override
  State<_AccommodationEditor> createState() => _AccommodationEditorState();
}

class _AccommodationEditorState extends State<_AccommodationEditor> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _website;
  final List<String> _imagePaths = [];
  final Set<String> _selectedAmenities = {};
  String? _galleryNotice;
  String? _saveError;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.accommodation;
    _name = TextEditingController(text: item?.name);
    _location = TextEditingController(text: item?.location);
    _price = TextEditingController(
      text: item == null ? '' : item.pricePerNight.toString(),
    );
    _description = TextEditingController(text: item?.description);
    _selectedAmenities.addAll(item?.amenities ?? const []);
    _phone = TextEditingController(text: item?.contactPhone);
    _email = TextEditingController(text: item?.contactEmail);
    _website = TextEditingController(text: item?.website);
    _active = item?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _location,
      _price,
      _description,
      _phone,
      _email,
      _website,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 2200,
    );
    if (images.isEmpty || !mounted) return;
    setState(() {
      _imagePaths
        ..clear()
        ..addAll(images.take(3).map((image) => image.path));
      _galleryNotice =
          images.length > 3
              ? 'Only the first three selected photos will be used.'
              : null;
      _saveError = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saveError = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(
        () => _saveError = 'Check the highlighted fields, then try again.',
      );
      return;
    }
    if (widget.accommodation == null && _imagePaths.isEmpty) {
      setState(
        () => _saveError = 'Select at least one lodge photo before saving.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final amenities = _selectedAmenities.toList()..sort();
      await CatalogService.instance.saveAccommodation(
        destination: widget.destination,
        accommodation: widget.accommodation,
        imagePaths: _imagePaths,
        amenities: amenities,
        fields: {
          'name': _name.text.trim(),
          'location': _location.text.trim(),
          'price_per_night': _price.text.trim(),
          'description': _description.text.trim(),
          'contact_phone': _phone.text.trim(),
          'contact_email': _email.text.trim(),
          'website': _website.text.trim(),
          'is_active': _active ? '1' : '0',
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _saveError = error.message);
    } catch (_) {
      if (mounted)
        setState(
          () =>
              _saveError =
                  'Accommodation could not be saved. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) {
    final existingImages =
        widget.accommodation?.galleryUrls ?? const <String>[];
    final amenityOptions =
        <String>{..._amenityOptions, ..._selectedAmenities}.toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .92,
        minChildSize: .65,
        builder:
            (context, controller) => Form(
              key: _formKey,
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    widget.accommodation == null
                        ? 'Add accommodation'
                        : 'Edit accommodation',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    'For ${widget.destination.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lodge Gallery',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w300),
                        ),
                      ),
                      Text(
                        '${_imagePaths.isNotEmpty ? _imagePaths.length : existingImages.length}/3 photos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                          child: _GallerySlot(
                            index: index,
                            localPath:
                                index < _imagePaths.length
                                    ? _imagePaths[index]
                                    : null,
                            networkUrl:
                                _imagePaths.isEmpty &&
                                        index < existingImages.length
                                    ? existingImages[index]
                                    : null,
                            onTap: _pickImages,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.collections_outlined),
                    label: Text(
                      existingImages.isEmpty && _imagePaths.isEmpty
                          ? 'Choose up to 3 photos'
                          : 'Replace gallery photos',
                    ),
                  ),
                  if (_galleryNotice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _galleryNotice!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Accommodation name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _location,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Location within destination',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (_required(value) != null)
                        return 'Enter the nightly price.';
                      final price = double.tryParse(value!.trim());
                      return price == null || price < 0
                          ? 'Enter a valid USD price.'
                          : null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Price per night (USD)',
                      prefixText: '\$ ',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    children:
                        amenityOptions.map((amenity) {
                          final selected = _selectedAmenities.contains(amenity);
                          return ChoiceChip(
                            label: Text(amenity),
                            selected: selected,
                            avatar:
                                selected
                                    ? const Icon(Icons.check_rounded, size: 18)
                                    : null,
                            onSelected:
                                (value) => setState(() {
                                  if (value) {
                                    _selectedAmenities.add(amenity);
                                  } else {
                                    _selectedAmenities.remove(amenity);
                                  }
                                }),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 8,
                    validator: (value) {
                      if (_required(value) != null)
                        return 'Enter a description.';
                      return value!.trim().length < 20
                          ? 'Write at least 20 characters.'
                          : null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact phone (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Contact email (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _website,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Website (optional)',
                      hintText: 'https://...',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                    title: const Text('Published'),
                    subtitle: const Text(
                      'Published accommodation appears on the destination page.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_saveError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              _saveError!,
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                    label: Text(_saving ? 'Saving...' : 'Save accommodation'),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _GallerySlot extends StatelessWidget {
  const _GallerySlot({
    required this.index,
    required this.onTap,
    this.localPath,
    this.networkUrl,
  });

  final int index;
  final String? localPath;
  final String? networkUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image =
        localPath != null
            ? Image.file(File(localPath!), fit: BoxFit.cover)
            : networkUrl != null
            ? Image.network(
              networkUrl!,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image_outlined)),
            )
            : null;

    return AspectRatio(
      aspectRatio: .82,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                image ??
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined),
                    const SizedBox(height: 5),
                    Text(
                      'Photo ${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
