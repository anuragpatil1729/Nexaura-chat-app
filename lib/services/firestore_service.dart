
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:nexaaura/models/conversation_model.dart';
import 'package:nexaaura/models/group_model.dart' as group_model;
import 'package:nexaaura/models/user_model.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  // ... (user and conversation methods remain the same)
  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  Stream<AppUser> streamUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .where((snap) => snap.exists && snap.data() != null)
        .map((snap) => AppUser.fromMap(snap.data()!, uid));
  }

  Stream<List<AppUser>> streamUsers() {
    if (_currentUser == null) {
      return const Stream.empty();
    }

    return _db
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: _currentUser!.uid)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Stream<List<Conversation>> streamConversations() {
    if (_currentUser == null) {
      return const Stream.empty();
    }

    final uid = _currentUser!.uid;

    // -------- 1–1 CHATS --------
    final oneToOneChats = _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final futures = snapshot.docs.map((doc) async {
        try {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? []);

          if (participants.length < 2) return null;

          final otherUserId = participants.firstWhere((id) => id != uid, orElse: () => '');
          if (otherUserId.isEmpty) return null;

          final userDoc = await _db.collection('users').doc(otherUserId).get();
          if (!userDoc.exists || userDoc.data() == null) return null;

          final otherUser = AppUser.fromMap(userDoc.data()!, userDoc.id);

          final lastMessageSnap = await doc.reference.collection('messages').orderBy('timestamp', descending: true).limit(1).get();

          final lastMessage = lastMessageSnap.docs.isNotEmpty ? lastMessageSnap.docs.first.data()['text'] ?? 'Media' : 'No messages yet';

          final timestamp = lastMessageSnap.docs.isNotEmpty ? lastMessageSnap.docs.first.data()['timestamp'] as Timestamp? ?? Timestamp.now() : Timestamp.now();

          return Conversation(
            id: doc.id,
            name: otherUser.displayName ?? otherUser.email ?? 'Chat',
            imageUrl: otherUser.photoUrl,
            lastMessage: lastMessage,
            timestamp: timestamp,
            type: ConversationType.oneToOne,
            otherUser: otherUser,
          );
        } catch (e) {
          if (kDebugMode) {
            print("Error processing one-to-one chat ${doc.id}: $e");
          }
          return null;
        }
      });

      final results = await Future.wait(futures);
      return results.whereType<Conversation>().toList();
    });

    // -------- GROUP CHATS --------
    final groupChats = _db
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final futures = snapshot.docs.map((doc) async {
        try {
          final group = group_model.Group.fromMap(doc.data(), doc.id);

          final lastMessageSnap = await doc.reference.collection('messages').orderBy('timestamp', descending: true).limit(1).get();

          final lastMessage = lastMessageSnap.docs.isNotEmpty ? lastMessageSnap.docs.first.data()['text'] ?? 'Media' : 'No messages yet';

          final timestamp = lastMessageSnap.docs.isNotEmpty ? lastMessageSnap.docs.first.data()['timestamp'] as Timestamp? ?? Timestamp.fromDate(group.createdAt) : Timestamp.fromDate(group.createdAt);

          return Conversation(
            id: doc.id,
            name: group.name,
            imageUrl: group.groupImageUrl,
            lastMessage: lastMessage,
            timestamp: timestamp,
            type: ConversationType.group,
            group: group,
          );
        } catch (e) {
          if (kDebugMode) {
            print("Error processing group chat ${doc.id}: $e");
          }
          return null;
        }
      });

      final results = await Future.wait(futures);
      return results.whereType<Conversation>().toList();
    });

    // -------- MERGE & SORT --------
    return Rx.combineLatest2(
      oneToOneChats,
      groupChats,
          (List<Conversation> a, List<Conversation> b) {
        final all = [...a, ...b];
        all.sort((x, y) => y.timestamp.compareTo(x.timestamp));
        return all;
      },
    );
  }

  // ---------------- REACTIONS ----------------

  Future<void> toggleMessageReaction({
    required String messageId,
    required String chatId,
    required String emoji,
    required bool isGroupChat,
  }) async {
    if (_currentUser == null) return;
    final uid = _currentUser!.uid;

    final collectionPath = isGroupChat ? 'groups' : 'chats';
    final docRef = _db.collection(collectionPath).doc(chatId).collection('messages').doc(messageId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception("Message does not exist!");
      }

      final data = snapshot.data()!;
      final reactions = Map<String, String>.from(data['reactions'] ?? {});

      if (reactions.containsKey(uid) && reactions[uid] == emoji) {
        // User is removing their reaction
        reactions.remove(uid);
      } else {
        // User is adding or changing their reaction
        reactions[uid] = emoji;
      }

      transaction.update(docRef, {'reactions': reactions});
    });
  }
}
