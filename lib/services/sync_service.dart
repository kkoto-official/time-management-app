import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'local_db.dart';

class SyncService {
  static final _fs = FirebaseFirestore.instance;

  static Future<int> uploadUnsynced() async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) {
        debugPrint('[SyncService] uid == null: not logged in, skip upload');
        return 0;
      }

      final records = await LocalDb.getUnsynced();
      debugPrint('[SyncService] unsynced records: ${records.length}');
      if (records.isEmpty) return 0;

      final batch = _fs.batch();
      for (final r in records) {
        final ref = _fs.collection('users').doc(uid).collection('sessions').doc();
        batch.set(ref, {
          'activityId': r.activityId,
          'activityLabel': r.activityLabel,
          'durationSeconds': r.durationSeconds,
          'date': r.date,
          'startedAt': Timestamp.fromMillisecondsSinceEpoch(r.startedAt),
        });
      }
      await batch.commit();
      debugPrint('[SyncService] batch committed: ${records.length} records');

      final ids = records.map((r) => r.id!).toList();
      await LocalDb.markSynced(ids);
      debugPrint('[SyncService] marked synced: $ids');
      return records.length;
    } catch (e, st) {
      debugPrint('[SyncService] upload failed: $e');
      debugPrint('[SyncService] $st');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAll() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _fs
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('startedAt', descending: true)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }
}
