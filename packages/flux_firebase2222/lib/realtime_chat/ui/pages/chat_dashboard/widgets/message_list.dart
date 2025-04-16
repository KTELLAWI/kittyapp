import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fstore/common/constants.dart';
import 'package:fstore/common/tools/gravatar.dart';
import 'package:fstore/generated/l10n.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../../../constants/enums.dart';
import '../../../../models/chat_view_model.dart';
import '../../../../models/entities/chat_room.dart';
import '../../../../models/entities/chat_user.dart';
import '../../chat_conversation/chat_conversation.dart';

enum _Action {
  delete,
  block,
}

class MessageList extends StatelessWidget {
  const MessageList({
    super.key,
    required this.isFromChatList,
    this.initMessage,
  });

  final bool isFromChatList;
  final String? initMessage;

  @override
  Widget build(BuildContext context) {
    final model = context.read<ChatViewModel>();
    Future<bool> onTapBack() async {
      final chatRoomId = model.selectedChatRoomId;
      if (chatRoomId != null) {
        unawaited(model.updateTypingStatus(chatRoomId, false));
        model.selectedChatRoomId = null;
        return !isFromChatList;
      }
      return true;
    }

    return WillPopScopeWidget(
      onWillPop: onTapBack,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          leading: BackButton(
            onPressed: () async {
              final result = await onTapBack();
              if (result) {
                Navigator.of(context).pop();
              }
            },
          ),
          titleSpacing: 0.0,
          title: StreamBuilder<ChatRoom>(
            stream: model.selectedChatRoomStream,
            builder: (context, snapshot) {
              final selectedChatRoom = snapshot.data;
              final senderUser =
                  selectedChatRoom?.getSenderUser(model.senderEmail);
              final receiverUser =
                  selectedChatRoom?.getReceiverUser(model.senderEmail);
              String? displayName;
              if (model.type == RealtimeChatType.customerToAdmin ||
                  model.type == RealtimeChatType.customerToVendor) {
                displayName = model.receiverName;
              }
              return Row(
                children: [
                  if (selectedChatRoom != null) ...[
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        getGravatarUrl(receiverUser?.email ?? ''),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: receiverUser?.email ?? '',
                            waitDuration: const Duration(milliseconds: 500),
                            child: Text(
                              displayName ?? receiverUser?.displayName ?? '',
                              style:
                                  context.theme.textTheme.titleLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!(receiverUser?.isActiveNa ?? true))
                            Row(
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: receiverUser?.isActive == true
                                        ? Colors.green
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: receiverUser?.isActive == true
                                          ? Colors.green
                                          : Theme.of(context).disabledColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: const SizedBox(
                                    width: 8,
                                    height: 8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  receiverUser
                                          ?.displayLastActive(S.of(context)) ??
                                      '',
                                  style: TextStyle(
                                    color: receiverUser?.isActive == true
                                        ? Colors.green
                                        : context.theme.disabledColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    _renderAction(context, senderUser, receiverUser),
                  ] else
                    Expanded(
                      child: Text(
                        S.of(context).message,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ChatConversation(
                initMessage: initMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderAction(
      BuildContext context, ChatUser? senderUser, ChatUser? receiverUser) {
    final isSenderBlockReceiver =
        senderUser?.blackList.contains(receiverUser?.email) ?? false;
    final isReceiverBlockSender =
        receiverUser?.blackList.contains(senderUser?.email) ?? false;

    final viewModel = context.read<ChatViewModel>();
    final chatRoomId = viewModel.selectedChatRoomId;

    final actions = <PopupMenuEntry<_Action>>[];
    if (viewModel.userCanDeleteChat &&
        !isReceiverBlockSender &&
        !isSenderBlockReceiver) {
      actions.add(
        PopupMenuItem<_Action>(
          value: _Action.delete,
          child: Text(S.of(context).deleteConversation),
        ),
      );
    }

    if (viewModel.userCanBlockAnotherUser && !isReceiverBlockSender) {
      actions.add(
        PopupMenuItem<_Action>(
          value: _Action.block,
          child: Text(
            isSenderBlockReceiver
                ? S.of(context).unblockUser
                : S.of(context).blockUser,
          ),
        ),
      );
    }

    if (actions.isEmpty ||
        senderUser == null ||
        receiverUser == null ||
        chatRoomId == null) {
      return const SizedBox();
    }

    return PopupMenuButton<_Action>(
      icon: const Icon(Icons.more_vert),
      onSelected: (item) async {
        if (item == _Action.delete) {
          final confirmed = await confirmedDialog(
            context,
            title: S.of(context).deleteConversation,
            content: S.of(context).confirmDelete,
            confirmedButton: S.of(context).delete,
          );
          if (confirmed == true) {
            /// Delete conversation.
            await viewModel.deleteCurrentChatRoom();
          }
          return;
        }

        if (item == _Action.block) {
          final blackList = List<String>.from(senderUser.blackList);
          if (isSenderBlockReceiver) {
            final confirmed = await confirmedDialog(
              context,
              title: S.of(context).unblockUser,
              content: S.of(context).doYouWantToUnblock,
              confirmedButton: S.of(context).unblock,
            );

            if (confirmed == true) {
              /// Unblock user
              blackList.remove(receiverUser.email);
              await viewModel.updateBlackList(chatRoomId, blackList);
            }
          } else {
            final confirmed = await confirmedDialog(
              context,
              title: S.of(context).blockUser,
              content: S.of(context).willNotSendAndReceiveMessage,
              confirmedButton: S.of(context).block,
            );

            if (confirmed == true) {
              /// Block user
              blackList.add(receiverUser.email);
              await viewModel.updateBlackList(chatRoomId, blackList);
            }
          }
        }
      },
      itemBuilder: (context) => actions,
    );
  }

  Future<bool?> confirmedDialog(BuildContext context,
      {required String title,
      required String content,
      required String confirmedButton}) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmedButton),
          ),
        ],
      ),
    );
  }
}
