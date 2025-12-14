
import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final List<String> members;
  final String? groupImageUrl;
  final String createdBy;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.members,
    this.groupImageUrl,
    required this.createdBy,
    required this.createdAt,
  });

  factory Group.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now();
    }

    return Group(
      id: documentId,
      name: data['name'] ?? 'Unnamed Group',
      members: List<String>.from(data['members'] ?? []),
      groupImageUrl: data['groupImageUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': members,
      'groupImageUrl': groupImageUrl,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
