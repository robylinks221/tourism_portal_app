import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admin_customization_service.dart';
import '../theme/app_appearance_controller.dart';

const _teal = Color(0xFF165B5D);
const _orange = Color(0xFFF46627);
const _cream = Color(0xFFF4EEE1);
const _ink = Color(0xFF183A3C);
const _muted = Color(0xFF738181);

class AdminAppAppearancePage extends StatefulWidget {
  const AdminAppAppearancePage({super.key});

  @override
  State<AdminAppAppearancePage> createState() => _AdminAppAppearancePageState();
}

class _AdminAppAppearancePageState extends State<AdminAppAppearancePage> {
  Color primary = _teal;
  Color secondary = _orange;
  Color background = _cream;
  String font = 'Nexa';
  String mode = 'system';
  bool busy = false;
  String? error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { busy = true; error = null; });
    try {
      final data = await AdminCustomizationService.instance.appearance();
      if (!mounted) return;
      setState(() {
        primary = _parseColor(data['primary_color'], _teal);
        secondary = _parseColor(data['secondary_color'], _orange);
        background = _parseColor(data['background_color'], _cream);
        font = data['font_family']?.toString() ?? 'Nexa';
        mode = data['display_mode']?.toString() ?? 'system';
      });
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Color _parseColor(dynamic value, Color fallback) {
    final hex = value?.toString().replaceFirst('#', '');
    if (hex == null || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return fallback;
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _hex(Color color) => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Future<void> _save() async {
    setState(() { busy = true; error = null; });
    try {
      final saved = await AdminCustomizationService.instance.saveAppearance(
        font: font, primary: _hex(primary),
        secondary: _hex(secondary), background: _hex(background), mode: mode);
      // Apply selected values immediately, even if the save endpoint returns
      // only a success message instead of the full appearance object.
      AppAppearanceController.instance.apply({
        'primary_color': _hex(primary),
        'secondary_color': _hex(secondary),
        'background_color': _hex(background),
        'font_family': font,
        'display_mode': mode,
      });
      // Read back the authoritative saved values for subsequent launches.
      // Do not block immediate feedback on a second network request.
      if (saved['appearance'] is Map || saved['primary_color'] != null) {
        AppAppearanceController.instance.apply(saved);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appearance saved on the server.')));
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _resetServer() async {
    setState(() { busy = true; error = null; });
    try {
      final data = await AdminCustomizationService.instance.resetAppearance();
      AppAppearanceController.instance.apply(
        data['appearance'] is Map || data['primary_color'] != null
            ? data
            : {
                'primary_color': '#165B5D',
                'secondary_color': '#F46627',
                'background_color': '#F4EEE1',
                'font_family': 'Nexa',
                'display_mode': 'system',
              },
      );
      if (!mounted) return;
      setState(() {
        primary = _parseColor(data['primary_color'], _teal);
        secondary = _parseColor(data['secondary_color'], _orange);
        background = _parseColor(data['background_color'], _cream);
        font = data['font_family']?.toString() ?? 'Nexa';
        mode = data['display_mode']?.toString() ?? 'system';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default appearance restored.')));
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  static const fonts = ['Nexa', 'Roboto', 'Poppins', 'Inter'];
  // Nexa needs licensed font files registered in pubspec.yaml before it can render.
  String? get previewFont => font == 'App default' || font == 'Nexa'
      ? null : font;

  void reset() => setState(() {
    primary = _teal;
    secondary = _orange;
    background = _cream;
    font = 'App default';
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Appearance Studio',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        actions: [
          IconButton(
            tooltip: 'Reset preview',
            onPressed: busy ? null : _resetServer,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 42),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, Color.lerp(primary, Colors.black, .34)!],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: primary.withValues(alpha: .18), blurRadius: 26, offset: const Offset(0, 12))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DESIGN STUDIO',
                        style: TextStyle(color: Color(0xFFB7D6D1),
                            fontSize: 10, fontWeight: FontWeight.w800,
                            letterSpacing: 2.2)),
                    const SizedBox(height: 12),
                    const Text('Your brand, beautifully.',
                        style: TextStyle(color: Colors.white, fontSize: 29,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('A consistent visual identity across every journey. Fine-tune the colours and typography of Tourist Guide.',
                        style: TextStyle(color: Color(0xFFDFEBE8), height: 1.5)),
                    const SizedBox(height: 17),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text('LIVE DESIGN PREVIEW',
                          style: TextStyle(color: Colors.white, fontSize: 10,
                              letterSpacing: 1, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _sectionHeading('01', 'Typography',
                  'Choose the personality of your app text.'),
              const SizedBox(height: 12),
              _panel([
                for (final name in fonts) ...[
                  _fontOption(name),
                  if (name != fonts.last) const Divider(height: 1, color: Color(0xFFF0F0EB)),
                ],
                const SizedBox(height: 12),
                const Text('Nexa is available as a design choice. Its actual font will display after the licensed Nexa files are added to the Flutter project.',
                    style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
              ]),
              const SizedBox(height: 25),
              _sectionHeading('02', 'Colour palette',
                  'Tap a colour swatch to open the picker, or type a HEX code.'),
              const SizedBox(height: 12),
              _panel([
                _colorOption('Primary', 'Navigation, headings & main actions',
                    primary, (c) => setState(() => primary = c)),
                const Divider(height: 23, color: Color(0xFFF0F0EB)),
                _colorOption('Secondary', 'Highlights & accent buttons',
                    secondary, (c) => setState(() => secondary = c)),
                const Divider(height: 23, color: Color(0xFFF0F0EB)),
                _colorOption('Background', 'Page background & surfaces',
                    background, (c) => setState(() => background = c)),
              ]),
              const SizedBox(height: 25),
              _sectionHeading('03', 'Live preview',
                  'See your choices together before publishing.'),
              const SizedBox(height: 12),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE9EAE5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(children: [
                        const Icon(Icons.explore_outlined, color: Colors.white),
                        const SizedBox(width: 10),
                        Text('Tourist Guide',
                            style: TextStyle(fontFamily: previewFont,
                                color: Colors.white, fontSize: 18,
                                fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Explore East Africa',
                              style: TextStyle(fontFamily: previewFont,
                                  fontSize: 25, fontWeight: FontWeight.w800,
                                  color: primary)),
                          const SizedBox(height: 9),
                          Text('Find exceptional guides, inspiring places and experiences worth sharing.',
                              style: TextStyle(fontFamily: previewFont,
                                  color: _ink, height: 1.5)),
                          const SizedBox(height: 19),
                          Wrap(spacing: 9, runSpacing: 9, children: [
                            _previewButton('Explore tours', primary),
                            _previewButton('Book now', secondary),
                          ]),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(children: [
                              Icon(Icons.landscape_outlined, color: primary, size: 29),
                              const SizedBox(width: 13),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Signature safari',
                                      style: TextStyle(fontFamily: previewFont,
                                          fontWeight: FontWeight.w800, color: _ink)),
                                  const SizedBox(height: 4),
                                  Text('Discover remarkable destinations',
                                      style: TextStyle(fontFamily: previewFont,
                                          color: _muted, fontSize: 12)),
                                ],
                              )),
                              Icon(Icons.arrow_forward_rounded, color: secondary),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: busy ? null : _resetServer,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Restore default theme'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _teal,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(value: mode, decoration: const InputDecoration(labelText: 'Display mode'),
                items: const [DropdownMenuItem(value: 'system', child: Text('System')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'dark', child: Text('Dark'))],
                onChanged: busy ? null : (v) { if (v != null) setState(() => mode = v); }),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: busy ? null : _save, icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(busy ? 'Saving changes…' : 'Publish appearance')),
              const SizedBox(height: 10),
              const Text('Published colours update theme-aware screens immediately. Other screens will follow as their fixed colours are migrated.',
                textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String number, String title, String subtitle) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(color: const Color(0xFFE5EEEB),
              borderRadius: BorderRadius.circular(9)),
          child: Text(number, style: const TextStyle(color: _teal,
              fontSize: 11, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: _ink,
              fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        ])),
      ]);

  Widget _panel(List<Widget> children) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE9EAE5)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );

  Widget _fontOption(String name) {
    final selected = font == name;
    return InkWell(
      onTap: () => setState(() => font = name),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE6F0ED) : const Color(0xFFF5F5F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Aa', style: TextStyle(
              fontFamily: name == 'App default' || name == 'Nexa' ? null : name,
              fontSize: 17, fontWeight: FontWeight.w800, color: _teal)),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: _ink,
                fontWeight: FontWeight.w700, fontSize: 14)),
            if (name == 'Nexa') const Text('Font files required',
                style: TextStyle(color: _muted, fontSize: 11)),
          ])),
          Icon(selected ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
              color: selected ? _teal : const Color(0xFFBCC6C2)),
        ]),
      ),
    );
  }

  Widget _colorOption(String title, String subtitle, Color color,
      ValueChanged<Color> onChange) {
    return Row(children: [
      InkWell(
        onTap: () => _showPicker(title, color, onChange),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1E4DF), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x12000000),
                blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: const Icon(Icons.colorize_rounded,
              color: Colors.white, size: 20,
              shadows: [Shadow(color: Colors.black54, blurRadius: 5)]),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: _ink,
            fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 5),
        Text(_hex(color), style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12, color: _teal)),
      ])),
      IconButton(
        tooltip: 'Pick $title colour',
        onPressed: () => _showPicker(title, color, onChange),
        icon: const Icon(Icons.palette_outlined, color: _teal),
        style: IconButton.styleFrom(backgroundColor: const Color(0xFFEAF2EF)),
      ),
    ]);
  }

  Widget _previewButton(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: TextStyle(fontFamily: previewFont,
        color: Colors.white, fontWeight: FontWeight.w800)),
  );

  Future<void> _showPicker(String title, Color initial,
      ValueChanged<Color> onChange) async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => _PremiumColorPicker(title: title, initial: initial),
    );
    if (result != null && mounted) onChange(result);
  }
}

