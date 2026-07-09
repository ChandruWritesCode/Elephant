import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile/controllers/auth.dart';
import 'package:mobile/pages/chat_details_page.dart';
import 'package:provider/provider.dart';
import 'package:mobile/widgets/chat_screen_modular_widgets.dart';
import 'package:mobile/controllers/chat.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatPage extends StatefulWidget {
  final String chatUserId;
  final String displayName;
  final bool isGroup;
  final bool isNew;

  const ChatPage({
    super.key,
    required this.chatUserId,
    required this.displayName,
    this.isGroup = false,
    this.isNew = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  bool _isSearchMode = false;
  final TextEditingController _chatSearchController = TextEditingController();
  List<dynamic> _searchResults = [];

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  bool _showScrollToBottom = false;
  // ignore: prefer_final_fields
  bool _isNearBottom = true;
  final Set<int> _selectedIndices = {};
  dynamic _replyingToMessage;
  late ChatController _chatController;
  late AuthState _authState;

  Timer? _highlightTimer;

  String? _highlightedMessageId;

  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _itemPositionsListener.itemPositions.addListener(_scrollListener);

    _chatController = context.read<ChatController>();
    _authState = context.read<AuthState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chatController.openChat(widget.chatUserId, isGroup: widget.isGroup);
        if (widget.isGroup && widget.isNew) {
          _sendMessage('Hey Everyone!!');
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _itemPositionsListener.itemPositions.removeListener(_scrollListener);

    Future.microtask(() {
      _chatController.closeChat();
    });

    _highlightTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_isNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom(animated: true);
        }
      });
    }
  }

  void _scrollToAndHighlight(String messageId) async {
    setState(() {
      _isSearchMode = false;
      _chatSearchController.clear();
      _searchResults.clear();
    });

    final chatState = context.read<ChatController>();
    final activeChat = chatState.activeChat;
    final bool isTyping = chatState.isPeerTyping;

    final targetIndex = activeChat.indexWhere((msg) => msg.id == messageId);

    if (targetIndex != -1 && _itemScrollController.isAttached) {
      final int realVisualIndex =
          (activeChat.length - 1 - targetIndex) + (isTyping ? 3 : 2);

      await _itemScrollController.scrollTo(
        index: realVisualIndex,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
        alignment: 0.4,
      );

      setState(() {
        _highlightedMessageId = messageId;
      });

      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
  }

  void _scrollListener() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final bottomItem = positions.firstWhere(
      (p) => p.index == 0,
      orElse: () => const ItemPosition(
        index: -1,
        itemLeadingEdge: 0,
        itemTrailingEdge: 0,
      ),
    );

    final isScrolledUp = bottomItem.index > 2 || (bottomItem.index == -1);

    if (isScrolledUp != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = isScrolledUp;
      });
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_itemScrollController.isAttached) return;

    if (animated) {
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _itemScrollController.jumpTo(index: 0);
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    String? replyName;
    if (_replyingToMessage != null) {
      final String pId = _replyingToMessage.senderId.trim().toLowerCase();
      final bool isMe =
          pId == 'me' ||
          (pId.isNotEmpty && pId != widget.chatUserId.trim().toLowerCase());
      replyName = isMe ? "You" : widget.displayName;
    }

    context.read<ChatController>().sendTextMessage(
      text,
      replyingTo: _replyingToMessage,
      replyingToName: replyName,
      senderId: _authState.currentUser!.displayName,
    );

    setState(() {
      _replyingToMessage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
    });
  }

  void _copySelectedMessages(List<dynamic> activeChat) {
    final sortedIndices = _selectedIndices.toList()..sort();

    final selectedTexts = sortedIndices
        .map((index) {
          final msg = activeChat[index];
          final time = DateFormat.jm().format(msg.createdAt);
          final senderName = msg.senderId == _authState.currentUser!.id
              ? "Me"
              : widget.displayName;

          return '[$time] $senderName: ${msg.content}';
        })
        .join('\n\n');

    Clipboard.setData(ClipboardData(text: selectedTexts));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));

    _clearSelection();
  }

  UserStatus _getPresenceStatusText(ChatController state) {
    return state.isPeerOnline ? UserStatus.online : UserStatus.offline;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildSearchAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(color: theme.colorScheme.surface),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearchMode = false;
            _chatSearchController.clear();
            _searchResults.clear();
          });
        },
      ),
      title: TextField(
        controller: _chatSearchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search in chat...',
          border: InputBorder.none,
        ),
        onChanged: (query) {
          if (query.trim().isEmpty) {
            setState(() => _searchResults = []);
            return;
          }

          final chatState = context.read<ChatController>();
          final lowercaseQuery = query.toLowerCase();

          setState(() {
            _searchResults = chatState.activeChat.where((msg) {
              return msg.content.toLowerCase().contains(lowercaseQuery);
            }).toList();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatController>();
    final activeChat = chatState.activeChat;
    final isSelectionMode = _selectedIndices.isNotEmpty;
    final theme = Theme.of(context);

    if (activeChat.length != _previousMessageCount) {
      final isNewMessage = activeChat.length > _previousMessageCount;
      _previousMessageCount = activeChat.length;

      if (isNewMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom(animated: true);
        });
      }
    }

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _selectedIndices.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: _isSearchMode
              ? _buildSearchAppBar(theme)
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, -0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                  child: isSelectionMode
                      ? AppBar(
                          key: const ValueKey('SelectionAppBar'),
                          backgroundColor: theme.colorScheme.primary,
                          leading: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onPrimary,
                            ),
                            onPressed: _clearSelection,
                          ),
                          title: Text(
                            '${_selectedIndices.length} Selected',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: theme.colorScheme.onPrimary,
                              ),
                              onPressed: () =>
                                  _copySelectedMessages(activeChat),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: theme.colorScheme.onPrimary,
                              ),
                              onPressed: () {
                                _clearSelection();
                              },
                            ),
                          ],
                        )
                      : GlassAppBar(
                          isGroup: widget.isGroup,
                          key: const ValueKey('GlassAppBar'),
                          name: widget.displayName,
                          status: widget.isGroup
                              ? null
                              : _getPresenceStatusText(chatState),
                          onTitleTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailsPage(
                                  isGroup: widget.isGroup,
                                  chatId: chatState.currentChatUserId!,
                                  chatName: widget.displayName,
                                  chatImageUrl: "",
                                ),
                              ),
                            );

                            // If the user clicked "Search" in ChatDetailsPage
                            if (result == 'start_search') {
                              setState(() {
                                _isSearchMode = true;
                              });
                            }
                          },
                        ),
                ),
        ),
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: chatState.isChatHistoryLoading && activeChat.isEmpty
                  ? Center(
                      key: const ValueKey('loading'),
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : activeChat.isEmpty
                  ? Center(
                      key: const ValueKey('empty'),
                      child: Text(
                        "No messages yet.\nSay hi!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ScrollablePositionedList.builder(
                      key: const ValueKey('list'),
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      reverse: true,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(
                        // bottom: 140,
                        top: 140,
                        left: 16,
                        right: 16,
                      ),
                      itemCount:
                          activeChat.length +
                          (chatState.isPeerTyping ? 2 : 1) +
                          1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const SizedBox(height: 140);
                        }
                        if (index == 1) {
                          return AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: SizedBox(
                              height: _replyingToMessage != null ? 80 : 0,
                            ),
                          );
                        }

                        if (chatState.isPeerTyping && index == 2) {
                          return _AnimatedMessageItem(
                            key: const ValueKey('typing_indicator'),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  bottom: 8,
                                  top: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16)
                                      .copyWith(
                                        bottomLeft: const Radius.circular(0),
                                      ),
                                ),
                                child: Text(
                                  "Typing...",
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final int msgIndex =
                            index - (chatState.isPeerTyping ? 3 : 2);
                        final int realIndex = activeChat.length - 1 - msgIndex;
                        final msg = activeChat[realIndex];

                        final bool isHighlighted =
                            msg.id == _highlightedMessageId;
                        final bool isSelected = _selectedIndices.contains(
                          realIndex,
                        );

                        bool showDateSeparator = false;
                        if (realIndex == 0) {
                          showDateSeparator = true;
                        } else {
                          final prevMsg = activeChat[realIndex - 1];
                          if (!_isSameDay(msg.createdAt, prevMsg.createdAt)) {
                            showDateSeparator = true;
                          }
                        }

                        final String cleanSenderId = msg.senderId
                            .trim()
                            .toLowerCase();
                        widget.chatUserId.trim().toLowerCase();

                        final bool isMe =
                            cleanSenderId == 'me' ||
                            (_authState.currentUser?.id != null &&
                                cleanSenderId ==
                                    _authState.currentUser!.id.toLowerCase());

                        final String senderId = msg.senderId
                            .trim()
                            .toLowerCase();
                        final String? displayName = widget.isGroup
                            ? (chatState.groupMemberNames[senderId] ??
                                  'Unknown')
                            : null;

                        bool showSenderName = widget.isGroup;
                        if (widget.isGroup && realIndex > 0) {
                          final previousMsg = activeChat[realIndex - 1];

                          if (previousMsg.senderId.trim().toLowerCase() ==
                              cleanSenderId) {
                            showSenderName = false;
                          }
                        }

                        return _AnimatedMessageItem(
                          key: ValueKey(msg.id.toString()),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateSeparator)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatDateSeparator(msg.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                onLongPress: () {
                                  HapticFeedback.selectionClick();
                                  _toggleSelection(realIndex);
                                },
                                onTap: () {
                                  if (isSelectionMode) {
                                    _toggleSelection(realIndex);
                                  }
                                },
                                child: AnimatedScale(
                                  scale: isSelected ? 0.95 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    decoration: BoxDecoration(
                                      color: isSelected || isHighlighted
                                          ? theme.colorScheme.primary
                                                .withValues(alpha: 0.25)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: SwipeToReply(
                                      isMe: isMe,
                                      onReply: () {
                                        setState(() {
                                          _replyingToMessage = msg;
                                        });
                                      },
                                      child: ChatBubble(
                                        message: msg.content,
                                        isMe: isMe,
                                        timestamp: msg.createdAt,
                                        isRead: msg.isRead,
                                        quotedMessage: msg.quotedMessage,
                                        isGroup: widget.isGroup,
                                        senderName: showSenderName
                                            ? displayName
                                            : null,
                                        onQuoteTap: msg.quotedMessage != null
                                            ? () => _scrollToAndHighlight(
                                                msg.quotedMessage!.id,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            if (_isSearchMode)
              Positioned.fill(
                top: kToolbarHeight + MediaQuery.of(context).padding.top,
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _chatSearchController.text.isEmpty
                                ? 'Type to search...'
                                : 'No messages found.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final msg = _searchResults[index];

                            String sender = "Unknown";
                            if (msg.senderId == _authState.currentUser?.id) {
                              sender = "You";
                            } else if (widget.isGroup) {
                              sender =
                                  context
                                      .read<ChatController>()
                                      .groupMemberNames[msg.senderId] ??
                                  'Someone';
                            } else {
                              sender = widget.displayName;
                            }

                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                title: Text(
                                  msg.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '$sender • ${DateFormat.yMd().add_jm().format(msg.createdAt)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                onTap: () {
                                  // Close search mode
                                  setState(() {
                                    _isSearchMode = false;
                                    _chatSearchController.clear();
                                    _searchResults.clear();
                                  });

                                  FocusScope.of(context).unfocus();

                                  _scrollToAndHighlight(msg.id);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),

            if (!_isSearchMode)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                right: 16,
                bottom: _replyingToMessage != null ? 180 : 100,
                child: AnimatedScale(
                  scale: _showScrollToBottom ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: _showScrollToBottom ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      elevation: 4,
                      onPressed: () => _scrollToBottom(animated: true),
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ),
              ),
            if (!_isSearchMode)
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.bottomCenter,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _replyingToMessage != null ? 1.0 : 0.0,
                        child: _replyingToMessage != null
                            ? ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 15,
                                    sigmaY: 15,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      border: Border(
                                        left: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 4,
                                        ),
                                        top: BorderSide(
                                          color: theme.colorScheme.surface
                                              .withValues(alpha: 0.8),
                                          width: 1,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.shadowColor.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, -4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Replying to message",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _replyingToMessage.content,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            size: 20,
                                            color: theme.iconTheme.color,
                                          ),
                                          onPressed: () => setState(
                                            () => _replyingToMessage = null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(width: double.infinity, height: 0),
                      ),
                    ),
                    ChatInputArea(
                      onSendMessage: _sendMessage,
                      onTypingChanged: (isTyping) => context
                          .read<ChatController>()
                          .sendTypingNotification(isTyping),
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

class _AnimatedMessageItem extends StatefulWidget {
  final Widget child;

  const _AnimatedMessageItem({super.key, required this.child});

  @override
  State<_AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<_AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool isMe;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    required this.isMe,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _vibrated = false;
  final double _replyThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;

      if (widget.isMe) {
        if (_dragOffset > 0) _dragOffset = 0;
        if (_dragOffset < -_replyThreshold) {
          _dragOffset =
              -_replyThreshold + ((_dragOffset + _replyThreshold) * 0.15);
        }
      } else {
        if (_dragOffset < 0) _dragOffset = 0;
        if (_dragOffset > _replyThreshold) {
          _dragOffset =
              _replyThreshold + ((_dragOffset - _replyThreshold) * 0.15);
        }
      }

      if (_dragOffset.abs() >= _replyThreshold && !_vibrated) {
        HapticFeedback.lightImpact();
        _vibrated = true;
      } else if (_dragOffset.abs() < _replyThreshold) {
        _vibrated = false;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() >= _replyThreshold) {
      widget.onReply();
    }
    _vibrated = false;

    _animation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final double iconOpacity = (_dragOffset.abs() / _replyThreshold).clamp(
      0.0,
      1.0,
    );

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: widget.isMe ? null : 20,
            right: widget.isMe ? 20 : null,
            child: Opacity(
              opacity: iconOpacity,
              child: Transform.scale(
                scale: 0.5 + (0.5 * iconOpacity),
                child: Icon(
                  Icons.reply,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
