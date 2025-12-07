import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/network_helper.dart';

class ScheduleSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<StreamSubscription> _listeners = []; // ✅ 여러 문서 리스너 관리
  bool _initialSyncDone = false;

  /// ⭐ 날짜 포맷(YYYY-M-D → YYYY-MM-DD) 변환 함수 추가
  String _formatDateId(String id) {
    final parts = id.split('-');
    if (parts.length != 3) return id;

    final y = parts[0];
    final m = parts[1].padLeft(2, '0');
    final d = parts[2].padLeft(2, '0');

    return "$y-$m-$d";
  }

  /// ✅ Timestamp, Map, List 변환
  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _normalizeValue(v)));
    } else if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  /// 🔹 Firestore → Flask 실시간 감시
  Future<void> startListening() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint("⚠️ [ScheduleSync] 로그인된 사용자가 없습니다.");
      return;
    }

    debugPrint("🔄 [ScheduleSync] Firestore 일정 감시 시작 (uid: $uid)");

    final schedulesRef =
        _firestore.collection('users').doc(uid).collection('schedules');

    // ✅ 전체 문서 가져와 각각 리스너 등록
    final docs = await schedulesRef.get();
    for (var doc in docs.docs) {
      _listenToDocument(uid, schedulesRef.doc(doc.id));
    }

    // ✅ 새 날짜 문서가 추가되면 리스너 추가
    _listeners.add(schedulesRef.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _listenToDocument(uid, schedulesRef.doc(change.doc.id));
        }
      }
    }));
  }

  /// 🔹 개별 문서 리스너
  void _listenToDocument(String uid, DocumentReference docRef) {
    final sub = docRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final normalized = _normalizeValue(data);

      /// ⭐ 날짜 포맷 적용
      final formattedId = _formatDateId(snapshot.id);

      debugPrint("📡 Firestore 문서 변경 감지됨 → ${snapshot.id}");
      debugPrint("🚀 Flask 전송 시도 → $formattedId, data: $normalized");

      /// ⭐ 기존 snapshot.id → formattedId 로 변경
      NetworkHelper.sendScheduleToFlask(uid, formattedId, normalized);

    }, onError: (e) {
      debugPrint("💥 [ScheduleSync] 문서 리스너 오류 (${docRef.id}): $e");
    });

    _listeners.add(sub);
  }

  /// 🔹 자정 전체 동기화
  void scheduleDailyFullSync() {
    Timer.periodic(const Duration(hours: 1), (timer) async {
      final now = DateTime.now();
      if (now.hour == 0 && now.minute < 5) {
        debugPrint("🕛 [ScheduleSync] 자정 Full Sync 실행 중...");
        await sendAllSchedules();
      }
    });
  }

  /// 🔹 전체 문서 Flask로 전송
  Future<void> sendAllSchedules() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint("⚠️ [ScheduleSync] 로그인되지 않음. Full Sync 불가.");
      return;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .get();

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        final normalized = _normalizeValue(data);

        /// ⭐ 날짜 포맷 적용
        final formattedId = _formatDateId(doc.id);

        debugPrint("📤 [ScheduleSync] Full Sync → $formattedId");

        /// ⭐ 기존 doc.id → formattedId
        await NetworkHelper.sendScheduleToFlask(uid, formattedId, normalized);

      } catch (e) {
        debugPrint("❌ [ScheduleSync] Full Sync 중 오류: $e");
      }
    }
  }

  /// 🔹 리스너 해제
  void dispose() {
    for (var sub in _listeners) {
      sub.cancel();
    }
    _listeners.clear();
    debugPrint("🛑 [ScheduleSync] Firestore 감시 종료");
  }
}
