import 'package:flutter/material.dart';

import '../models/operator_management.dart';
import '../services/booking_service.dart';
import '../services/tour_booking_service.dart';

class TourBookingPage extends StatefulWidget {
  const TourBookingPage({super.key, required this.tour});

  final OperatorTour tour;

  @override
  State<TourBookingPage> createState() => _TourBookingPageState();
}

class _TourBookingPageState extends State<TourBookingPage> {
  final TextEditingController _notes = TextEditingController();

  DateTime? _startDate;
  int _travellers = 1;
  String _accommodationType = 'mid_range';
  bool _submitting = false;

  double get _total => widget.tour.price * _travellers;

  DateTime? get _endDate {
    final start = _startDate;

    if (start == null) {
      return null;
    }

    final days = widget.tour.days < 1 ? 1 : widget.tour.days;

    return start.add(Duration(days: days - 1));
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();

    final initial =
        _startDate ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3, 12, 31),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = picked;
    });
  }

  Future<void> _submit() async {
    final startDate = _startDate;

    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your safari departure date.'),
        ),
      );

      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final booking = await TourBookingService.instance.bookTour(
        tour: widget.tour,
        startDate: startDate,
        travellers: _travellers,
        accommodationType: _accommodationType,
        touristNotes: _notes.text,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder:
              (_) => _BookingSuccessPage(booking: booking, tour: widget.tour),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Safari',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 82,
                      height: 82,
                      child:
                          widget.tour.imageUrl.isEmpty
                              ? Container(
                                color: colors.primaryContainer,
                                child: const Icon(Icons.landscape_rounded),
                              )
                              : Image.network(
                                widget.tour.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      color: colors.primaryContainer,
                                      child: const Icon(
                                        Icons.landscape_rounded,
                                      ),
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
                          widget.tour.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.tour.operatorName.isEmpty
                              ? widget.tour.isGuideLed
                                  ? 'Tourist Guide'
                                  : 'Tour Operator'
                              : widget.tour.operatorName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.tour.days} '
                          '${widget.tour.days == 1 ? 'day' : 'days'}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Travel dates',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _submitting ? null : _chooseDate,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _startDate == null
                            ? 'Choose departure date'
                            : '${_prettyDate(_startDate!)}'
                                '${_endDate == null ? '' : ' – ${_prettyDate(_endDate!)}'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color:
                              _startDate == null
                                  ? colors.onSurfaceVariant
                                  : colors.onSurface,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Travellers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Number of travellers',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _submitting || _travellers <= 1
                            ? null
                            : () {
                              setState(() {
                                _travellers--;
                              });
                            },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 35,
                    child: Text(
                      '$_travellers',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _submitting || _travellers >= 100
                            ? null
                            : () {
                              setState(() {
                                _travellers++;
                              });
                            },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Accommodation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose the accommodation level you prefer for this safari.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _AccommodationOption(
              title: 'Budget Accommodation',
              subtitle:
                  'Simple, clean and comfortable stays with essential facilities.',
              icon: Icons.bed_outlined,
              value: 'budget',
              groupValue: _accommodationType,
              onChanged:
                  _submitting
                      ? null
                      : (value) {
                        setState(() {
                          _accommodationType = value;
                        });
                      },
            ),
            const SizedBox(height: 10),
            _AccommodationOption(
              title: 'Mid-range Accommodation',
              subtitle:
                  'Comfortable lodges and hotels with a higher level of service.',
              icon: Icons.hotel_outlined,
              value: 'mid_range',
              groupValue: _accommodationType,
              onChanged:
                  _submitting
                      ? null
                      : (value) {
                        setState(() {
                          _accommodationType = value;
                        });
                      },
            ),
            const SizedBox(height: 10),
            _AccommodationOption(
              title: 'Luxury Accommodation',
              subtitle:
                  'Premium safari lodges, camps and high-end hospitality.',
              icon: Icons.villa_outlined,
              value: 'luxury',
              groupValue: _accommodationType,
              onChanged:
                  _submitting
                      ? null
                      : (value) {
                        setState(() {
                          _accommodationType = value;
                        });
                      },
            ),
            const SizedBox(height: 24),
            Text(
              'Special requests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              minLines: 4,
              maxLines: 7,
              enabled: !_submitting,
              decoration: const InputDecoration(
                hintText:
                    'Dietary needs, airport pickup, room preferences or anything the provider should know.',
              ),
            ),
            const SizedBox(height: 24),
            _PriceSummary(
              currency: widget.tour.currency,
              pricePerTraveller: widget.tour.price,
              travellers: _travellers,
              total: _total,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child:
                _submitting
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Confirm Booking',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
          ),
        ),
      ),
    );
  }
}

class _AccommodationOption extends StatelessWidget {
  const _AccommodationOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = value == groupValue;

    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.07) : colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(value),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              const SizedBox(width: 8),
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged:
                    onChanged == null
                        ? null
                        : (selectedValue) {
                          if (selectedValue != null) {
                            onChanged!(selectedValue);
                          }
                        },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.currency,
    required this.pricePerTraveller,
    required this.travellers,
    required this.total,
  });

  final String currency;
  final double pricePerTraveller;
  final int travellers;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          _PriceRow(
            label: 'Price per traveller',
            value: '$currency ${_money(pricePerTraveller)}',
          ),
          const SizedBox(height: 10),
          _PriceRow(label: 'Travellers', value: '$travellers'),
          const Divider(height: 26),
          _PriceRow(
            label: 'Estimated total',
            value: '$currency ${_money(total)}',
            strong: true,
          ),
          const SizedBox(height: 8),
          Text(
            'The provider will review and confirm your booking request.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: strong ? 17 : 14,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BookingSuccessPage extends StatelessWidget {
  const _BookingSuccessPage({required this.booking, required this.tour});

  final BookingItem booking;
  final OperatorTour tour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Booking Sent',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 42,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Booking Request Sent',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your safari provider will review the request and confirm the booking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SuccessLine(label: 'Reference', value: booking.reference),
                  _SuccessLine(
                    label: 'Departure',
                    value: booking.startDate ?? '—',
                  ),
                  _SuccessLine(
                    label: 'Travellers',
                    value: '${booking.travellers}',
                  ),
                  _SuccessLine(
                    label: 'Total',
                    value: '${booking.currency} ${_money(booking.totalAmount)}',
                  ),
                  _SuccessLine(label: 'Status', value: _pretty(booking.status)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessLine extends StatelessWidget {
  const _SuccessLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

String _money(double value) {
  return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
}

String _prettyDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${value.day} '
      '${months[value.month - 1]} '
      '${value.year}';
}

String _pretty(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
