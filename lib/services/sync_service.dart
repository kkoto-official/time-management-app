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

  // Firebase → ローカル SQLite に未保存レコードを取り込む
  // 戻り値: 新規挿入件数
  static Future<int> downloadAndMerge() async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) {
        debugPrint('[SyncService] downloadAndMerge: not logged in, skip');
        return 0;
      }

      final snap = await _fs
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .get();

      if (snap.docs.isEmpty) return 0;
      debugPrint('[SyncService] firebase records: ${snap.docs.length}');

      final localRecords = await LocalDb.getAll();
      // activityId + startedAt で重複チェック
      final localKeys = localRecords
          .map((r) => '${r.activityId}_${r.startedAt}')
          .toSet();

      int inserted = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final ts = data['startedAt'];
        final startedAt = ts is int ? ts : (ts as dynamic).millisecondsSinceEpoch as int;
        final activityId = data['activityId'] as String;

        if (!localKeys.contains('${activityId}_$startedAt')) {
          await LocalDb.insert(SessionRecord(
            activityId: activityId,
            activityLabel: data['activityLabel'] as String,
            durationSeconds: data['durationSeconds'] as int,
            date: data['date'] as String,
            startedAt: startedAt,
            synced: true,
          ));
          inserted++;
        }
      }

      debugPrint('[SyncService] downloadAndMerge: inserted $inserted new records');
      return inserted;
    } catch (e, st) {
      debugPrint('[SyncService] downloadAndMerge failed: $e\n$st');
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
