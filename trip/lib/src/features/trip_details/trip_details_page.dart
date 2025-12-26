import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:trip/src/services/api_client.dart';
import 'dart:convert';

class TripDetailsPage extends StatefulWidget {
  final int tripId;
  final String tripName;
  const TripDetailsPage({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripName),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Itinerary'),
            Tab(text: 'Polls'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          ItineraryTab(tripId: widget.tripId),
          PollsTab(tripId: widget.tripId),
          ChatTab(tripId: widget.tripId),
        ],
      ),
    );
  }
}

class ItineraryTab extends StatefulWidget {
  final int tripId;
  const ItineraryTab({super.key, required this.tripId});

  @override
  State<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ApiClient();
    final res = await api.get(
      'itinerary-items/',
      query: {'trip': widget.tripId},
    );
    setState(() {
      _items = List<Map<String, dynamic>>.from(res.data as List);
      _items.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      _loading = false;
    });
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final list = List<Map<String, dynamic>>.from(_items);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setState(() => _items = list);
    final orderIds = list.map((e) => e['id']).toList();
    final api = ApiClient();
    await api.post(
      'trips/${widget.tripId}/reorder-itinerary/',
      data: {'order': orderIds},
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ReorderableListView.builder(
      itemCount: _items.length,
      onReorder: _reorder,
      itemBuilder: (context, index) {
        final it = _items[index];
        return ListTile(
          key: ValueKey(it['id']),
          title: Text(it['title'] as String? ?? 'Item'),
          subtitle: (it['description'] as String?)?.isEmpty ?? true
              ? null
              : Text(it['description'] as String),
        );
      },
    );
  }
}

class PollsTab extends StatefulWidget {
  final int tripId;
  const PollsTab({super.key, required this.tripId});

  @override
  State<PollsTab> createState() => _PollsTabState();
}

class _PollsTabState extends State<PollsTab> {
  List<Map<String, dynamic>> _polls = [];
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ApiClient();
    final res = await api.get('polls/', query: {'trip': widget.tripId});
    setState(() {
      _polls = List<Map<String, dynamic>>.from(res.data as List);
      _loading = false;
    });
  }

  Future<void> _vote(int pollId, int optionId) async {
    final api = ApiClient();
    await api.post('polls/$pollId/vote/', data: {'option_id': optionId});
    _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _polls.length,
        itemBuilder: (context, i) {
          final p = _polls[i];
          final options = List<Map<String, dynamic>>.from(p['options'] as List);
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['question'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final o in options)
                    ListTile(
                      title: Text(o['text'] as String),
                      trailing: Text('${o['votes_count'] ?? 0}'),
                      onTap: () => _vote(p['id'] as int, o['id'] as int),
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

class ChatTab extends StatefulWidget {
  final int tripId;
  const ChatTab({super.key, required this.tripId});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  int? _lastId;
  bool _loading = true;
  bool _sending = false;
  WebSocketChannel? _channel;

  Future<void> _load({bool incremental = false}) async {
    final api = ApiClient();
    final query = {
      'trip': widget.tripId,
      if (incremental && _lastId != null) 'after_id': _lastId,
    };
    final res = await api.get('messages/', query: query);
    final list = List<Map<String, dynamic>>.from(res.data as List);
    setState(() {
      if (incremental) {
        _messages.addAll(list);
      } else {
        _messages = list;
      }
      if (_messages.isNotEmpty) _lastId = _messages.last['id'] as int;
      _loading = false;
    });
    await Future.delayed(const Duration(milliseconds: 50));
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  Future<void> _send() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final content = _controller.text.trim();
    _controller.clear();
    final optimistic = {
      'id': (_lastId ?? 0) + 1,
      'content': content,
      'sender': {'username': 'me'},
      'created_at': DateTime.now().toIso8601String(),
    };
    setState(() {
      _messages.add(optimistic);
      _lastId = optimistic['id'] as int;
    });
    final api = ApiClient();
    try {
      await api.post(
        'messages/',
        data: {'trip': widget.tripId, 'content': content},
      );
      await _load(incremental: true);
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    _connectWs();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              return ListTile(title: Text(m['content'] as String));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Message...'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _connectWs() {
    try {
      final base = const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000/api/',
      );
      // convert http://host:8000/api/ -> ws://host:8000/ws/trips/{id}/
      final uri = Uri.parse(base);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final apiBasePath = uri.path; // e.g., /api/
      final rootPath = apiBasePath.endsWith('/')
          ? apiBasePath.substring(0, apiBasePath.length - 1)
          : apiBasePath;
      final pathUp = rootPath.endsWith('/api')
          ? rootPath.substring(0, rootPath.length - 4)
          : '/';
      final wsUri = Uri(
        scheme: scheme,
        host: uri.host,
        port: uri.port,
        path: '${pathUp}ws/trips/${widget.tripId}/',
      );
      _channel = WebSocketChannel.connect(wsUri);
      _channel!.stream.listen((event) {
        try {
          final data = event is String ? event : String.fromCharCodes(event);
          final decoded = _tryDecodeJson(data);
          if (decoded is Map && decoded['type'] == 'chat') {
            final msg = Map<String, dynamic>.from(decoded['message'] as Map);
            setState(() {
              _messages.add(msg);
              _lastId = msg['id'] as int? ?? _lastId;
            });
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  dynamic _tryDecodeJson(String s) {
    try {
      return s.isEmpty
          ? null
          : (s[0] == '{' || s[0] == '[')
          ? jsonDecode(s)
          : null;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _channel?.sink.close(ws_status.goingAway);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }
}
