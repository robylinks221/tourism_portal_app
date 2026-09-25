import 'dart:async';

import 'package:flutter/material.dart';

import '../models/community.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Connect',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'People'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chats'),
            ],
          ),
        ),
        body: const TabBarView(children: [_PeopleTab(), _ConversationsTab()]),
      ),
    );
  }
}

class _PeopleTab extends StatefulWidget {
  const _PeopleTab();

  @override
  State<_PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<_PeopleTab> {
  late Future<List<CommunityMember>> _members;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _members = CommunityService.instance.fetchMembers();
  }

  void _reload() {
    setState(() => _members = CommunityService.instance.fetchMembers());
  }

  Future<void> _message(CommunityMember member) async {
    try {
      final conversation = await CommunityService.instance.startConversation(
        member.id,
      );
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(conversation: conversation)),
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  Future<void> _rate(CommunityMember member) async {
    final isProfessional =
        AuthService.instance.currentUser?.role == 'tour_operator';
    var stars = member.myRating?.stars ?? 5;
    final reviewController = TextEditingController(
      text: member.myRating?.review ?? '',
    );
    final shouldSave = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    isProfessional
                        ? 'Rate ${member.name} professionally'
                        : 'Rate ${member.name}',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final value = index + 1;
                            return IconButton(
                              tooltip: '$value star${value == 1 ? '' : 's'}',
                              onPressed:
                                  () => setDialogState(() => stars = value),
                              icon: Icon(
                                value <= stars
                                    ? Icons.star_rounded
                                    : Icons.star_border,
                                color: Colors.amber.shade700,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: reviewController,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            labelText:
                                isProfessional
                                    ? 'Professional feedback (optional)'
                                    : 'Review (optional)',
                            hintText:
                                isProfessional
                                    ? 'Share how the guide worked with your guests'
                                    : 'Share your experience',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Save rating'),
                    ),
                  ],
                ),
          ),
    );
    if (shouldSave != true) {
      reviewController.dispose();
      return;
    }
    try {
      await CommunityService.instance.submitRating(
        memberId: member.id,
        stars: stars,
        review: reviewController.text,
      );
      reviewController.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isProfessional
                ? 'Professional guide rating saved.'
                : 'Rating saved successfully.',
          ),
        ),
      );
      _reload();
    } on ApiException catch (error) {
      reviewController.dispose();
      if (mounted) _showError(error.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final viewerRole = AuthService.instance.currentUser?.role;
    final isTourist = viewerRole == 'tourist';
    final isOperator = viewerRole == 'tour_operator';
    return FutureBuilder<List<CommunityMember>>(
      future: _members,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'People could not be loaded.',
            onRetry: _reload,
          );
        }
        final members = snapshot.data ?? const [];
        final visible =
            _filter == 'all'
                ? members
                : members.where((member) => member.role == _filter).toList();
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _members;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Text(
                isTourist
                    ? 'Find guides and operators, start a chat, or leave a rating.'
                    : isOperator
                    ? 'Find guides, share professional feedback, or start a private chat.'
                    : 'Find people in the tourism community and start a private chat.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (!isTourist) ...[
                const SizedBox(height: 14),
                const _MyRatingsSummaryCard(),
              ],
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip('All', 'all', _filter, _setFilter),
                    _FilterChip(
                      'Tour guides',
                      'tourist_guide',
                      _filter,
                      _setFilter,
                    ),
                    _FilterChip(
                      'Tour operators',
                      'tour_operator',
                      _filter,
                      _setFilter,
                    ),
                    _FilterChip('Tourists', 'tourist', _filter, _setFilter),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No matching people yet.')),
                )
              else
                ...visible.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MemberCard(
                      member: member,
                      canRate:
                          (isTourist &&
                              (member.role == 'tourist_guide' ||
                                  member.role == 'tour_operator')) ||
                          (isOperator && member.role == 'tourist_guide'),
                      onMessage: () => _message(member),
                      onRate: () => _rate(member),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _setFilter(String value) => setState(() => _filter = value);
}

class _MyRatingsSummaryCard extends StatefulWidget {
  const _MyRatingsSummaryCard();

