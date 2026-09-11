import 'package:cloud_firestore/cloud_firestore.dart';

/// Ein Chat kann entweder an eine Fahrt (rideId) gebunden sein, oder ein
/// direkter 1:1-Chat zwischen zwei Nutzern ohne Fahrtbezug sein.
/// Die Chat-ID wird deterministisch gebildet, siehe [ChatRepository].
class ChatThread {
  final String id;
  final String? rideId; // null => reiner 1:1-Chat ohne Fahrtbezug
  final List<String> participantIds; // genau 2 Nutzer-IDs
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const ChatThread({
    required this.id,
    this.rideId,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
  });

  Map<String, dynamic> toMap() => {
        'rideId': rideId,
        'participantIds': participantIds,
        'lastMessage': lastMessage,
        'lastMessageAt':
            lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      };

  factory ChatThread.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return ChatThread(
      id: doc.id,
      rideId: map['rideId'],
      participantIds: List<String>.from(map['participantIds'] ?? const []),
      lastMessage: map['lastMessage'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
      };

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return ChatMessage(
      id: doc.id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
