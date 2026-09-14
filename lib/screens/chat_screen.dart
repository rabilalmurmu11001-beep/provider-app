import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../secureStorage.dart';
import '../services/authServices.dart';
import '../services/messageServices.dart';
import '../services/socketService.dart';
import '../stores/providers.dart';
import '../theme.dart';

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String messageContent;
  final String messageType;
  final String messageStatus; // 'sending', 'sent', 'delivered', 'read', 'failed'
  final DateTime createdAt;
  final String? senderName;
  final String? senderPhoto;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.messageContent,
    this.messageType = 'text',
    this.messageStatus = 'sent',
    required this.createdAt,
    this.senderName,
    this.senderPhoto,
  });

  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? messageContent,
    String? messageType,
    String? messageStatus,
    DateTime? createdAt,
    String? senderName,
    String? senderPhoto,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      messageContent: messageContent ?? this.messageContent,
      messageType: messageType ?? this.messageType,
      messageStatus: messageStatus ?? this.messageStatus,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['createdAt'] != null) {
      parsedDate =
          DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final sender = json['sender'] is Map<String, dynamic>
        ? json['sender'] as Map<String, dynamic>
        : null;

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      messageContent: json['messageContent']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'text',
      messageStatus: json['messageStatus']?.toString() ?? 'sent',
      createdAt: parsedDate,
      senderName:
          sender?['username']?.toString() ?? sender?['name']?.toString(),
      senderPhoto: sender?['photo']?.toString(),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String? recipientName;
  final String? recipientPhoto;
  final String? recipientId;

  const ChatScreen({
    super.key,
    this.roomId = '',
    this.recipientName,
    this.recipientPhoto,
    this.recipientId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;

  // Track the currently active room ID (in case user selected from conversations list)
  late String _activeRoomId;
  String? _activeRecipientName;
  String? _activeRecipientPhoto;

  // Conversations list (used when roomId is empty)
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoadingConversations = false;

  void Function(dynamic data)? _onMessageReceived;
  void Function(dynamic data)? _onMessagesRead;

  final List<Map<String, String>> _macros = [
    {
      'label': '📍 On my way',
      'text': 'I am currently in transit to your location.',
    },
    {
      'label': '🚗 Arrived',
      'text': 'I have arrived at your location coordinates.',
    },
    {
      'label': '🛠️ Starting Work',
      'text': 'I am beginning the requested service now.',
    },
    {
      'label': '✓ Job Complete',
      'text': 'The requested service has been successfully completed.',
    },
    {
      'label': '📞 Please call me',
      'text': 'Please give me a quick call when you are free.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeRoomId = widget.roomId;
    _activeRecipientName = widget.recipientName;
    _activeRecipientPhoto = widget.recipientPhoto;

    _initChat();
  }

  Future<void> _initChat() async {
    await _resolveCurrentUserId();

    if (_activeRoomId.isNotEmpty) {
      await _loadMessages();
      _setupSocket();
    } else {
      await _loadConversations();
    }
  }

  Future<void> _resolveCurrentUserId() async {
    // 1. Try from cached provider profile
    final profile = ref.read(providerProfileProvider);
    if (profile != null && profile['id'] != null) {
      _currentUserId = profile['id'].toString();
      return;
    }

    // 2. Try decoding JWT token from secure storage
    final token = await TokenRepository().readToken();
    if (token != null && token.isNotEmpty) {
      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          final normalized = base64Url.normalize(parts[1]);
          final payloadStr = utf8.decode(base64Url.decode(normalized));
          final payload = json.decode(payloadStr) as Map<String, dynamic>?;
          if (payload != null && payload['id'] != null) {
            _currentUserId = payload['id'].toString();
            return;
          }
        }
      } catch (_) {}
    }

    // 3. Fallback: Fetch from API
    try {
      final res = await ref.read(authServiceProvider).getUserProfile();
      if (res.data is Map<String, dynamic> && res.data['user'] != null) {
        final user = res.data['user'] as Map<String, dynamic>;
        _currentUserId = user['id']?.toString();
        ref.read(providerProfileProvider.notifier).state = user;
      }
    } catch (_) {}
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoadingConversations = true);
    try {
      final res = await ref.read(messageServiceProvider).getConversations();
      if (res.data is Map<String, dynamic>) {
        final list = (res.data['conversations'] as List? ?? [])
            .map((c) => c as Map<String, dynamic>)
            .toList();
        if (mounted) {
          setState(() {
            _conversations = list;
            _isLoadingConversations = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingConversations = false);
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error loading conversations: $e');
      if (mounted) setState(() => _isLoadingConversations = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_activeRoomId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ref.read(messageServiceProvider).getRoomMessages(
            _activeRoomId,
            limit: 100,
          );

      if (res.data is Map<String, dynamic>) {
        final rawList = res.data['messages'] as List? ?? [];
        final parsed = rawList
            .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _messages = parsed;
            _isLoading = false;
          });
          _scrollToBottom();
        }

        // Mark existing messages as read
        await ref.read(messageServiceProvider).markRoomAsRead(_activeRoomId);
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error loading messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupSocket() {
    final socketService = ref.read(socketServiceProvider);

    if (!socketService.isConnected) {
      socketService.connect().then((_) {
        if (mounted && _activeRoomId.isNotEmpty) {
          socketService.joinRoom(_activeRoomId);
        }
      });
    } else if (_activeRoomId.isNotEmpty) {
      socketService.joinRoom(_activeRoomId);
    }

    // Real-time message listener
    _onMessageReceived = (data) {
      if (!mounted) return;

      if (data is Map<String, dynamic>) {
        final incoming = ChatMessage.fromJson(data);

        // Filter messages for other rooms
        if (incoming.roomId.isNotEmpty && incoming.roomId != _activeRoomId) {
          return;
        }

        setState(() {
          // Check if replacing an optimistic message
          final existingIdx = _messages.indexWhere(
            (m) =>
                m.id == incoming.id ||
                (m.messageStatus == 'sending' &&
                    m.senderId == incoming.senderId &&
                    m.messageContent == incoming.messageContent),
          );

          if (existingIdx >= 0) {
            _messages[existingIdx] = incoming;
          } else {
            _messages.add(incoming);
          }
        });

        _scrollToBottom();

        // Mark incoming messages as read if sent by customer
        if (incoming.senderId != _currentUserId && _activeRoomId.isNotEmpty) {
          ref.read(messageServiceProvider).markRoomAsRead(_activeRoomId);
        }
      }
    };

    socketService.onMessage(_onMessageReceived!);

    // Real-time read receipts listener
    _onMessagesRead = (data) {
      if (!mounted) return;
      if (data is Map<String, dynamic> && data['roomId'] == _activeRoomId) {
        setState(() {
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].senderId == _currentUserId) {
              _messages[i] = _messages[i].copyWith(messageStatus: 'read');
            }
          }
        });
      }
    };

    socketService.onMessagesRead(_onMessagesRead!);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty || _activeRoomId.isEmpty) return;

    if (customText == null) {
      _messageController.clear();
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = ChatMessage(
      id: tempId,
      roomId: _activeRoomId,
      senderId: _currentUserId ?? '',
      messageContent: text,
      messageType: 'text',
      messageStatus: 'sending',
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(optimisticMessage);
    });
    _scrollToBottom();

    final socketService = ref.read(socketServiceProvider);

    if (socketService.isConnected) {
      socketService.sendMessageToRoom(
        roomId: _activeRoomId,
        message: text,
        messageType: 'text',
      );
    } else {
      // Fallback to REST endpoint
      try {
        final res = await ref.read(messageServiceProvider).sendMessage(
              roomId: _activeRoomId,
              messageContent: text,
            );
        if (res.data is Map<String, dynamic> && res.data['message'] != null) {
          final serverMsg = ChatMessage.fromJson(
            res.data['message'] as Map<String, dynamic>,
          );
          if (mounted) {
            setState(() {
              final idx = _messages.indexWhere((m) => m.id == tempId);
              if (idx >= 0) {
                _messages[idx] = serverMsg;
              }
            });
          }
        }
      } catch (e) {
        debugPrint('[ChatScreen] REST send error: $e');
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == tempId);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(messageStatus: 'failed');
            }
          });
        }
      }
    }
  }

  void _selectConversation(Map<String, dynamic> conv) {
    final roomId = conv['roomId']?.toString() ?? '';
    final lastMsg = conv['lastMessage'] as Map<String, dynamic>?;
    final sender = lastMsg?['sender'] as Map<String, dynamic>?;
    final name = sender?['username']?.toString() ?? 'Customer';
    final photo = sender?['photo']?.toString();

    setState(() {
      _activeRoomId = roomId;
      _activeRecipientName = name;
      _activeRecipientPhoto = photo;
    });

    _loadMessages();
    _setupSocket();
  }

  @override
  void dispose() {
    final socketService = ref.read(socketServiceProvider);
    if (_onMessageReceived != null) {
      socketService.offMessage(_onMessageReceived);
    }
    if (_onMessagesRead != null) {
      socketService.offMessagesRead(_onMessagesRead);
    }
    if (_activeRoomId.isNotEmpty) {
      socketService.leaveRoom(_activeRoomId);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'CL';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return const Icon(
          Icons.access_time_rounded,
          size: 11,
          color: Colors.white60,
        );
      case 'sent':
        return const Icon(
          Icons.check_rounded,
          size: 13,
          color: Colors.white70,
        );
      case 'delivered':
        return const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Colors.white70,
        );
      case 'read':
        return const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Colors.lightBlueAccent,
        );
      case 'failed':
        return const Icon(
          Icons.error_outline_rounded,
          size: 12,
          color: Colors.redAccent,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // If no room is selected, show conversations list
    if (_activeRoomId.isEmpty) {
      return _buildConversationsListScreen(theme, isDark);
    }

    return _buildChatRoomScreen(theme, isDark);
  }

  Widget _buildConversationsListScreen(ThemeData theme, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Client Messages',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadConversations,
            tooltip: 'Refresh conversations',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerColor),
        ),
      ),
      body: _isLoadingConversations
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            )
          : _conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Active Chat Threads',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'When clients message you regarding a booking, your chat threads will appear here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/bookings'),
                          icon: const Icon(Icons.calendar_today_rounded, size: 14),
                          label: const Text('View Bookings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: theme.dividerColor),
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      final lastMsg =
                          conv['lastMessage'] as Map<String, dynamic>?;
                      final sender =
                          lastMsg?['sender'] as Map<String, dynamic>?;
                      final clientName =
                          sender?['username']?.toString() ?? 'Client';
                      final text =
                          lastMsg?['messageContent']?.toString() ?? '';
                      final unreadCount =
                          (conv['unreadCount'] as num?)?.toInt() ?? 0;
                      final timeStr = lastMsg?['createdAt'] != null
                          ? _formatTime(
                              DateTime.tryParse(
                                    lastMsg!['createdAt'].toString(),
                                  ) ??
                                  DateTime.now(),
                            )
                          : '';

                      return ListTile(
                        onTap: () => _selectConversation(conv),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            _getInitials(clientName),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                clientName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: unreadCount > 0
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : theme.textTheme.bodyMedium?.color,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildChatRoomScreen(ThemeData theme, bool isDark) {
    final clientName = _activeRecipientName ?? 'Client';
    final socketService = ref.watch(socketServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Chat Room Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // If opened with initial roomId, pop back to caller screen
                      if (widget.roomId.isNotEmpty) {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/bookings');
                        }
                      } else {
                        // Switch back to conversation list
                        setState(() {
                          _activeRoomId = '';
                        });
                        _loadConversations();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: _activeRecipientPhoto != null &&
                            _activeRecipientPhoto!.isNotEmpty
                        ? NetworkImage(_activeRecipientPhoto!)
                        : null,
                    child: _activeRecipientPhoto == null ||
                            _activeRecipientPhoto!.isEmpty
                        ? Text(
                            _getInitials(clientName),
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ValueListenableBuilder<bool>(
                          valueListenable: socketService.connectionNotifier,
                          builder: (context, isConnected, _) {
                            final connected =
                                isConnected || socketService.isConnected;
                            return Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: connected
                                        ? AppColors.success
                                        : AppColors.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  connected ? 'Connected' : 'Connecting...',
                                  style: TextStyle(
                                    color: connected
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Room badge
                  if (_activeRoomId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Text(
                        '#${_activeRoomId.substring(0, _activeRoomId.length > 8 ? 8 : _activeRoomId.length)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.textTheme.bodyMedium?.color,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Message Stream
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Coordinate directly with your customer regarding appointment and service specs.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isProvider = _currentUserId != null &&
                                msg.senderId == _currentUserId;

                            return Align(
                              alignment: isProvider
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isProvider
                                      ? AppColors.primary
                                      : (isDark
                                          ? const Color(0xFF1E293B)
                                          : theme.cardColor),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft:
                                        Radius.circular(isProvider ? 16 : 4),
                                    bottomRight:
                                        Radius.circular(isProvider ? 4 : 16),
                                  ),
                                  border: isProvider
                                      ? null
                                      : Border.all(color: theme.dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isProvider
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.messageContent,
                                      style: TextStyle(
                                        color: isProvider
                                            ? Colors.white
                                            : theme.textTheme.bodyLarge?.color,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatTime(msg.createdAt),
                                          style: TextStyle(
                                            color: isProvider
                                                ? Colors.white.withValues(alpha: 0.65)
                                                : theme
                                                    .textTheme.bodyMedium?.color
                                                    ?.withValues(alpha: 0.65),
                                            fontSize: 8.5,
                                          ),
                                        ),
                                        if (isProvider) ...[
                                          const SizedBox(width: 4),
                                          _buildStatusIcon(msg.messageStatus),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Quick Reply Macros
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                itemCount: _macros.length,
                itemBuilder: (context, index) {
                  final macro = _macros[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _sendMessage(macro['text']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          macro['label']!,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Message Input Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Type verified message response...',
                        hintStyle: TextStyle(
                          fontSize: 11.5,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.6),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        fillColor: theme.scaffoldBackgroundColor,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _sendMessage(),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