class _PremiumColorPicker extends StatefulWidget {
  const _PremiumColorPicker({required this.title, required this.initial});
  final String title;
  final Color initial;

  @override
  State<_PremiumColorPicker> createState() => _PremiumColorPickerState();
}

class _PremiumColorPickerState extends State<_PremiumColorPicker> {
  late HSVColor hsv;
  late TextEditingController hexController;
  String? error;

  static const presets = [
    Color(0xFF165B5D), Color(0xFFF46627), Color(0xFFF4EEE1),
    Color(0xFF233B54), Color(0xFF668C76), Color(0xFFB88D55),
    Color(0xFF744D72), Color(0xFF1D1D1D), Color(0xFFFFFFFF),
    Color(0xFFCC6D66), Color(0xFF477DB0), Color(0xFFDFBC7B),
  ];

  @override
  void initState() {
    super.initState();
    hsv = HSVColor.fromColor(widget.initial);
    hexController = TextEditingController(text: _hex(hsv.toColor()));
  }

  @override
  void dispose() {
    hexController.dispose();
    super.dispose();
  }

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  void _setColor(Color c) {
    setState(() {
      hsv = HSVColor.fromColor(c);
      hexController.text = _hex(c);
      error = null;
    });
  }

  void _setHsv(HSVColor c) {
    setState(() {
      hsv = c;
      hexController.text = _hex(c.toColor());
      error = null;
    });
  }

