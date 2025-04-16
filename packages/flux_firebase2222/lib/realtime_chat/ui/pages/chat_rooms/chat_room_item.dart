import 'package:flutter/material.dart';
import 'package:fstore/common/extensions/extensions.dart';
import 'package:fstore/common/tools/gravatar.dart';
import 'package:fstore/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/chat_view_model.dart';
import '../../../models/entities/chat_room.dart';
import '../../../models/entities/chat_user.dart';

class ChatRoomItem extends StatefulWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const ChatRoomItem({
    super.key,
    required this.chatRoom,
    required this.onTap,
  });

  @override
  State<ChatRoomItem> createState() => _ChatRoomItemState();
}

class _ChatRoomItemState extends State<ChatRoomItem> {
  bool isHovered = false;

  ChatRoom get chatRoom => widget.chatRoom;

  String get senderEmail => context.read<ChatViewModel>().senderEmail;

  List<ChatUser> get otherUsers => chatRoom.getOtherUsers(senderEmail);

  ChatUser? get receiverUser => chatRoom.getReceiverUser(senderEmail);

  ChatUser? get senderUser => chatRoom.getSenderUser(senderEmail);

  @override
  Widget build(BuildContext context) {
    final receiverEmail = receiverUser?.email ?? '';

    if (receiverEmail.isEmpty) {
      /// Hide invalid chat.
      return const SizedBox.shrink();
    }
    final isSelectedRoom = context.select((ChatViewModel chatViewModel) =>
        chatViewModel.selectedChatRoomId == chatRoom.id);
    final unread = senderUser?.unread ?? 0;
    final isReceiverActive = receiverUser?.isActive;

    return MouseRegion(
      onExit: (_) => setState(() => isHovered = false),
      onEnter: (_) => setState(() => isHovered = true),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: isSelectedRoom || isHovered
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelectedRoom
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              SizedBox.square(
                dimension: 32.0,
                child: CircleAvatar(
                  backgroundImage: NetworkImage(
                    getGravatarUrl(receiverEmail),
                  ),
                  backgroundColor: Colors.grey[200],
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isReceiverActive == true
                            ? Colors.green
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isReceiverActive == true
                              ? Theme.of(context).colorScheme.surface
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: const SizedBox(
                        width: 9,
                        height: 9,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: receiverEmail,
                      waitDuration: const Duration(milliseconds: 500),
                      child: Text(
                        receiverEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: unread > 0 ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (otherUsers.any((user) => user.isTyping))
                          Flexible(
                            child: Text(
                              S.of(context).typing,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else if (chatRoom.latestMessage.isNotEmpty)
                          Flexible(
                            child: Tooltip(
                              waitDuration: const Duration(milliseconds: 500),
                              message: chatRoom.latestMessage,
                              child: Text(
                                chatRoom.latestMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight:
                                      unread > 0 ? FontWeight.w500 : null,
                                  color: unread > 0
                                      ? null
                                      : Theme.of(context).disabledColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (receiverUser?.email != null && unread > 0) ...[
                const SizedBox(width: 16),
                Container(
                  height: 24,
                  width: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
              const SizedBox(width: 16),
              Text(
                timeago.format(chatRoom.updatedAt.toLocal()),
                style: context.theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
