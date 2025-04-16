import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fstore/common/config.dart';
import 'package:fstore/common/config/models/config_chat.dart';

import '../constants/enums.dart';
import '../repos/base/chat_repository.dart';
import 'entities/chat_message.dart';
import 'entities/chat_room.dart';

class ChatViewModel extends ChangeNotifier {
  final RealtimeChatType _type;

  final String _receiverName;
  final String _receiverEmail;

  ChatViewModel(
    this._type,
    this._receiverName,
    this._receiverEmail,
  );

  ChatRepository? _repository;

  late String _senderEmail;

  bool get isAdmin =>
      _senderEmail == adminEmail || _type == RealtimeChatType.adminToCustomers;

  RealtimeChatType get type => _type;

  String get senderEmail => _senderEmail;

  String get receiverName => _receiverName;

  String get receiverEmail => _receiverEmail;

  StreamSubscription<String>? _authSubscription;

  bool get isAuthenticated => _senderEmail.isNotEmpty;

  bool get isInitialized => _repository != null;

  Stream<List<ChatRoom>> _chatRooms = const Stream.empty();

  Stream<List<ChatRoom>> get chatRooms => _chatRooms;

  String? _selectedChatRoomId;

  String? get selectedChatRoomId => _selectedChatRoomId;

  set selectedChatRoomId(String? value) {
    _selectedChatRoomId = value;
    notifyListeners();
  }

  Stream<ChatRoom> get selectedChatRoomStream => _selectedChatRoomId != null
      ? _repository!.getChatRoom(
          _selectedChatRoomId!,
        )
      : const Stream.empty();

  Future<void> init(ChatRepository repository) async {
    _repository = repository;

    _senderEmail = _repository!.userEmail;

    if (_type == RealtimeChatType.adminToCustomers ||
        _type == RealtimeChatType.vendorToCustomers ||
        _type == RealtimeChatType.userToUsers) {
      final isAllowAdminGetAllChatRooms =
          _senderEmail == adminEmail && adminCanAccessAllChatRooms;
      _chatRooms = getChatRoomsStream(isAllowAdminGetAllChatRooms);
    } else {
      _selectedChatRoomId = await _repository?.getChatRoomId(
        _senderEmail,
        _receiverEmail,
      );
    }
    notifyListeners();

    _authSubscription = repository.userEmailStream.listen((email) {
      if (email.isNotEmpty && email != _senderEmail) {
        _senderEmail = email;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  RealtimeChatConfig get realtimeChatConfig => kConfigChat.realtimeChatConfig;

  String get adminName => realtimeChatConfig.adminName;

  String get adminEmail => realtimeChatConfig.adminEmail;

  bool get enableRealtimeChat => realtimeChatConfig.enable;

  bool get userCanDeleteChat => realtimeChatConfig.userCanDeleteChat;

  bool get userCanBlockAnotherUser =>
      realtimeChatConfig.userCanBlockAnotherUser;

  bool get adminCanAccessAllChatRooms =>
      realtimeChatConfig.adminCanAccessAllChatRooms;

  Stream<List<ChatRoom>> getChatRoomsStream(bool allowAdminGetAllChatRooms) {
    return _repository!.getChatRooms(senderEmail, allowAdminGetAllChatRooms);
  }

  Stream<List<ChatMessage>> getChatConversation(String chatId) {
    return _repository!.getConversation(chatId);
  }

  Future<void> sendChatMessage(
    String chatId,
    String image,
    String message,
  ) async {
    final sender = _senderEmail;
    final msg = image.isNotEmpty ? '$sender has sent an image.' : message;
    await _repository!.sendChatMessage(
      chatId,
      sender,
      image,
      msg,
    );
    await _repository!.updateChatRoom(
      chatId,
      latestMessage: msg,
      receiverUnreadCountPlus: 1,
      sender: sender,
    );
  }

  Future<void> updateTypingStatus(String chatId, bool status) async {
    switch (_type) {
      case RealtimeChatType.adminToCustomers:
      case RealtimeChatType.vendorToCustomers:
      case RealtimeChatType.customerToAdmin:
      case RealtimeChatType.customerToVendor:
      case RealtimeChatType.userToUsers:
        await _repository!.updateTypingStatus(
          chatId,
          isTyping: status,
          senderEmail: _senderEmail,
        );
        break;
    }
  }

  Future<void> deleteCurrentChatRoom() async {
    final chatRoomId = _selectedChatRoomId;
    if (chatRoomId != null) {
      _selectedChatRoomId = null;
      notifyListeners();
      await _repository!.deleteChatRoom(chatRoomId);
    }
  }

  Future<void> updateBlackList(String chatId, List<String> emails) async {
    return _repository!.updateBlackList(
      chatId,
      blackList: emails,
      senderEmail: _senderEmail,
    );
  }
}