  void _applyHex(String text) {
    final clean = text.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(clean)) {
      setState(() => error = 'Enter a valid six-digit HEX code.');
      return;
    }
    _setColor(Color(int.parse('FF$clean', radix: 16)));
  }

  @override
  Widget build(BuildContext context) {
    final selected = hsv.toColor();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(21),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.palette_outlined, color: _teal),
                const SizedBox(width: 10),
                Expanded(child: Text('${widget.title} colour',
                    style: const TextStyle(fontSize: 19,
                        fontWeight: FontWeight.w800, color: _ink))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                height: 62,
                decoration: BoxDecoration(
                  color: selected,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(height: 18),
              const Text('CHOOSE A SHADE',
                  style: TextStyle(color: _muted, fontSize: 10,
                      letterSpacing: 1.4, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              // A real interactive saturation/value surface: drag anywhere to choose.
              LayoutBuilder(builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _fromPosition(
                      details.localPosition, constraints.maxWidth, 152),
                  onPanUpdate: (details) => _fromPosition(
                      details.localPosition, constraints.maxWidth, 152),
                  child: Container(
                    width: double.infinity, height: 152,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [Colors.white,
                          HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor()],
                      ),
                    ),
                    child: Stack(children: [
                      Container(decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      )),
                      Positioned(
                        left: (constraints.maxWidth * hsv.saturation - 10)
                            .clamp(0.0, constraints.maxWidth - 20),
                        top: ((1 - hsv.value) * 152 - 10).clamp(0.0, 132.0),
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(
                              color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text('HUE', style: TextStyle(color: _muted,
                  fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                  thumbColor: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                ),
                child: Slider(
                  value: hsv.hue, min: 0, max: 360,
                  onChanged: (v) => _setHsv(hsv.withHue(v)),
                ),
              ),
              const SizedBox(height: 5),
              const Text('QUICK COLOURS',
                  style: TextStyle(color: _muted, fontSize: 10,
                      letterSpacing: 1.4, fontWeight: FontWeight.w800)),
              const SizedBox(height: 11),
              Wrap(spacing: 9, runSpacing: 9, children: [
                for (final c in presets)
                  InkWell(
                    onTap: () => _setColor(c),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 39, height: 39,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: c.toARGB32() == selected.toARGB32()
                              ? _teal : const Color(0xFFE2E4E1),
                          width: c.toARGB32() == selected.toARGB32() ? 3 : 1,
                        ),
                      ),
                      child: c.toARGB32() == selected.toARGB32()
                          ? Icon(Icons.check_rounded,
                              color: c.computeLuminance() > .55
                                  ? Colors.black87 : Colors.white)
                          : null,
                    ),
                  ),
              ]),
              const SizedBox(height: 18),
              const Text('HEX COLOUR CODE',
                  style: TextStyle(color: _muted, fontSize: 10,
                      letterSpacing: 1.4, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(
                  controller: hexController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-fA-F0-9#]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  onSubmitted: _applyHex,
                  decoration: InputDecoration(
                    isDense: true,
                    errorText: error,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )),
                const SizedBox(width: 9),
                FilledButton(
                  onPressed: () => _applyHex(hexController.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    minimumSize: const Size(68, 49),
                  ),
                  child: const Text('Apply'),
                ),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(
                  onPressed: () {
                    final clean = hexController.text.trim().replaceFirst('#', '');
                    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(clean)) {
                      Navigator.pop(context, Color(int.parse('FF$clean', radix: 16)));
                    } else {
                      setState(() => error = 'Enter a valid six-digit HEX code.');
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: _teal),
                  child: const Text('Use colour'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _fromPosition(Offset position, double width, double height) {
    if (width <= 0) return;
    final saturation = (position.dx / width).clamp(0.0, 1.0);
    final value = (1 - position.dy / height).clamp(0.0, 1.0);
    _setHsv(HSVColor.fromAHSV(1, hsv.hue, saturation, value));
  }
}
