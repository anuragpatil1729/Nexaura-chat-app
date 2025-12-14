
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid;

  PresenceService(this._uid) {
    WidgetsBinding.instance.addObserver(this);
    _updateStatus('online');
  }

  void dispose() {
    _updateStatus('offline');
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus('online');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _updateStatus('offline');
    }
  }

  Future<void> _updateStatus(String status) async {
    await _db.collection('presence').doc(_uid).set({
      'status': status,
      'last_seen': FieldValue.serverTimestamp(),
    });
  }
}
