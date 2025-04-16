import 'package:collection/collection.dart';

import '../../constants/keys.dart';
import 'chat_user.dart';

class ChatRoom {
  final String id;
  final DateTime updatedAt;
  final String latestMessage;
  final List<ChatUser> users;

  ChatRoom(
    this.id, {
    required this.updatedAt,
    this.latestMessage = '',
    this.users = const [],
  });

  factory ChatRoom.fromJson(String id, Map json) {
    return ChatRoom(
      id,
      updatedAt: DateTime.tryParse(
              '${json[kFirestoreOldFieldUpdatedAtForChatRooms]}') ??
          DateTime.now(),
      latestMessage: json[kFirestoreFieldLatestMessage] ?? '',
      users: List<Map<String, dynamic>>.from(json[kFirestoreFieldUsers])
          .map((e) => ChatUser.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        kFirestoreOldFieldUpdatedAtForChatRooms:
            updatedAt.toUtc().toIso8601String(),
        kFirestoreFieldLatestMessage: latestMessage,
        kFirestoreFieldUsers: users.map((e) => e.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoom &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          updatedAt == other.updatedAt &&
          latestMessage == other.latestMessage &&
          users == other.users;

  @override
  int get hashCode =>
      id.hashCode ^
      updatedAt.hashCode ^
      latestMessage.hashCode ^
      users.hashCode;

  ChatRoom copyWith({
    String? id,
    DateTime? updatedAt,
    String? latestMessage,
    List<ChatUser>? users,
  }) {
    return ChatRoom(
      id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      latestMessage: latestMessage ?? this.latestMessage,
      users: users ?? this.users,
    );
  }
}

extension ChatRoomExtension on ChatRoom {
  List<ChatUser> getOtherUsers(String currentUserEmail) {
    if (currentUserEmail.isEmpty) {
      throw ArgumentError('currentUserEmail cannot be empty');
    }
    return users.whereNot((e) => e.email == currentUserEmail).toList();
  }

  ChatUser? getReceiverUser(String currentUserEmail) {
    if (currentUserEmail.isEmpty) {
      throw ArgumentError('currentUserEmail cannot be empty');
    }
    return users.firstWhereOrNull(
      (e) {
        return e.email != currentUserEmail;
      },
    );
  }

  ChatUser? getSenderUser(String currentUserEmail) {
    if (currentUserEmail.isEmpty) {
      throw ArgumentError('currentUserEmail cannot be empty');
    }
    return users.firstWhereOrNull(
      (e) {
        return e.email == currentUserEmail;
      },
    );
  }
}
