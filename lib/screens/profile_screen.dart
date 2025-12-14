import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexaaura/models/user_model.dart';
import 'package:nexaaura/services/firestore_service.dart';
import 'package:nexaaura/services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;

  bool _isEditing = false;
  File? _newImage;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.user.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ---------------- PICK IMAGE ----------------
  Future<void> _pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _newImage = File(image.path);
    });
  }

  // ---------------- SAVE PROFILE ----------------
  Future<void> _saveProfile() async {
    String? photoUrl = widget.user.photoUrl;

    if (_newImage != null) {
      photoUrl = await _storageService.uploadImage(_newImage!);
    }

    final updatedUser = AppUser(
      uid: widget.user.uid,
      email: widget.user.email,
      displayName: _nameController.text.trim(),
      photoUrl: photoUrl,
    );

    await _firestoreService.updateUser(updatedUser);

    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser =
        currentUser != null && widget.user.uid == currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _buildProfileImage(),
                child: _buildAvatarOverlay(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Email: ${widget.user.email}'),
            const SizedBox(height: 10),
            _isEditing
                ? TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
              ),
            )
                : Text(
              'Display Name: ${widget.user.displayName ?? ''}',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- IMAGE HELPERS ----------------
  ImageProvider? _buildProfileImage() {
    if (_newImage != null) {
      return FileImage(_newImage!);
    }
    if (widget.user.photoUrl != null &&
        widget.user.photoUrl!.isNotEmpty) {
      return NetworkImage(widget.user.photoUrl!);
    }
    return null;
  }

  Widget? _buildAvatarOverlay() {
    if (_newImage == null && widget.user.photoUrl == null) {
      return const Icon(Icons.person, size: 50);
    }
    if (_isEditing) {
      return const Icon(Icons.camera_alt, size: 30);
    }
    return null;
  }
}