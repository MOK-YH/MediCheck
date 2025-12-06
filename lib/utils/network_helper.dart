import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NetworkHelper {
  // ✅ Flask 서버 주소 (Tailscale IP 고정)
  static const String _baseUrl = 'http://100.72.23.91:8000/api/schedule';

  /// ✅ Firestore Timestamp, Map, List 등 직렬화 변환
  static dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k, _normalizeValue(v)));
    } else if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  /// ✅ Flask 서버로 일정 데이터 전송
  static Future<void> sendScheduleToFlask(
      String uid, String dateId, Map<String, dynamic> scheduleData) async {
    try {
      final url = Uri.parse(_baseUrl);
      final normalized = _normalizeValue(scheduleData);

      final payload = {
        'uid': uid,
        'date': dateId,
        'schedule': normalized,
      };

      debugPrint('🚀 Flask 전송 시도 → $url');
      debugPrint('📦 Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('✅ Flask 서버 전송 성공 (${response.statusCode})');
      } else {
        debugPrint('⚠️ Flask 서버 응답 오류 (${response.statusCode}): ${response.body}');
      }
    } on TimeoutException {
      debugPrint('⏱ Flask 서버 응답 시간 초과 (10초)');
    } catch (e) {
      debugPrint('❌ Flask 서버 전송 실패: $e');
    }
  }
}
