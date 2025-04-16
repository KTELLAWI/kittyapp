import '../../models/entities/chat_message.dart';
import '../../models/entities/chat_room.dart';

abstract class ChatRepository {
  String? get pushToken;

  String get userEmail;

  Stream<String> get userEmailStream;

  Stream<List<ChatRoom>> getChatRooms(String email, bool getAllChatRooms);

  Stream<ChatRoom> getChatRoom(String roomId);

  Stream<List<ChatMessage>> getConversation(String chatId);

  Future<void> sendChatMessage(
    String chatId,
    String sender,
    String image,
    String message,
  );

  Future<void> updateTypingStatus(
    String chatId, {
    bool? isTyping,
    String? senderEmail,
  });

  Future<void> updateChatRoom(
    String chatId, {
    String? latestMessage,
    int? receiverUnreadCountPlus,
    String? sender,
  });

  Future<void> deleteChatRoom(String chatId);

  Future<String> getChatRoomId(String senderEmail, String receiverEmail);

  Future<void> updateBlackList(
    String chatId, {
    List<String>? blackList,
    String? senderEmail,
  });
}
