import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:fstore/generated/l10n.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../../models/chat_view_model.dart';
import '../../../models/entities/chat_message.dart';
import '../../../models/entities/chat_room.dart';
import '../chat_rooms/chat_auth.dart';
import 'chat_message_bubble.dart';
import 'chat_typing_status.dart';

class ChatConversation extends StatefulWidget {
  const ChatConversation({
    super.key,
    this.initMessage,
  });

  final String? initMessage;

  @override
  State<ChatConversation> createState() => _ChatConversationState();
}

class _ChatConversationState extends State<ChatConversation>
    with WidgetsBindingObserver {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool get isTyping =>
      _textEditingController.text.isNotEmpty && _focusNode.hasFocus;

  int _lastReceiverMessageIndex = 0;
  int _lastSenderMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initMessage?.isNotEmpty ?? false) {
      _textEditingController.text = widget.initMessage ?? '';
    }

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        // _focusNode.requestFocus();
        _focusNode.addListener(_updateTypingStatus);
      }
    });
  }

  void _updateTypingStatus() {
    if (!mounted) {
      return;
    }
    final model = context.read<ChatViewModel>();
    final chatRoomId = model.selectedChatRoomId;
    if (chatRoomId == null) {
      return;
    }

    EasyDebounce.debounce(
      'chat-message-update-typing-status',
      const Duration(milliseconds: 1000),
      () => model.updateTypingStatus(chatRoomId, isTyping),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_updateTypingStatus);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && isTyping) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.read<ChatViewModel>();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Selector<ChatViewModel, String?>(
        selector: (BuildContext __, ChatViewModel chatViewModel) =>
            chatViewModel.selectedChatRoomId,
        builder: (BuildContext context, String? chatRoomId, __) {
          if (chatRoomId == null) {
            // Not used.
            return const SizedBox();
          }
          return AutoHideKeyboard(
            child: Column(
              children: [
                Expanded(
                  child: Selector<ChatViewModel, Stream<List<ChatMessage>>>(
                    selector: (BuildContext __, ChatViewModel chatViewModel) =>
                        chatViewModel.getChatConversation(chatRoomId),
                    builder:
                        (BuildContext _, Stream<List<ChatMessage>> stream, __) {
                      return StreamBuilder<List<ChatMessage>>(
                        stream: stream,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<ChatMessage>> snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            case ConnectionState.active:
                              if (snapshot.hasError) {
                                if ('${snapshot.error}'
                                    .contains('permission-denied')) {
                                  return const ChatAuth();
                                }
                                return Center(
                                  child: Text(snapshot.error.toString()),
                                );
                              }
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
                                final chatMessages = snapshot.data!;
                                final model = context.read<ChatViewModel>();
                                final senderEmail = model.senderEmail;
                                final receiverEmail = model.receiverEmail;
                                _lastReceiverMessageIndex =
                                    chatMessages.indexWhere(
                                  (ChatMessage message) =>
                                      message.sender == receiverEmail,
                                );
                                _lastSenderMessageIndex =
                                    chatMessages.indexWhere(
                                  (ChatMessage message) =>
                                      message.sender == senderEmail,
                                );
                                return ListView.builder(
                                  key: ValueKey(chatRoomId),
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 16.0,
                                  ),
                                  itemCount: chatMessages.length + 1,
                                  itemBuilder: (context, fakeIndex) {
                                    if (fakeIndex == 0) {
                                      return const ChatTypingStatus();
                                    }
                                    final index = fakeIndex - 1;
                                    final msg = chatMessages[index];
                                    final shouldShowInfo =
                                        (index + 1) == chatMessages.length ||
                                            chatMessages[index + 1].sender !=
                                                msg.sender;
                                    final isLastMessage =
                                        index == _lastSenderMessageIndex ||
                                            index == _lastReceiverMessageIndex;
                                    var diffWithNextInMin =
                                        (index + 1) != chatMessages.length
                                            ? (chatMessages[index + 1]
                                                    .createdAt
                                                    .difference(msg.createdAt)
                                                    .inMinutes)
                                                .abs()
                                            : 0;

                                    var diffWithPrevInMin = index != 0
                                        ? (chatMessages[index - 1]
                                                .createdAt
                                                .difference(msg.createdAt)
                                                .inMinutes)
                                            .abs()
                                        : 0;

                                    if (diffWithNextInMin <
                                        Duration.minutesPerHour / 4) {
                                      diffWithNextInMin = 0;
                                    }
                                    if (diffWithPrevInMin <
                                        Duration.minutesPerHour / 4) {
                                      diffWithPrevInMin = 0;
                                    }

                                    final isNextMessageFromSameSender =
                                        (index + 1) != chatMessages.length &&
                                            chatMessages[index + 1].sender ==
                                                msg.sender;

                                    final isPrevMessageFromSameSender =
                                        index != 0 &&
                                            chatMessages[index - 1].sender ==
                                                msg.sender;

                                    return ChatMessageBubble(
                                      key: ValueKey(
                                        '$chatRoomId-${msg.toJson()}',
                                      ),
                                      shouldShowInfo: shouldShowInfo,
                                      isFirstMessage:
                                          index + 1 == chatMessages.length,
                                      isLastMessage: isLastMessage,
                                      chatMessage: msg,
                                      diffWithNextInMin: diffWithNextInMin,
                                      diffWithPrevInMin: diffWithPrevInMin,
                                      isPrevMessageFromSameSender:
                                          isPrevMessageFromSameSender,
                                      isNextMessageFromSameSender:
                                          isNextMessageFromSameSender,
                                    );
                                  },
                                );
                              }
                              return const SizedBox.shrink();
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                  ),
                  child: SafeArea(
                    child: StreamBuilder<ChatRoom>(
                      stream: model.selectedChatRoomStream,
                      builder: (context, snapshot) {
                        final selectedChatRoom = snapshot.data;
                        if (selectedChatRoom == null) {
                          return const SizedBox.shrink();
                        }

                        final senderUser =
                            selectedChatRoom.getSenderUser(model.senderEmail);
                        final receiverUser =
                            selectedChatRoom.getReceiverUser(model.senderEmail);

                        final isSenderBlockReceiver = senderUser?.blackList
                                .contains(receiverUser?.email) ??
                            false;
                        final isReceiverBlockSender = receiverUser?.blackList
                                .contains(senderUser?.email) ??
                            false;

                        if (isSenderBlockReceiver || isReceiverBlockSender) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.block,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isSenderBlockReceiver
                                      ? S.of(context).userHasBeenBlocked
                                      : S.of(context).cannotSendMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                focusNode: _focusNode,
                                decoration: InputDecoration(
                                  hintText: S.of(context).typeAMessage,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(10),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.send),
                                    color: Theme.of(context).primaryColor,
                                    onPressed: () => _sendMessage(chatRoomId),
                                  ),
                                ),
                                minLines: 1,
                                maxLines: 3,
                                textInputAction: TextInputAction.send,
                                controller: _textEditingController,
                                onChanged: (_) => _updateTypingStatus(),
                                onSubmitted: (String text) {
                                  _sendMessage(chatRoomId);
                                },
                                onEditingComplete: () {
                                  _sendMessage(chatRoomId);
                                },
                                onTapOutside: (_) => _focusNode.unfocus(),
                              ),
                            ),
                          ],
                        );
                      },
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

  void _sendMessage(String chatRoomId) {
    if (_textEditingController.text.trim().isNotEmpty) {
      final model = context.read<ChatViewModel>();
      model.sendChatMessage(
        chatRoomId,
        '',
        _textEditingController.text,
      );
      _textEditingController.clear();
    }
  }
}
