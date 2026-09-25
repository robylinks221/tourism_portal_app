import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import '../theme/field_guide_theme.dart';

class GuideTeamAssignmentsPage extends StatefulWidget {
  const GuideTeamAssignmentsPage({super.key});

  @override
  State<GuideTeamAssignmentsPage> createState() =>
      _GuideTeamAssignmentsPageState();
}

class _GuideTeamAssignmentsPageState extends State<GuideTeamAssignmentsPage> {
  bool _loading = true;
  bool _working = false;
  String? _error;
  String _filter = 'all';
  List<BookingGuideAssignmentItem> _assignments = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final assignments =
          await BookingService.instance.fetchGuideTeamAssignments();

      if (!mounted) {
        return;
      }

      setState(() {
        _assignments = assignments;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<BookingGuideAssignmentItem> get _filtered {
    if (_filter == 'all') {
      return _assignments;
    }

    return _assignments
        .where((assignment) => assignment.status == _filter)
        .toList();
  }

  int _count(String status) {
    return _assignments
        .where((assignment) => assignment.status == status)
        .length;
  }

  Future<void> _accept(BookingGuideAssignmentItem assignment) async {
    if (_working || !assignment.isPending) {
      return;
    }

    final confirmed = await _confirm(
      title: 'Accept Team Assignment?',
      message:
          'You will lead this safari on behalf of ${assignment.operator?.name ?? 'the tour operator'}. '
          'The booking remains owned and managed by the tour operator.',
      action: 'Accept Assignment',
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      await BookingService.instance.acceptGuideTeamAssignment(assignment.id);

      await _load();

      if (!mounted) {
        return;
      }

      _message('Team assignment accepted.');
    } catch (error) {
      if (mounted) {
        _message(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _decline(BookingGuideAssignmentItem assignment) async {
    if (_working || !assignment.isPending) {
      return;
    }

    final confirmed = await _confirm(
      title: 'Decline Team Assignment?',
      message:
          'The tour operator will be able to assign another guide to this safari.',
      action: 'Decline Assignment',
      destructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      await BookingService.instance.declineGuideTeamAssignment(assignment.id);

      await _load();

      if (!mounted) {
        return;
      }

      _message('Team assignment declined.');
    } catch (error) {
      if (mounted) {
        _message(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: FieldGuidePalette.background,
              title: Text(
                title,
                style: const TextStyle(
                  color: FieldGuidePalette.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                message,
                style: const TextStyle(
                  color: FieldGuidePalette.mutedText,
                  height: 1.45,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Not Now'),
                ),
                FilledButton(
                  style:
                      destructive
                          ? FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF9B4949),
                          )
                          : null,
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(action),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDetails(BookingGuideAssignmentItem assignment) async {
    BookingGuideAssignmentItem fullAssignment = assignment;

    try {
      fullAssignment = await BookingService.instance.fetchGuideTeamAssignment(
        assignment.id,
      );
    } catch (_) {
      // The list response already contains enough information to display.
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AssignmentDetailsSheet(
          assignment: fullAssignment,
          working: _working,
          onAccept:
              fullAssignment.isPending
                  ? () {
                    Navigator.pop(context);
                    _accept(fullAssignment);
                  }
                  : null,
          onDecline:
              fullAssignment.isPending
                  ? () {
                    Navigator.pop(context);
                    _decline(fullAssignment);
                  }
                  : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _count('pending');
    final accepted = _count('accepted');

    return Scaffold(
      backgroundColor: FieldGuidePalette.background,
      appBar: AppBar(
        backgroundColor: FieldGuidePalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Team Assignments',
          style: TextStyle(
            color: FieldGuidePalette.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: FieldGuidePalette.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
          children: [
            _HeroCard(pending: pending, accepted: accepted),
            const SizedBox(height: 18),
            _FilterBar(
              selected: _filter,
              onSelected: (value) {
                setState(() {
                  _filter = value;
                });
              },
              counts: {
                'all': _assignments.length,
                'pending': pending,
                'accepted': accepted,
              },
            ),
            const SizedBox(height: 18),
            if (_loading)
              const _LoadingState()
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else if (_filtered.isEmpty)
              _EmptyState(filter: _filter)
            else
              ..._filtered.map(
                (assignment) => Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: _AssignmentCard(
                    assignment: assignment,
                    working: _working,
                    onPressed: () => _openDetails(assignment),
                    onAccept:
                        assignment.isPending ? () => _accept(assignment) : null,
                    onDecline:
                        assignment.isPending
                            ? () => _decline(assignment)
                            : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.pending, required this.accepted});

  final int pending;
  final int accepted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FieldGuidePalette.primary, Color(0xFF0F4547)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_2_outlined, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Operator Team Work',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Safaris assigned to you by tour operators are kept separate '
            'from your own independent bookings.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _HeroMetric(label: 'Pending', value: '$pending')),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(label: 'Accepted', value: '$accepted'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelected,
    required this.counts,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('accepted', 'Accepted'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            filters.map((filter) {
              final active = selected == filter.$1;
              final count = counts[filter.$1] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: active,
                  onSelected: (_) => onSelected(filter.$1),
                  label: Text('${filter.$2}  $count'),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color:
                        active
                            ? FieldGuidePalette.primary
                            : FieldGuidePalette.mutedText,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.working,
    required this.onPressed,
    this.onAccept,
    this.onDecline,
  });

  final BookingGuideAssignmentItem assignment;
  final bool working;
  final VoidCallback onPressed;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final booking = assignment.booking;
    final operatorName =
        assignment.operator?.name.trim().isNotEmpty == true
            ? assignment.operator!.name
            : 'Tour Operator';

    final statusColor = _assignmentStatusColor(assignment.status);

    return Material(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: FieldGuidePalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OperatorAvatar(
                    photo: assignment.operator?.profilePhoto ?? '',
                    name: operatorName,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operatorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FieldGuidePalette.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tour Operator',
                          style: TextStyle(
                            color: FieldGuidePalette.mutedText,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(
                    text: _prettyStatus(assignment.status),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                booking?.title.isNotEmpty == true
                    ? booking!.title
                    : 'Safari Team Assignment',
                style: const TextStyle(
                  color: FieldGuidePalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 7,
                children: [
                  _MiniDetail(
                    icon: Icons.calendar_month_outlined,
                    text: _dateRange(booking?.startDate, booking?.endDate),
                  ),
                  _MiniDetail(
                    icon: Icons.groups_outlined,
                    text: '${booking?.travellers ?? 0} travellers',
                  ),
                  if (booking?.safariRequest?.days != null)
                    _MiniDetail(
                      icon: Icons.schedule_rounded,
                      text: '${booking!.safariRequest!.days} days',
                    ),
                ],
              ),
              if ((assignment.assignmentNotes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FieldGuidePalette.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    assignment.assignmentNotes!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FieldGuidePalette.mutedText,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (assignment.isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: working ? null : onDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF9B4949),
                          side: const BorderSide(color: Color(0xFF9B4949)),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: FilledButton(
                        onPressed: working ? null : onAccept,
                        child: const Text(
                          'Accept',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentDetailsSheet extends StatelessWidget {
  const _AssignmentDetailsSheet({
    required this.assignment,
    required this.working,
    this.onAccept,
    this.onDecline,
  });

  final BookingGuideAssignmentItem assignment;
  final bool working;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final booking = assignment.booking;
    final request = booking?.safariRequest;
    final destinations =
        request?.destinations ?? const <BookingReferenceItem>[];
    final activities = request?.activities ?? const <BookingReferenceItem>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.62,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: FieldGuidePalette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: FieldGuidePalette.mutedText.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking?.title.isNotEmpty == true
                                  ? booking!.title
                                  : 'Team Assignment',
                              style: const TextStyle(
                                color: FieldGuidePalette.ink,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _StatusPill(
                            text: _prettyStatus(assignment.status),
                            color: _assignmentStatusColor(assignment.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Assigned by ${assignment.operator?.name ?? 'Tour Operator'}',
                        style: const TextStyle(
                          color: FieldGuidePalette.mutedText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DetailSection(
                        title: 'Safari Details',
                        children: [
                          _DetailLine(
                            icon: Icons.confirmation_number_outlined,
                            label: 'Reference',
                            value: booking?.reference ?? '—',
                          ),
                          _DetailLine(
                            icon: Icons.calendar_month_outlined,
                            label: 'Dates',
                            value: _dateRange(
                              booking?.startDate,
                              booking?.endDate,
                            ),
                          ),
                          _DetailLine(
                            icon: Icons.groups_outlined,
                            label: 'Travellers',
                            value: '${booking?.travellers ?? 0}',
                          ),
                          if (request?.days != null)
                            _DetailLine(
                              icon: Icons.schedule_rounded,
                              label: 'Duration',
                              value: '${request!.days} days',
                            ),
                        ],
                      ),
                      if (destinations.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DetailSection(
                          title: 'Destinations',
                          children: [
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children:
                                  destinations
                                      .map((item) => _Tag(text: item.name))
                                      .toList(),
                            ),
                          ],
                        ),
                      ],
                      if (activities.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DetailSection(
                          title: 'Activities',
                          children: [
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children:
                                  activities
                                      .map((item) => _Tag(text: item.name))
                                      .toList(),
                            ),
                          ],
                        ),
                      ],
                      if ((assignment.assignmentNotes ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DetailSection(
                          title: 'Operator Instructions',
                          children: [
                            Text(
                              assignment.assignmentNotes!,
                              style: const TextStyle(
                                color: FieldGuidePalette.mutedText,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: FieldGuidePalette.primary.withValues(
                            alpha: 0.07,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: FieldGuidePalette.primary.withValues(
                              alpha: 0.16,
                            ),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: FieldGuidePalette.primary,
                              size: 20,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'This is operator team work. The tour operator '
                                'remains the booking owner and your independent '
                                'bookings stay separate.',
                                style: TextStyle(
                                  color: FieldGuidePalette.mutedText,
                                  fontSize: 11.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (assignment.isPending) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: working ? null : onDecline,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF9B4949),
                                  side: const BorderSide(
                                    color: Color(0xFF9B4949),
                                  ),
                                ),
                                child: const Text(
                                  'Decline',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: working ? null : onAccept,
                                child: const Text(
                                  'Accept Assignment',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FieldGuidePalette.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          ...children,
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: FieldGuidePalette.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: FieldGuidePalette.mutedText,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: FieldGuidePalette.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDetail extends StatelessWidget {
  const _MiniDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.circle, size: 0, color: Colors.transparent),
        Icon(icon, color: FieldGuidePalette.secondary, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: FieldGuidePalette.mutedText,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OperatorAvatar extends StatelessWidget {
  const _OperatorAvatar({required this.photo, required this.name});

  final String photo;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'T' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 22,
      backgroundColor: FieldGuidePalette.primary.withValues(alpha: 0.12),
      backgroundImage: photo.trim().isEmpty ? null : NetworkImage(photo),
      child:
          photo.trim().isEmpty
              ? Text(
                initial,
                style: const TextStyle(
                  color: FieldGuidePalette.primary,
                  fontWeight: FontWeight.w900,
                ),
              )
              : null,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: FieldGuidePalette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: FieldGuidePalette.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 70),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: FieldGuidePalette.secondary,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load team assignments',
            style: TextStyle(
              color: FieldGuidePalette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FieldGuidePalette.mutedText,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    final title =
        filter == 'all'
            ? 'No Team Assignments Yet'
            : 'No ${_prettyStatus(filter)} Assignments';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.groups_2_outlined,
            color: FieldGuidePalette.primary,
            size: 46,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FieldGuidePalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'When a tour operator assigns you to lead one of their safaris, '
            'it will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FieldGuidePalette.mutedText,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

Color _assignmentStatusColor(String status) {
  switch (status) {
    case 'accepted':
      return const Color(0xFF2E7D32);
    case 'declined':
      return const Color(0xFF9B4949);
    case 'cancelled':
      return FieldGuidePalette.mutedText;
    default:
      return FieldGuidePalette.secondary;
  }
}

String _prettyStatus(String status) {
  if (status.trim().isEmpty) {
    return '';
  }

  return status
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String _dateRange(String? start, String? end) {
  final startValue = start == null || start.trim().isEmpty ? 'Date TBC' : start;

  if (end == null || end.trim().isEmpty || end == start) {
    return startValue;
  }

  return '$startValue – $end';
}
