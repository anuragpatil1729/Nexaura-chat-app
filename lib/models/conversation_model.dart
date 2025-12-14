
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexaaura/models/group_model.dart' as group_model;
import 'package:nexaaura/models/user_model.dart';

enum ConversationType { oneToOne, group }

class Conversation {
  final String id;
  final String name;
  final String? imageUrl;
  final String lastMessage;
  final Timestamp timestamp;
  final ConversationType type;
  final AppUser? otherUser; // For one-to-one chats
  final group_model.Group? group; // For group chats

  Conversation({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.lastMessage,
    required this.timestamp,
    required this.type,
    this.otherUser,
    this.group,
  });
}
