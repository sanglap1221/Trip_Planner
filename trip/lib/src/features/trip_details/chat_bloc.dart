import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/api_client.dart';

// Events
abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatLoadRequested extends ChatEvent {
  final int tripId;
  ChatLoadRequested(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class ChatMessageSent extends ChatEvent {
  final int tripId;
  final String content;
  ChatMessageSent(this.tripId, this.content);
  @override
  List<Object?> get props => [tripId, content];
}

class ChatMessageReceived extends ChatEvent {
  final Map<String, dynamic> message;
  ChatMessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}

// States
abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatLoading extends ChatState {}

class ChatEmpty extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Map<String, dynamic>> messages;
  final bool isSending;

  ChatLoaded(this.messages, {this.isSending = false});

  @override
  List<Object?> get props => [messages, isSending];
}

class ChatError extends ChatState {
  final String message;

  ChatError({this.message = 'Failed to load chat'});

  @override
  List<Object?> get props => [message];
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiClient _api;
  int? _lastId;
  int? _currentTripId;

  ChatBloc(this._api) : super(ChatLoading()) {
    on<ChatLoadRequested>(_onLoadRequested);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessageReceived>(_onMessageReceived);
  }

  Future<void> _onLoadRequested(
    ChatLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    _currentTripId = event.tripId;
    try {
      final res = await _api.get('messages/', query: {'trip': event.tripId});
      final messages = List<Map<String, dynamic>>.from(res.data as List);
      if (messages.isNotEmpty) {
        _lastId = messages.last['id'] as int;
      }

      if (messages.isEmpty) {
        emit(ChatEmpty());
      } else {
        emit(ChatLoaded(messages));
      }
    } catch (e) {
      emit(ChatError(message: _parseError(e)));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistically show the message
    final optimistic = {
      'id': (_lastId ?? 0) + 1,
      'content': event.content,
      'sender': {'username': 'You'},
      'created_at': DateTime.now().toIso8601String(),
    };

    if (state is ChatLoaded) {
      final current = (state as ChatLoaded).messages;
      final updated = [...current, optimistic];
      _lastId = optimistic['id'] as int;
      emit(ChatLoaded(updated, isSending: true));
    } else if (state is ChatEmpty) {
      emit(ChatLoaded([optimistic], isSending: true));
    }

    try {
      await _api.post(
        'messages/',
        data: {'trip': event.tripId, 'content': event.content},
      );
      // Reload to get server-generated IDs
      if (_currentTripId != null) {
        add(ChatLoadRequested(_currentTripId!));
      }
    } catch (e) {
      // On error, revert optimistic update
      emit(ChatError(message: _parseError(e)));
      if (_currentTripId != null) {
        add(ChatLoadRequested(_currentTripId!));
      }
    }
  }

  Future<void> _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final current = (state as ChatLoaded).messages;
      final updated = [...current, event.message];
      _lastId = event.message['id'] as int? ?? _lastId;
      emit(ChatLoaded(updated));
    }
  }

  String _parseError(Object? error) {
    if (error.toString().contains('401')) {
      return 'Session expired. Please log in again.';
    }
    return 'An error occurred. Please try again.';
  }
}
