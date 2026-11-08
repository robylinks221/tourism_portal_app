import 'package:flutter/material.dart';
import '../models/accommodation_room_type.dart';
import '../services/accommodation_room_type_service.dart';

/// Lists accommodation room types and lets administrators create or edit them.
/// The editor is displayed inside this page instead of opening a dialog route.
class AccommodationRoomTypesPage extends StatefulWidget {
  const AccommodationRoomTypesPage({
    super.key,
    required this.accommodationId,
    required this.service,
    this.admin = false,
  });

  final int accommodationId;
  final AccommodationRoomTypeService service;
  final bool admin;

  @override
  State<AccommodationRoomTypesPage> createState() =>
      _AccommodationRoomTypesPageState();
}

class _AccommodationRoomTypesPageState extends State<AccommodationRoomTypesPage> {
  static const green = Color(0xFF165B5D);
  static const orange = Color(0xFFF46627);
  static const cream = Color(0xFFF4EEE1);

  late Future<List<AccommodationRoomType>> _future;
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _currency = TextEditingController(text: 'USD');
  final _occupancy = TextEditingController(text: '2');
  final _beds = TextEditingController();
  final _quantity = TextEditingController(text: '1');

  AccommodationRoomType? _editingRoom;
  bool _showEditor = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.service.list(widget.accommodationId);
  }

  void _openEditor([AccommodationRoomType? room]) {
    if (!widget.admin || _saving) return;
    _editingRoom = room;
    _name.text = room?.name ?? '';
    _description.text = room?.description ?? '';
    _price.text = room?.pricePerNight.toString() ?? '';
    _currency.text = room?.currency ?? 'USD';
    _occupancy.text = room?.maxOccupancy.toString() ?? '2';
    _beds.text = room?.bedType ?? '';
    _quantity.text = room?.quantity.toString() ?? '1';
    setState(() => _showEditor = true);
  }

  void _closeEditor() {
    if (_saving) return;
    setState(() {
      _showEditor = false;
      _editingRoom = null;
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final price = double.tryParse(_price.text.trim());
    final occupancy = int.tryParse(_occupancy.text.trim());
    final quantity = int.tryParse(_quantity.text.trim());
    if (price == null || price < 0 || occupancy == null || occupancy < 1 ||
        quantity == null || quantity < 0) {
      _message('Please enter valid price, occupancy and room quantity.');
      return;
    }

    final fields = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'price_per_night': price,
      'currency': _currency.text.trim().toUpperCase(),
      'max_occupancy': occupancy,
      'bed_type': _beds.text.trim(),
      'quantity': quantity,
    };

    setState(() => _saving = true);
    try {
      final room = _editingRoom;
      if (room == null) {
        await widget.service.create(widget.accommodationId, fields);
      } else {
        await widget.service.update(room.id, fields);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _showEditor = false;
        _editingRoom = null;
        _reload();
      });
      _message(room == null ? 'Room type added successfully.' : 'Room type updated successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('Unable to save room type: $error');
    }
  }

  Future<void> _toggle(AccommodationRoomType room) async {
    try {
      await widget.service.setActive(room.id, !room.isActive);
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (mounted) _message('Unable to update room status: $error');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    bool integer = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        maxLines: lines,
        keyboardType: number
            ? TextInputType.numberWithOptions(decimal: !integer)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final text = (value ?? '').trim();
          if (required && text.isEmpty) return 'Required';
          if (number && text.isNotEmpty) {
            if (integer && int.tryParse(text) == null) return 'Enter a whole number';
            if (!integer && double.tryParse(text) == null) return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _editor() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _editingRoom == null ? 'Add Room Type' : 'Edit Room Type',
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: green,
            ),
          ),
          const SizedBox(height: 16),
          _field(_name, 'Room name', required: true),
          _field(_description, 'Description', lines: 3),
          _field(_price, 'Price per night', required: true, number: true),
          _field(_currency, 'Currency (USD)', required: true),
          _field(_occupancy, 'Maximum occupancy',
              required: true, number: true, integer: true),
          _field(_beds, 'Bed type'),
          _field(_quantity, 'Number of rooms', number: true, integer: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _closeEditor,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: green),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save Room Type'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roomList() {
    return FutureBuilder<List<AccommodationRoomType>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final rooms = (snapshot.data ?? [])
            .where((room) => widget.admin || room.isActive)
            .toList();
        if (rooms.isEmpty) {
          return const Center(child: Text('No room types have been added yet.'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: green,
                              ),
                            ),
                          ),
                          if (widget.admin)
                            Chip(label: Text(room.isActive ? 'Active' : 'Inactive')),
                        ],
                      ),
                      if (room.description?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(room.description!),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        '${room.currency} ${room.pricePerNight.toStringAsFixed(2)} / night',
                        style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700, color: green,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Up to ${room.maxOccupancy} guests'
                        '${room.bedType?.isNotEmpty == true ? ' · ${room.bedType}' : ''}'
                        ' · ${room.quantity} rooms',
                      ),
                      if (widget.admin)
                        Wrap(
                          children: [
                            TextButton.icon(
                              onPressed: () => _openEditor(room),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                            TextButton.icon(
                              onPressed: () => _toggle(room),
                              icon: Icon(
                                room.isActive
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              label: Text(room.isActive ? 'Deactivate' : 'Activate'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        title: Text(_showEditor ? 'Room Type Details' : 'Room Types'),
        leading: _showEditor
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _saving ? null : _closeEditor,
              )
            : null,
      ),
      floatingActionButton: widget.admin && !_showEditor
          ? FloatingActionButton.extended(
              backgroundColor: orange,
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Add room'),
            )
          : null,
      body: _showEditor ? _editor() : _roomList(),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _description, _price, _currency, _occupancy, _beds, _quantity,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
