import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:trip/src/services/api_client.dart';
import 'package:trip/src/features/auth/auth_bloc.dart';
import 'package:trip/src/features/trip_details/itinerary_bloc.dart';
import 'package:trip/src/features/trip_details/polls_bloc.dart';
import 'package:trip/src/features/trip_details/chat_bloc.dart';
import 'package:trip/src/features/trip_details/widgets.dart';
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
          BlocProvider(
            create: (context) =>
                ItineraryBloc(context.read<ApiClient>())
                  ..add(ItineraryLoadRequested(widget.tripId)),
            child: ItineraryTab(tripId: widget.tripId),
          ),
          BlocProvider(
            create: (context) =>
                PollsBloc(context.read<ApiClient>())
                  ..add(PollsLoadRequested(widget.tripId)),
            child: PollsTab(tripId: widget.tripId),
          ),
          BlocProvider(
            create: (context) =>
                ChatBloc(context.read<ApiClient>())
                  ..add(ChatLoadRequested(widget.tripId)),
            child: ChatTab(tripId: widget.tripId),
          ),
        ],
      ),
    );
  }
}

class ItineraryTab extends StatelessWidget {
  final int tripId;
  const ItineraryTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItineraryBloc, ItineraryState>(
      listener: (context, state) {
        if (state is ItineraryError &&
            state.message.contains('Session expired')) {
          context.read<AuthBloc>().add(AuthTokenExpired());
        }
      },
      child: BlocBuilder<ItineraryBloc, ItineraryState>(
        builder: (context, state) {
          if (state is ItineraryLoading) {
            return const LoadingStateWidget(message: 'Loading itinerary...');
          }

          if (state is ItineraryEmpty) {
            return EmptyStateWidget(
              title: 'No itinerary yet',
              subtitle: 'Add your first destination to get started',
              icon: Icons.map_outlined,
              onAction: () {
                context.read<ItineraryBloc>().add(
                  ItineraryLoadRequested(tripId),
                );
              },
              actionLabel: 'Refresh',
            );
          }

          if (state is ItineraryError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () {
                context.read<ItineraryBloc>().add(
                  ItineraryLoadRequested(tripId),
                );
              },
            );
          }

          if (state is ItineraryLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ItineraryBloc>().add(
                  ItineraryLoadRequested(tripId),
                );
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ReorderableListView.builder(
                itemCount: state.items.length,
                onReorder: (oldIndex, newIndex) {
                  context.read<ItineraryBloc>().add(
                    ItineraryReorderRequested(tripId, oldIndex, newIndex),
                  );
                },
                itemBuilder: (context, index) {
                  final it = state.items[index];
                  return ListTile(
                    key: ValueKey(it['id']),
                    leading: Icon(Icons.drag_handle),
                    title: Text(it['title'] as String? ?? 'Untitled'),
                    subtitle: (it['description'] as String?)?.isEmpty ?? true
                        ? null
                        : Text(it['description'] as String),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class PollsTab extends StatelessWidget {
  final int tripId;
  const PollsTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PollsBloc, PollsState>(
      listener: (context, state) {
        if (state is PollsError && state.message.contains('Session expired')) {
          context.read<AuthBloc>().add(AuthTokenExpired());
        }
      },
      child: BlocBuilder<PollsBloc, PollsState>(
        builder: (context, state) {
          if (state is PollsLoading) {
            return const LoadingStateWidget(message: 'Loading polls...');
          }

          if (state is PollsEmpty) {
            return EmptyStateWidget(
              title: 'No polls yet',
              subtitle: 'Create a poll to let your group decide',
              icon: Icons.poll_outlined,
              onAction: () {
                context.read<PollsBloc>().add(PollsLoadRequested(tripId));
              },
              actionLabel: 'Refresh',
            );
          }

          if (state is PollsError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () {
                context.read<PollsBloc>().add(PollsLoadRequested(tripId));
              },
            );
          }

          if (state is PollsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<PollsBloc>().add(PollsLoadRequested(tripId));
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                itemCount: state.polls.length,
                itemBuilder: (context, i) {
                  final p = state.polls[i];
                  final options = List<Map<String, dynamic>>.from(
                    p['options'] as List,
                  );
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['question'] as String? ?? 'Untitled Poll',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          for (final o in options)
                            ListTile(
                              title: Text(o['text'] as String? ?? ''),
                              trailing: Text('${o['votes_count'] ?? 0}'),
                              onTap: () {
                                context.read<PollsBloc>().add(
                                  PollsVoteRequested(
                                    p['id'] as int,
                                    o['id'] as int,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
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
  WebSocketChannel? _channel;
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _connectWs();
  }

  void _connectWs() {
    try {
      // Get API client to retrieve the properly normalized base URL
      final apiClient = context.read<ApiClient>();
      final baseUrl = apiClient.baseUrl ?? 'http://10.0.2.2:8000/api/';
      final uri = Uri.parse(baseUrl);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final apiBasePath = uri.path;
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
            _chatBloc.add(ChatMessageReceived(msg));
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
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatError && state.message.contains('Session expired')) {
          context.read<AuthBloc>().add(AuthTokenExpired());
        }
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const LoadingStateWidget(message: 'Loading chat...');
          }

          if (state is ChatEmpty) {
            return Column(
              children: [
                Expanded(
                  child: EmptyStateWidget(
                    title: 'Start the conversation 👋',
                    subtitle: 'Be the first to message your travel group',
                    icon: Icons.chat_outlined,
                    onAction: () {
                      context.read<ChatBloc>().add(
                        ChatLoadRequested(widget.tripId),
                      );
                    },
                    actionLabel: 'Refresh',
                  ),
                ),
                _buildMessageInput(context),
              ],
            );
          }

          if (state is ChatError) {
            return Column(
              children: [
                Expanded(
                  child: ErrorStateWidget(
                    message: state.message,
                    onRetry: () {
                      context.read<ChatBloc>().add(
                        ChatLoadRequested(widget.tripId),
                      );
                    },
                  ),
                ),
                _buildMessageInput(context),
              ],
            );
          }

          if (state is ChatLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) {
                _scroll.jumpTo(_scroll.position.maxScrollExtent);
              }
            });

            return Column(
              children: [
                Expanded(
                  child: state.messages.isEmpty
                      ? EmptyStateWidget(
                          title: 'No messages yet',
                          subtitle: 'Send the first message',
                          icon: Icons.chat_outlined,
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<ChatBloc>().add(
                              ChatLoadRequested(widget.tripId),
                            );
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                          },
                          child: ListView.builder(
                            controller: _scroll,
                            itemCount: state.messages.length,
                            itemBuilder: (context, i) {
                              final m = state.messages[i];
                              final sender = m['sender'] as Map?;
                              final username =
                                  sender?['username'] as String? ?? 'Unknown';
                              return ListTile(
                                title: Text(m['content'] as String? ?? ''),
                                subtitle: Text(username),
                              );
                            },
                          ),
                        ),
                ),
                _buildMessageInput(context),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final isSending = state is ChatLoaded && state.isSending;
              return IconButton(
                onPressed: isSending
                    ? null
                    : () {
                        if (_controller.text.trim().isNotEmpty) {
                          context.read<ChatBloc>().add(
                            ChatMessageSent(
                              widget.tripId,
                              _controller.text.trim(),
                            ),
                          );
                          _controller.clear();
                        }
                      },
                icon: isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close(ws_status.goingAway);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }
}
