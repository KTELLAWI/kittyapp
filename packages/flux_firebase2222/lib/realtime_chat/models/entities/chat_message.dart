import '../../constants/keys.dart';

class ChatMessage {
  final String image;
  final String sender;
  final DateTime createdAt;
  final String text;

  ChatMessage({
    this.image = '',
    this.sender = '',
    required this.createdAt,
    this.text = '',
  });

  factory ChatMessage.fromJson(Map json) => ChatMessage(
        image: json[kFirestoreFieldImage] ?? '',
        sender: json[kFirestoreFieldSender] ?? '',
        createdAt: DateTime.tryParse('${json[kFirestoreFieldCreatedAt]}') ??
            DateTime.now(),
        text: json[kFirestoreFieldText] ?? '',
      );

  Map<String, dynamic> toJson() => {
        kFirestoreFieldImage: image,
        kFirestoreFieldSender: sender,
        kFirestoreFieldCreatedAt: createdAt.toUtc().toIso8601String(),
        kFirestoreFieldText: text,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          image == other.image &&
          sender == other.sender &&
          createdAt == other.createdAt &&
          text == other.text;

  @override
  int get hashCode =>
      image.hashCode ^ sender.hashCode ^ createdAt.hashCode ^ text.hashCode;
}