  @override
  State<_MyRatingsSummaryCard> createState() => _MyRatingsSummaryCardState();
}

class _MyRatingsSummaryCardState extends State<_MyRatingsSummaryCard> {
  late Future<RatingSummary> _summary =
      CommunityService.instance.fetchMyRatings();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RatingSummary>(
      future: _summary,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.star_outline_rounded),
              title: const Text('My ratings could not be loaded'),
              trailing: IconButton(
                onPressed:
                    () => setState(() {
                      _summary = CommunityService.instance.fetchMyRatings();
                    }),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          );
        }
        final summary = snapshot.data!;
        return Card(
          child: ListTile(
            onTap:
                () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReceivedRatingsPage(),
                  ),
                ),
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              child: Icon(
                summary.count == 0
                    ? Icons.star_outline_rounded
                    : Icons.star_rounded,
              ),
            ),
            title: const Text(
              'My ratings',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              summary.count == 0
                  ? 'No ratings yet'
                  : '${summary.average.toStringAsFixed(1)} from ${summary.count} rating${summary.count == 1 ? '' : 's'}',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }
}

class ReceivedRatingsPage extends StatefulWidget {
  const ReceivedRatingsPage({super.key});

  @override
  State<ReceivedRatingsPage> createState() => _ReceivedRatingsPageState();
}

class _ReceivedRatingsPageState extends State<ReceivedRatingsPage> {
  late Future<RatingSummary> _summary =
      CommunityService.instance.fetchMyRatings();

