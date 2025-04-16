import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fstore/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../models/chat_view_model.dart';
import '../../../models/entities/chat_room.dart';
import '../../../realtime_chat.dart';
import '../chat_dashboard/widgets/message_list.dart';
import 'chat_room_item.dart';

class ChatRooms extends StatelessWidget {
  final ScrollController? scrollController;

  const ChatRooms({
    super.key,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = context
        .select((ChatViewModel chatViewModel) => chatViewModel.senderEmail);
    return Selector<ChatViewModel, Stream<List<ChatRoom>>>(
      selector: (BuildContext __, ChatViewModel chatViewModel) =>
          chatViewModel.chatRooms,
      builder: (BuildContext _, Stream<List<ChatRoom>> stream, __) {
        return StreamBuilder<List<ChatRoom>>(
          stream: stream,
          builder:
              (BuildContext context, AsyncSnapshot<List<ChatRoom>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const Center(
                  child: CircularProgressIndicator(),
                );
              case ConnectionState.active:
                if (snapshot.hasError) {
                  if ('${snapshot.error}'.contains('permission-denied')) {
                    return const ChatAuth();
                  }
                  return _renderScaffold(
                    context,
                    child: Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.hasData) {
                  final chatRooms = snapshot.data!;
                  if (chatRooms.isEmpty) {
                    return _renderScaffold(
                      context,
                      floatingActionButton: _rendeChatWithAdminButton(context),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                S.of(context).noConversation,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                S.of(context).noConversationDescription,
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: (context.select((ChatViewModel chatViewModel) =>
                            chatViewModel.selectedChatRoomId != null))
                        ? const MessageList(isFromChatList: true)
                        : Scaffold(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            appBar: AppBar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              titleSpacing: 0.0,
                              title: Text(
                                S.of(context).conversations,
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .headlineSmall,
                              ),
                              centerTitle: true,
                            ),
                            floatingActionButton:
                                _rendeChatWithAdminButton(context),
                            body: ListView.builder(
                              controller: scrollController,
                              itemBuilder: (context, index) {
                                final chatRoom = chatRooms[index];
                                if (currentUserEmail.isEmpty) {
                                  /// Hide invalid chat.
                                  return const SizedBox();
                                }
                                return ChatRoomItem(
                                  chatRoom: chatRoom,
                                  onTap: () => _handleChatRoomTap(
                                    context,
                                    chatRoom,
                                  ),
                                );
                              },
                              itemCount: chatRooms.length,
                            ),
                          ),
                  );
                }
                return const SizedBox.shrink();
              default:
                return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  void _handleChatRoomTap(BuildContext context, ChatRoom chatRoom) {
    final model = context.read<ChatViewModel>();
    if (chatRoom.id == model.selectedChatRoomId) {
      return;
    }
    model.selectedChatRoomId = chatRoom.id;
  }

  Widget _renderScaffold(
    BuildContext context, {
    required Widget child,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      floatingActionButton: floatingActionButton,
      body: child,
    );
  }

  Widget? _rendeChatWithAdminButton(BuildContext context) {
    final currentUserEmail = context
        .select((ChatViewModel chatViewModel) => chatViewModel.senderEmail);
    if (context.read<ChatViewModel>().isAdmin) {
      return null;
    }
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RealtimeChat(
              userEmail: currentUserEmail,
              type: RealtimeChatType.customerToAdmin,
            ),
          ),
        );
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      tooltip: S.of(context).needHelp,
      child: Icon(
        CupertinoIcons.conversation_bubble,
        color: Theme.of(context).primaryColor,
        size: 32,
      ),
    );
  }
}
