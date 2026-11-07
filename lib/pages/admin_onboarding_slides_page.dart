import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/onboarding_slide.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';

class AdminOnboardingSlidesPage extends StatefulWidget {
  const AdminOnboardingSlidesPage({super.key});

  @override
  State<AdminOnboardingSlidesPage> createState() =>
      _AdminOnboardingSlidesPageState();
}

class _AdminOnboardingSlidesPageState extends State<AdminOnboardingSlidesPage> {
  List<OnboardingSlide> _slides = const [];
  bool _loading = true;
  bool _reordering = false;
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
      final slides = await OnboardingService.instance.fetchSlides(admin: true);
      if (mounted) {
        setState(() {
          _slides = slides;
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

  Future<void> _edit({OnboardingSlide? slide}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OnboardingSlideEditor(slide: slide),
    );
    if (saved == true) await _load();
  }

  Future<void> _move(int index, int direction) async {
    final target = index + direction;
    if (_reordering || target < 0 || target >= _slides.length) return;
    final reordered = [..._slides];
    final moved = reordered.removeAt(index);
    reordered.insert(target, moved);
    setState(() {
      _slides = reordered;
      _reordering = true;
    });
    try {
      await OnboardingService.instance.reorder(
        reordered.map((item) => item.id).toList(),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        await _load();
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  Future<void> _delete(OnboardingSlide slide) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete ${slide.title}?'),
            content: const Text(
              'This removes the slide and its uploaded image. You can add another slide later.',
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
      await OnboardingService.instance.deleteSlide(slide);
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
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('First Page Slides'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton:
          !_loading && _slides.length < 3
              ? FloatingActionButton.extended(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Slide'),
              )
              : null,
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder:
            (_, __) => Container(
              height: 210,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 46,
                color: Color(0xFF66736F),
              ),
              const SizedBox(height: 14),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton(onPressed: _load, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }
    if (_slides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.view_carousel_outlined,
                size: 50,
                color: Color(0xFF66736F),
              ),
              const SizedBox(height: 12),
              const Text(
                'No first-page slides yet.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add up to three slides for the app onboarding experience.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Slide'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF12372A),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium Onboarding',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tourists see these slides only on their first app launch. Keep text short and use portrait images.',
                style: TextStyle(color: Color(0xFFD4E4DE), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < _slides.length; index++) ...[
          _SlideAdminCard(
            slide: _slides[index],
            index: index,
            count: _slides.length,
            reordering: _reordering,
            onEdit: () => _edit(slide: _slides[index]),
            onDelete: () => _delete(_slides[index]),
            onMoveUp: () => _move(index, -1),
            onMoveDown: () => _move(index, 1),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SlideAdminCard extends StatelessWidget {
  const _SlideAdminCard({
    required this.slide,
    required this.index,
    required this.count,
    required this.reordering,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final OnboardingSlide slide;
  final int index;
  final int count;
  final bool reordering;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final remoteUrl = AuthService.storageUrl(slide.image);
    final fallback =
        fallbackOnboardingSlides[index < fallbackOnboardingSlides.length
                ? index
                : fallbackOnboardingSlides.length - 1]
            .assetFallback!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDFE8E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                remoteUrl.isEmpty
                    ? Image.asset(fallback, fit: BoxFit.cover)
                    : Image.network(
                      remoteUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              Image.asset(fallback, fit: BoxFit.cover),
                    ),
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
                  left: 14,
                  top: 14,
                  child: _StatusPill(
                    label: 'Slide ${index + 1}',
                    color: const Color(0xFF25C6B6),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: _StatusPill(
                    label: slide.isActive ? 'Visible' : 'Hidden',
                    color:
                        slide.isActive
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF68736F),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Text(
                    slide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF5D6965), height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F6F3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        slide.buttonLabel,
                        style: const TextStyle(
                          color: Color(0xFF136C62),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Move up',
                      onPressed: reordering || index == 0 ? null : onMoveUp,
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                    IconButton(
                      tooltip: 'Move down',
                      onPressed:
                          reordering || index == count - 1 ? null : onMoveDown,
                      icon: const Icon(Icons.arrow_downward_rounded),
                    ),
                    PopupMenuButton<String>(
                      onSelected:
                          (value) => value == 'edit' ? onEdit() : onDelete(),
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit slide'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete slide'),
                            ),
                          ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OnboardingSlideEditor extends StatefulWidget {
  const _OnboardingSlideEditor({this.slide});
  final OnboardingSlide? slide;

  @override
  State<_OnboardingSlideEditor> createState() => _OnboardingSlideEditorState();
}

class _OnboardingSlideEditorState extends State<_OnboardingSlideEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _button;
  bool _active = true;
  bool _saving = false;
  XFile? _image;
  Uint8List? _imagePreviewBytes;

  @override
  void initState() {
    super.initState();
    final slide = widget.slide;
    _title = TextEditingController(text: slide?.title ?? '');
    _subtitle = TextEditingController(text: slide?.subtitle ?? '');
    _button = TextEditingController(
      text: slide?.buttonLabel ?? 'Swipe to Explore',
    );
    _active = slide?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _button.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (image == null) return;
    try {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _image = image;
        _imagePreviewBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected image. Please try another image.')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await OnboardingService.instance.saveSlide(
        slide: widget.slide,
        title: _title.text,
        subtitle: _subtitle.text,
        buttonLabel: _button.text,
        isActive: _active,
        imageFile: _image,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * .94),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            media.viewInsets.bottom + 24,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DEDB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.slide == null
                  ? 'Add Onboarding Slide'
                  : 'Edit Onboarding Slide',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use a portrait photo with a calm lower area so the text stays easy to read.',
              style: TextStyle(color: Color(0xFF66736F), height: 1.4),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _saving ? null : _pickImage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 185,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    _imagePreviewBytes != null
                        ? Image.memory(_imagePreviewBytes!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _ImagePlaceholder())
                        : _ExistingOrPlaceholder(slide: widget.slide),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saving ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _image == null
                    ? 'Choose portrait image'
                    : 'Choose a different image',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Title'),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a title.'
                          : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitle,
              maxLength: 180,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Subtitle'),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a subtitle.'
                          : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _button,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Button label'),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a button label.'
                          : null,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Visible in the app',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Hidden slides remain available for later.'),
              value: _active,
              onChanged:
                  _saving ? null : (value) => setState(() => _active = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child:
                  _saving
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Save Slide'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExistingOrPlaceholder extends StatelessWidget {
  const _ExistingOrPlaceholder({this.slide});
  final OnboardingSlide? slide;

  @override
  Widget build(BuildContext context) {
    final remoteUrl = AuthService.storageUrl(slide?.image);
    if (remoteUrl.isNotEmpty) {
      return Image.network(
        remoteUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
      );
    }
    return const _ImagePlaceholder();
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 42,
            color: Color(0xFF4C625B),
          ),
          SizedBox(height: 8),
          Text(
            'Tap to select an image',
            style: TextStyle(
              color: Color(0xFF4C625B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
