import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/chat_message.dart';

class ChatRepository {
  ChatRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection(AppConstants.chatsCollection);

  /// Deterministische Chat-ID:
  /// - Fahrt-Chat:   "ride_{rideId}"           (alle Teilnehmer der Fahrt
  ///                 können hierüber sprechen; einfachster Fall: 1:1
  ///                 zwischen Fahrer und einem bestimmten Mitfahrer)
  /// - Direkt-Chat:  "dm_{sortierte UserIds}"  (unabhängig von einer Fahrt)
  String threadIdFor({
    String? rideId,
    required String userAId,
    required String userBId,
  }) {
    if (rideId != null) {
      final sorted = [userAId, userBId]..sort();
      return 'ride_${rideId}_${sorted.join('_')}';
    }
    final sorted = [userAId, userBId]..sort();
    return 'dm_${sorted.join('_')}';
  }

  Future<void> ensureThread(ChatThread thread) async {
    final ref = _chats.doc(thread.id);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set(thread.toMap());
    }
  }

  Stream<List<ChatThread>> watchThreadsFor(String userId) => _chats
      .where('participantIds', arrayContains: userId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ChatThread.fromDoc).toList());

  Stream<List<ChatMessage>> watchMessages(String threadId) => _chats
      .doc(threadId)
      .collection(AppConstants.messagesSubcollection)
      .orderBy('sentAt')
      .snapshots()
      .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());

  Future<void> sendMessage(String threadId, ChatMessage message) async {
    final threadRef = _chats.doc(threadId);
    await threadRef
        .collection(AppConstants.messagesSubcollection)
        .add(message.toMap());
    await threadRef.update({
      'lastMessage': message.text,
      'lastMessageAt': Timestamp.fromDate(message.sentAt),
    });
  }
}
