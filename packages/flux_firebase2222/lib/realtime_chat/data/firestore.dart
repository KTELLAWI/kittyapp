import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fstore/data/boxes.dart';

import '../constants/keys.dart';
import '../models/entities/chat_message.dart';
import '../models/entities/chat_room.dart';
import '../models/entities/chat_user.dart';

class FirestoreChat {
  static Stream<QuerySnapshot<ChatRoom>> getChatRooms(
    FirebaseFirestore instance,
  ) {
    return instance
        .collection(kFirestoreCollectionChatRooms)
        .withConverter<ChatRoom>(
          fromFirestore: (snapshot, _) => ChatRoom.fromJson(
            snapshot.id,
            snapshot.data() ?? {},
          ),
          toFirestore: (item, _) => item.toJson(),
        )
        .orderBy(kFirestoreOldFieldUpdatedAtForChatRooms, descending: true)
        .snapshots();
  }

  static Stream<DocumentSnapshot<ChatRoom>> getChatRoom(
    FirebaseFirestore instance,
    String roomId,
  ) {
    return instance
        .collection(kFirestoreCollectionChatRooms)
        .doc(roomId)
        .withConverter<ChatRoom>(
          fromFirestore: (snapshot, _) {
            return ChatRoom.fromJson(
              snapshot.id,
              snapshot.data() ?? {},
            );
          },
          toFirestore: (item, _) => item.toJson(),
        )
        .snapshots();
  }

  static Stream<QuerySnapshot<ChatMessage>> getConversation(
      FirebaseFirestore instance, String chatId) {
    return instance
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .collection(kFirestoreCollectionChatScreen)
        .orderBy(
          kFirestoreFieldCreatedAt,
          descending: true,
        )
        .withConverter<ChatMessage>(
          fromFirestore: (snapshot, _) => ChatMessage.fromJson(
            snapshot.data() ?? {},
          ),
          toFirestore: (chatMessage, _) => chatMessage.toJson(),
        )
        .snapshots();
  }

  static Future<DocumentReference<ChatMessage>> sendChatMessage(
    FirebaseFirestore instance,
    String chatId,
    String sender,
    String image,
    String message,
  ) async {
    return instance
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .collection(kFirestoreCollectionChatScreen)
        .withConverter<ChatMessage>(
          fromFirestore: (snapshot, _) => ChatMessage.fromJson(
            snapshot.data() ?? {},
          ),
          toFirestore: (chatMessage, _) => chatMessage.toJson(),
        )
        .add(
          ChatMessage(
            createdAt: DateTime.now(),
            sender: sender,
            image: image,
            text: message,
          ),
        );
  }

  static Future<void> updateTypingStatus(
    FirebaseFirestore instance,
    String chatId, {
    bool? isTyping = false,
    String? senderEmail,
    String? pushToken,
  }) async {
    return updateChatRoom(
      instance,
      chatId,
      isTyping: isTyping,
      senderEmail: senderEmail,
      pushToken: pushToken,
    );
  }

  static Future<ChatRoom> initChatRoom(
    FirebaseFirestore instance,
    String chatId, {
    String? senderEmail,
    String? receiverEmail,
  }) async {
    final ref = getChatRoomReference(
      instance,
      chatId,
    );
    final snapshot = await ref.get();
    final data = snapshot.data();
    final chatRoom = data ??
        ChatRoom(
          chatId,
          updatedAt: data?.updatedAt ?? DateTime.now(),
        );
    final users = List<ChatUser>.from(chatRoom.users);
    var shouldUpdateUsers = users.isEmpty;

    if (senderEmail != null && users.every((e) => e.email != senderEmail)) {
      users.add(
        ChatUser(
          email: senderEmail,
          lastActive: DateTime(0),
        ),
      );

      shouldUpdateUsers = true;
    }

    if (receiverEmail != null && users.every((e) => e.email != receiverEmail)) {
      users.add(
        ChatUser(
          email: receiverEmail,
          lastActive: DateTime(0),
        ),
      );

      shouldUpdateUsers = true;
    }

    if (!snapshot.exists || shouldUpdateUsers) {
      final newChatRoom = chatRoom.copyWith(users: users);
      await ref.set(newChatRoom);
      return newChatRoom;
    }

    return chatRoom;
  }

  static Future updateChatRoom(
    FirebaseFirestore instance,
    String chatId, {
    String? latestMessage,
    int? receiverUnreadCountPlus,
    bool? isTyping,
    List<String>? blackList,
    String? senderName,
    String? senderEmail,
    String? pushToken,
  }) async {
    final newLangCode = SettingsBox().languageCode;
    var chatRoom =
        await initChatRoom(instance, chatId, senderEmail: senderEmail);

    final currentUsers = chatRoom.users.map((e) {
      if (e.email == senderEmail) {
        return e.copyWith(
          lastActive: DateTime.now(),
          unread: 0,
          languageCode: newLangCode,
          isTyping: isTyping,
          blackList: blackList,
          pushToken: pushToken != null &&
                  pushToken.isNotEmpty &&
                  e.pushToken != pushToken
              ? pushToken
              : null,
        );
      } else {
        return e.copyWith(
          unread: e.unread + (receiverUnreadCountPlus ?? 0),
        );
      }
    }).toList();

    chatRoom = chatRoom.copyWith(
        latestMessage: latestMessage,
        updatedAt: latestMessage != null ? DateTime.now() : null,
        users: currentUsers);
    return instance
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .update(chatRoom.toJson());
  }

  static Future<void> deleteChatRoom(
      FirebaseFirestore instance, String chatId) async {
    /// Get all messages in the chat room.
    final allMessages = await instance
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .collection(kFirestoreCollectionChatScreen)
        .get();

    /// Delete all the chat room's messages.
    for (DocumentSnapshot document in allMessages.docs) {
      await document.reference.delete();
    }

    /// Delete the chat room.
    return instance
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .delete();
  }

  static Future<String> getChatRoomId(
    FirebaseFirestore instance,
    String senderEmail,
    String receiverEmail,
  ) async {
    var chatId = '$receiverEmail-$senderEmail';
    final snapshot = await getChatRoomReference(
      instance,
      chatId,
    ).get();

    if (!snapshot.exists) {
      chatId = '$senderEmail-$receiverEmail';
    }

    await initChatRoom(
      instance,
      chatId,
      senderEmail: senderEmail,
      receiverEmail: receiverEmail,
    );
    return chatId;
  }

  static DocumentReference<ChatRoom> getChatRoomReference(
    FirebaseFirestore instance,
    String roomId,
  ) {
    return instance
        .collection(kFirestoreCollectionChatRooms)
        .doc(roomId)
        .withConverter<ChatRoom>(
          fromFirestore: (snapshot, _) {
            if (!snapshot.exists) {}
            return ChatRoom.fromJson(
              snapshot.id,
              snapshot.data() ?? {},
            );
          },
          toFirestore: (item, _) => item.toJson(),
        );
  }

  static Future<void> updateBlackList(
    FirebaseFirestore instance,
    String chatId, {
    List<String>? blackList,
    String? senderEmail,
    String? pushToken,
  }) async {
    return updateChatRoom(
      instance,
      chatId,
      senderEmail: senderEmail,
      pushToken: pushToken,
      blackList: blackList,
    );
  }
}
