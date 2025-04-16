/// Collections.
const String kFirestoreCollectionChatRooms = 'chatRooms';
const String kFirestoreCollectionChatScreen = 'chatScreen';

/// Fields.

// Use `createdAt` key instead of `updatedAt` because old data structure use the
// wrong key. But please note that the purpose of this key is to update the time
const String kFirestoreOldFieldUpdatedAtForChatRooms = 'createdAt';
const String kFirestoreFieldCreatedAt = 'createdAt';
const String kFirestoreFieldUpdatedAt = 'updatedAt';
const String kFirestoreFieldLatestMessage = 'lastestMessage';
const String kFirestoreFieldUnread = 'unread';
const String kFirestoreFieldLanguageCode = 'langCode';
const String kFirestoreFieldPushToken = 'pushToken';
const String kFirestoreFieldName = 'name';
const String kFirestoreFieldUserEmail = 'userEmail';
const String kFirestoreFieldUsers = 'users';
const String kFirestoreFieldEmail = 'email';
const String kFirestoreFieldImage = 'image';
const String kFirestoreFieldText = 'text';
const String kFirestoreFieldSender = 'sender';
const String kFirestoreFieldLastActive = 'lastActive';
const String kFirestoreFieldIsTyping = 'isTyping';
const String kFirestoreFieldBlackList = 'blackList';
