import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/tourism_country.dart';
import '../models/catalog_item.dart';
import '../models/safari_mood.dart';
import '../services/country_service.dart';
import '../services/catalog_service.dart';

class AdminCountriesPage extends StatefulWidget {
  const AdminCountriesPage({super.key});

  @override
  State<AdminCountriesPage> createState() => _AdminCountriesPageState();
}

class _AdminCountriesPageState extends State<AdminCountriesPage> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);

  late Future<List<TourismCountry>> _countries;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _countries = CountryService.instance.fetchCountries(admin: true);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _countries;
  }

  Future<void> _edit(TourismCountry country) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _CountryEditorPage(country: country),
      ),
    );

    if (changed == true && mounted) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Countries',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<TourismCountry>>(
        future: _countries,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(_reload),
            );
          }

          final countries = snapshot.data ?? const [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
              children: [
                const _AdminIntro(),
                const SizedBox(height: 18),
                for (final country in countries) ...[
                  _CountryAdminCard(
                    country: country,
                    onEdit: () => _edit(country),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminIntro extends StatelessWidget {
  const _AdminIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'East Africa country content',
            style: TextStyle(
              color: Color(0xFF165B5D),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Manage the image and introduction shown on the tourist dashboard and each Country Hub. Tour totals are calculated automatically.',
            style: TextStyle(
              color: Color(0xFF53605D),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryAdminCard extends StatelessWidget {
  const _CountryAdminCard({
    required this.country,
    required this.onEdit,
  });

  final TourismCountry country;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkOrFallback(url: country.cardImageUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xB0000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 17,
                    right: 17,
                    bottom: 15,
                    child: Text(
                      country.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 15, 17, 17),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.tagline.isEmpty
                              ? 'No tagline yet'
                              : country.tagline,
                          style: const TextStyle(
                            color: Color(0xFF17211F),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${country.tourCount} ${country.tourCount == 1 ? 'Tour' : 'Tours'} • ${country.isActive ? 'Active' : 'Hidden'}',
                          style: TextStyle(
                            color: country.isActive
                                ? const Color(0xFF165B5D)
                                : Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: onEdit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF46627)
                          .withValues(alpha: .12),
                      foregroundColor: const Color(0xFFF46627),
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontWeight: FontWeight.w900),
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

class _CountryEditorPage extends StatefulWidget {
  const _CountryEditorPage({required this.country});

  final TourismCountry country;

  @override
  State<_CountryEditorPage> createState() => _CountryEditorPageState();
}

class _CountryEditorPageState extends State<_CountryEditorPage> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _tagline;
  late final TextEditingController _introduction;
  late final TextEditingController _sortOrder;

  bool _active = true;
  bool _saving = false;
  String? _cardImagePath;
  String? _heroImagePath;

  late Future<TourismCatalog> _catalog;
  late Future<List<SafariMood>> _moods;
  late Set<int> _selectedMoodIds;
  late Set<int> _selectedActivityIds;
  late Set<int> _selectedDestinationIds;

  @override
  void initState() {
    super.initState();
    _tagline = TextEditingController(text: widget.country.tagline);
    _introduction = TextEditingController(text: widget.country.introduction);
    _sortOrder =
        TextEditingController(text: widget.country.sortOrder.toString());
    _active = widget.country.isActive;
    _selectedMoodIds = widget.country.moodIds.toSet();
    _selectedActivityIds = widget.country.activityIds.toSet();
    _selectedDestinationIds = widget.country.destinationIds.toSet();

    _catalog = CatalogService.instance.fetchCatalog(admin: true);
    _moods = _catalog.then((catalog) => catalog.moods);
  }

  @override
  void dispose() {
    _tagline.dispose();
    _introduction.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  Future<void> _pickCard() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (file != null && mounted) {
      setState(() => _cardImagePath = file.path);
    }
  }

  Future<void> _pickHero() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (file != null && mounted) {
      setState(() => _heroImagePath = file.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await CountryService.instance.updateCountry(
        country: widget.country,
        tagline: _tagline.text,
        introduction: _introduction.text,
        sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
        isActive: _active,
        cardImagePath: _cardImagePath,
        heroImagePath: _heroImagePath,
        moodIds: _selectedMoodIds.toList(),
        activityIds: _selectedActivityIds.toList(),
        destinationIds: _selectedDestinationIds.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.country.name} updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          widget.country.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
          children: [
            _ImageEditor(
              title: 'Country Card Image',
              subtitle: 'Used in Explore East Africa.',
              existingUrl: widget.country.cardImageUrl,
              localPath: _cardImagePath,
              onPick: _pickCard,
            ),
            const SizedBox(height: 16),
            _ImageEditor(
              title: 'Country Hero Image',
              subtitle: 'Used at the top of the Country Hub.',
              existingUrl: widget.country.heroImageUrl,
              localPath: _heroImagePath,
              onPick: _pickHero,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _tagline,
              decoration: const InputDecoration(
                labelText: 'Tagline',
                hintText: 'The Pearl of Africa',
              ),
              maxLength: 255,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _introduction,
              decoration: const InputDecoration(
                labelText: 'Country introduction',
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 7,
              maxLength: 3000,
            ),
            const SizedBox(height: 10),

            _ExperienceAssignments(
              moods: _moods,
              selectedIds: _selectedMoodIds,
              onChanged: (ids) {
                setState(() {
                  _selectedMoodIds = ids;
                });
              },
            ),

            const SizedBox(height: 16),

            _CatalogAssignments(
              catalog: _catalog,
              title: 'Activities',
              subtitle:
                  'Choose the safari activities tourists should discover in this country.',
              type: _AssignmentType.activities,
              selectedIds: _selectedActivityIds,
              onChanged: (ids) {
                setState(() {
                  _selectedActivityIds = ids;
                });
              },
            ),

            const SizedBox(height: 16),

            _CatalogAssignments(
              catalog: _catalog,
              title: 'Destinations',
              subtitle:
                  'Choose the destinations that belong to this country. A destination can belong to one country.',
              type: _AssignmentType.destinations,
              selectedIds: _selectedDestinationIds,
              onChanged: (ids) {
                setState(() {
                  _selectedDestinationIds = ids;
                });
              },
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller: _sortOrder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Display order',
              ),
              validator: (value) {
                if (int.tryParse(value?.trim() ?? '') == null) {
                  return 'Enter a valid display order.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              contentPadding: EdgeInsets.zero,
              activeColor: _secondary,
              title: const Text(
                'Active',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'Inactive countries are hidden from tourists.',
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  shape: const StadiumBorder(),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Country',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ExperienceAssignments extends StatelessWidget {
  const _ExperienceAssignments({
    required this.moods,
    required this.selectedIds,
    required this.onChanged,
  });

  final Future<List<SafariMood>> moods;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: FutureBuilder<List<SafariMood>>(
        future: moods,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Text(
              'Experiences could not be loaded.',
              style: TextStyle(
                color: Color(0xFFF46627),
                fontWeight: FontWeight.w800,
              ),
            );
          }

          final items = snapshot.data ?? const <SafariMood>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Experiences / Safari Moods',
                style: TextStyle(
                  color: Color(0xFF165B5D),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Choose the Experiences tourists should see inside this country.',
                style: TextStyle(
                  color: Color(0xFF66716E),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              if (items.isEmpty)
                const Text(
                  'No Safari Moods have been created yet.',
                )
              else
                for (final mood in items)
                  CheckboxListTile(
                    value: selectedIds.contains(mood.id),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: const Color(0xFF165B5D),
                    title: Text(
                      mood.title,
                      style: const TextStyle(
                        color: Color(0xFF17211F),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: mood.subtitle.trim().isEmpty
                        ? null
                        : Text(
                            mood.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onChanged: (checked) {
                      final next = {...selectedIds};

                      if (checked == true) {
                        next.add(mood.id);
                      } else {
                        next.remove(mood.id);
                      }

                      onChanged(next);
                    },
                  ),
            ],
          );
        },
      ),
    );
  }
}



enum _AssignmentType {
  activities,
  destinations,
}

class _CatalogAssignments extends StatelessWidget {
  const _CatalogAssignments({
    required this.catalog,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.selectedIds,
    required this.onChanged,
  });

  final Future<TourismCatalog> catalog;
  final String title;
  final String subtitle;
  final _AssignmentType type;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: FutureBuilder<TourismCatalog>(
        future: catalog,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Text(
              '$title could not be loaded.',
              style: const TextStyle(
                color: Color(0xFFF46627),
                fontWeight: FontWeight.w800,
              ),
            );
          }

          final data = snapshot.data;
          final List<CatalogItem> items = type == _AssignmentType.activities
              ? (data?.activities ?? const <CatalogItem>[])
              : (data?.destinations ?? const <CatalogItem>[]);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF165B5D),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF66716E),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              if (items.isEmpty)
                Text('No $title have been created yet.')
              else
                for (final item in items)
                  CheckboxListTile(
                    value: selectedIds.contains(item.id),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: const Color(0xFF165B5D),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF17211F),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: type == _AssignmentType.destinations &&
                            item.location?.trim().isNotEmpty == true
                        ? Text(
                            item.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : item.tagline?.trim().isNotEmpty == true
                            ? Text(
                                item.tagline!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                    onChanged: (checked) {
                      final next = {...selectedIds};

                      if (checked == true) {
                        next.add(item.id);
                      } else {
                        next.remove(item.id);
                      }

                      onChanged(next);
                    },
                  ),
            ],
          );
        },
      ),
    );
  }
}


class _ImageEditor extends StatelessWidget {
  const _ImageEditor({
    required this.title,
    required this.subtitle,
    required this.existingUrl,
    required this.localPath,
    required this.onPick,
  });

  final String title;
  final String subtitle;
  final String existingUrl;
  final String? localPath;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (localPath != null) {
      image = Image.file(
        File(localPath!),
        fit: BoxFit.cover,
      );
    } else {
      image = _NetworkOrFallback(url: existingUrl);
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: image,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF165B5D),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF66716E),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF165B5D),
              shape: const StadiumBorder(),
            ),
            child: Text(
              existingUrl.isEmpty && localPath == null
                  ? 'Choose Image'
                  : 'Change Image',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkOrFallback extends StatelessWidget {
  const _NetworkOrFallback({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF487C79), Color(0xFF0B3D3F)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.landscape_outlined,
            color: Colors.white30,
            size: 52,
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF165B5D),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white54),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Color(0xFFF46627),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
