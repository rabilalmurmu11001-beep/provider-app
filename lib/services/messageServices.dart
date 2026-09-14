import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_app/network.dart';

final messageServiceProvider = Provider<MessageServices>((ref) {
  final dio = ref.watch(dioProvider);
  return MessageServices(dio);
});

class MessageServices {
  final Dio _dio;

  MessageServices(this._dio);

  /// Fetch paginated message history for a specific room (booking ID)
  Future<Response> getRoomMessages(
    String roomId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      return await _dio.get(
        '/messages/room/$roomId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
    } catch (err) {
      rethrow;
    }
  }

  /// Send a message via REST endpoint (fallback or alternative to WebSocket)
  Future<Response> sendMessage({
    required String roomId,
    required String messageContent,
    String messageType = 'text',
  }) async {
    try {
      return await _dio.post(
        '/messages',
        data: {
          'roomId': roomId,
          'messageContent': messageContent,
          'messageType': messageType,
        },
      );
    } catch (err) {
      rethrow;
    }
  }

  /// Mark all messages in a room as read
  Future<Response> markRoomAsRead(String roomId) async {
    try {
      return await _dio.patch('/messages/room/$roomId/read');
    } catch (err) {
      rethrow;
    }
  }

  /// Fetch recent conversations list for the current user
  Future<Response> getConversations() async {
    try {
      return await _dio.get('/messages/conversations');
    } catch (err) {
      rethrow;
    }
  }

  /// Fetch total unread message count
  Future<Response> getUnreadCount() async {
    try {
      return await _dio.get('/messages/unread-count');
    } catch (err) {
      rethrow;
    }
  }

  /// Delete a message
  Future<Response> deleteMessage(String messageId) async {
    try {
      return await _dio.delete('/messages/$messageId');
    } catch (err) {
      rethrow;
    }
  }
}