  void _reload() {
    setState(() => _summary = CommunityService.instance.fetchMyRatings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ratings & Reviews',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
        ),
      ),
      body: FutureBuilder<RatingSummary>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Your ratings could not be loaded.',
              onRetry: _reload,
            );
          }
          final summary = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _summary;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              children: [
                _RatingOverview(summary: summary),
                const SizedBox(height: 18),
                Text(
                  'Reviews',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 10),
                if (summary.ratings.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No one has rated you yet.')),
                    ),
                  )
                else
                  ...summary.ratings.map(
                    (rating) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    rating.reviewerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                ...List.generate(
                                  5,
                                  (index) => Icon(
                                    index < rating.stars
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 18,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                            if (rating.review.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(rating.review),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              rating.reviewerTypeLabel,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RatingOverview extends StatelessWidget {
  const _RatingOverview({required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _RatingSourceSummary(
                    label: 'Travellers',
                    average: summary.travellerAverage,
                    count: summary.travellerCount,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RatingSourceSummary(
                    label: 'Tour operators',
                    average: summary.operatorAverage,
                    count: summary.operatorCount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'All Ratings',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                final count = summary.breakdown[stars] ?? 0;
                final value = summary.count == 0 ? 0.0 : count / summary.count;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('$stars'),
                      const SizedBox(width: 6),
                      Expanded(child: LinearProgressIndicator(value: value)),
                      const SizedBox(width: 8),
                      SizedBox(width: 24, child: Text('$count')),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSourceSummary extends StatelessWidget {
  const _RatingSourceSummary({
    required this.label,
    required this.average,
    required this.count,
  });

  final String label;
  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                count == 0 ? '—' : average.toStringAsFixed(1),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 3),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 21),
              ],
            ],
          ),
          Text('$count rating${count == 1 ? '' : 's'}'),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, this.value, this.selected, this.onSelected);

  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected == value,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.canRate,
    required this.onMessage,
    required this.onRate,
  });

  final CommunityMember member;
  final bool canRate;
  final VoidCallback onMessage;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProfessionalRating =
        AuthService.instance.currentUser?.role == 'tour_operator';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProfileAvatar(
                  name: member.name,
                  imageUrl: member.profilePhotoUrl,
                  radius: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(member.roleLabel),
                      if (member.location.isNotEmpty)
                        Text(member.location, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (member.role != 'tourist')
                  Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber),
                          Text(
                            member.ratingCount == 0
                                ? 'New'
                                : member.ratingAverage.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Text(
                        '${member.ratingCount} rating${member.ratingCount == 1 ? '' : 's'}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
            if (member.biography.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                member.biography,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Message'),
                  ),
                ),
                if (canRate) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRate,
                      icon: const Icon(Icons.star_outline_rounded),
                      label: Text(
                        member.myRating == null
                            ? isProfessionalRating
                                ? 'Rate guide'
                                : 'Rate'
                            : isProfessionalRating
                            ? 'Edit guide rating'
                            : 'Edit rating',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationsTab extends StatefulWidget {
  const _ConversationsTab();

  @override
  State<_ConversationsTab> createState() => _ConversationsTabState();
}

class _ConversationsTabState extends State<_ConversationsTab> {
  late Future<List<ChatConversation>> _conversations;

  @override
  void initState() {
    super.initState();
    _conversations = CommunityService.instance.fetchConversations();
  }

  void _reload() {
    _conversations = CommunityService.instance.fetchConversations();
    if (mounted) setState(() {});
  }

  Future<void> _open(ChatConversation conversation) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(conversation: conversation)),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChatConversation>>(
      future: _conversations,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Conversations could not be loaded.',
            onRetry: _reload,
          );
        }
        final conversations = snapshot.data ?? const [];
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _conversations;
          },
          child:
              conversations.isEmpty
                  ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.forum_outlined, size: 64),
                      SizedBox(height: 14),
                      Center(child: Text('No conversations yet.')),
                      SizedBox(height: 6),
                      Center(child: Text('Open People to start a chat.')),
                    ],
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return ListTile(
                        onTap: () => _open(conversation),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        leading: _ProfileAvatar(
                          name: conversation.participant.name,
                          imageUrl: conversation.participant.profilePhotoUrl,
                          radius: 26,
                        ),
                        title: Text(
                          conversation.participant.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          conversation.latestMessage.isEmpty
                              ? conversation.participant.roleLabel
                              : conversation.latestMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing:
                            conversation.unreadCount > 0
                                ? Badge(
                                  label: Text('${conversation.unreadCount}'),
                                  child: const Icon(Icons.chat_bubble_rounded),
                                )
                                : const Icon(Icons.chevron_right_rounded),
                      );
                    },
                  ),
        );
      },
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = const [];
  Timer? _poller;
  bool _loading = true;
  bool _sending = false;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(showLoading: true);
    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(showLoading: false),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool showLoading}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final thread = await CommunityService.instance.fetchMessages(
        widget.conversation.id,
      );
      if (!mounted) return;
      final changed =
          _messages.length != thread.messages.length ||
          (_messages.isNotEmpty &&
              thread.messages.isNotEmpty &&
              _messages.last.id != thread.messages.last.id);
      setState(() {
        _messages = thread.messages;
        _loading = false;
        _error = null;
      });
      if (changed || showLoading) _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await CommunityService.instance.sendMessage(
        conversationId: widget.conversation.id,
        body: text,
      );
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _messages = [
          ..._messages.where((existing) => existing.id != message.id),
          message,
        ];
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final participant = widget.conversation.participant;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _ProfileAvatar(
              name: participant.name,
              imageUrl: participant.profilePhotoUrl,
              radius: 20,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  participant.roleLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null && _messages.isEmpty
                    ? _ErrorState(
                      message: _error!,
                      onRetry: () => _load(showLoading: true),
                    )
                    : _MessageList(
                      messages: _messages,
                      controller: _scrollController,
                    ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Write a message...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon:
                        _sending
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.controller});

  final List<ChatMessage> messages;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Text('Start the conversation.'));
    }
    final myId = AuthService.instance.currentUser?.id;
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final mine = message.senderId == myId;
        final colors = Theme.of(context).colorScheme;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 310),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
            decoration: BoxDecoration(
              color: mine ? colors.primary : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomRight: mine ? const Radius.circular(4) : null,
                bottomLeft: mine ? null : const Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.body,
                  style: TextStyle(
                    color: mine ? colors.onPrimary : colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _time(message.createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: (mine ? colors.onPrimary : colors.onSurface)
                        .withOpacity(.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _time(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.imageUrl,
    required this.radius,
  });

  final String name;
  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      child: Text(
        name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
    if (imageUrl.isEmpty) return fallback;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
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
            const Icon(Icons.cloud_off_rounded, size: 48),
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
