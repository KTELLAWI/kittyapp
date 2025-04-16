import 'package:flutter/material.dart';
import 'package:fstore/common/tools/gravatar.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:provider/provider.dart';

import '../../../models/chat_view_model.dart';
import '../../../models/entities/chat_room.dart';

class ChatTypingStatus extends StatelessWidget {
  const ChatTypingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.read<ChatViewModel>();
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: StreamBuilder<ChatRoom>(
        stream: model.selectedChatRoomStream,
        builder: (context, snapshot) {
          final chatRoom = snapshot.data;

          // Take max 3 users
          final usersTyping = chatRoom
                  ?.getOtherUsers(model.senderEmail)
                  .where((user) => user.isTyping)
                  .take(3) ??
              [];

          if (usersTyping.isEmpty) {
            return const SizedBox(width: double.infinity);
          }

          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    for (var i = 0; i < usersTyping.length; i++)
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: 8.0 * i),
                        child: CircleAvatar(
                          radius: 10,
                          child: CircleAvatar(
                            radius: 8.0,
                            backgroundImage: NetworkImage(
                              getGravatarUrl(usersTyping.elementAt(i).email),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8.0),
                JumpingDots(
                  animationDuration: const Duration(milliseconds: 200),
                  innerPadding: 3,
                  radius: 4,
                  verticalOffset: 8,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
