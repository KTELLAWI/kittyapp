import 'package:fstore/data/boxes.dart';
import 'package:fstore/generated/l10n.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../constants/keys.dart';

class ChatUser {
  final String email;
  final String name;
  final int unread;
  final DateTime lastActive;
  final String languageCode;
  final String pushToken;
  final bool isTyping;
  final List<String> blackList;

  ChatUser({
    this.email = '',
    this.name = '',
    this.unread = 0,
    required this.lastActive,
    this.languageCode = '',
    this.pushToken = '',
    this.isTyping = false,
    this.blackList = const [],
  });

  factory ChatUser.fromJson(Map json) => ChatUser(
        email: json[kFirestoreFieldEmail] ?? '',
        name: json[kFirestoreFieldName] ?? '',
        unread: json[kFirestoreFieldUnread] ?? 0,
        lastActive: DateTime.tryParse('${json[kFirestoreFieldLastActive]}') ??
            DateTime(0),
        languageCode: json[kFirestoreFieldLanguageCode] ?? '',
        pushToken: json[kFirestoreFieldPushToken] ?? '',
        isTyping: json[kFirestoreFieldIsTyping] ?? false,
        blackList: List<String>.from(json[kFirestoreFieldBlackList] ?? []),
      );

  Map<String, dynamic> toJson() => {
        kFirestoreFieldEmail: email,
        kFirestoreFieldName: name,
        kFirestoreFieldUnread: unread,
        kFirestoreFieldLastActive: lastActive.toUtc().toIso8601String(),
        kFirestoreFieldLanguageCode: languageCode,
        kFirestoreFieldPushToken: pushToken,
        kFirestoreFieldIsTyping: isTyping,
        kFirestoreFieldBlackList: blackList,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatUser &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          name == other.name &&
          unread == other.unread &&
          languageCode == other.languageCode &&
          pushToken == other.pushToken &&
          lastActive == other.lastActive &&
          isTyping == other.isTyping &&
          blackList == other.blackList;

  @override
  int get hashCode =>
      email.hashCode ^
      name.hashCode ^
      unread.hashCode ^
      lastActive.hashCode ^
      languageCode.hashCode ^
      languageCode.hashCode ^
      isTyping.hashCode ^
      blackList.hashCode;

  ChatUser copyWith({
    String? email,
    String? name,
    int? unread,
    DateTime? lastActive,
    String? languageCode,
    String? pushToken,
    bool? isTyping,
    List<String>? blackList,
  }) {
    return ChatUser(
      email: email ?? this.email,
      name: name ?? this.name,
      unread: unread ?? this.unread,
      lastActive: lastActive ?? this.lastActive,
      languageCode: languageCode ?? this.languageCode,
      pushToken: pushToken ?? this.pushToken,
      isTyping: isTyping ?? this.isTyping,
      blackList: blackList ?? this.blackList,
    );
  }
}

extension ChatUserExtension on ChatUser {
  String get displayName => name.isNotEmpty ? name : email;

  String get displayUnread => unread > 0 ? '$unread' : '';

  bool get isActive => lastActive.toLocal().isAfter(
        DateTime.now().subtract(
          const Duration(minutes: 5),
        ),
      );

  bool get isLongTimeAgo => lastActive.toLocal().isBefore(
        DateTime.now().subtract(
          const Duration(days: 1),
        ),
      );

  bool get isActiveNa => lastActive.millisecondsSinceEpoch <= 0;

  String displayLastActive(S locale) {
    if (isActive) {
      return locale.activeNow;
    }
    if (isLongTimeAgo) {
      return locale.activeLongAgo;
    }
    return locale.activeFor(timeago.format(
      lastActive,
      locale: SettingsBox().languageCode,
    ));
  }
}
