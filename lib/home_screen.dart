import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'alarm_screen.dart';
import 'services/schedule_sync_service.dart'; // ✅ 추가

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ✅ 동기화 서비스 인스턴스 추가
  final ScheduleSyncService _syncService = ScheduleSyncService();

  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _scheduleData;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null).then((_) {
      _loadSchedule();                   // 일정 불러오기
      _syncService.startListening();     // ✅ Firestore 실시간 감시 시작
      _syncService.scheduleDailyFullSync(); // ✅ 00시 자동 전송
    });
  }

  /// ✅ 앱 종료 시 리스너 해제
  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  /// 🔹 선택된 날짜 기준 Firestore 일정 불러오기
  Future<void> _loadSchedule() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateId = DateFormat('yyyy-M-d').format(_selectedDate);
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(dateId);

    final doc = await docRef.get();
    setState(() {
      _scheduleData = doc.exists ? doc.data() : null;
    });
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadSchedule();
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadSchedule();
  }

  /// 🔹 복용 완료/해제 토글
  Future<void> _markAsTaken(String period) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _scheduleData == null) return;

    final dateId = DateFormat('yyyy-M-d').format(_selectedDate);
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(dateId);

    final current = _scheduleData?[period] ?? {};
    final bool newTaken = !(current['taken'] ?? false);

    await docRef.set({
      period: {...current, 'taken': newTaken},
    }, SetOptions(merge: true));

    setState(() {
      _scheduleData?[period]['taken'] = newTaken;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_selectedDate);

    final morning = _scheduleData?['morning'];
    final lunch = _scheduleData?['lunch'];
    final dinner = _scheduleData?['dinner'];

    int takenCount = 0;
    if (morning?['taken'] == true) takenCount++;
    if (lunch?['taken'] == true) takenCount++;
    if (dinner?['taken'] == true) takenCount++;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediCheck'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlarmScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 날짜 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: _goToPreviousDay,
                    icon: const Icon(Icons.arrow_left, size: 28)),
                Text(formattedDate,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: _goToNextDay,
                    icon: const Icon(Icons.arrow_right, size: 28)),
              ],
            ),
            const SizedBox(height: 10),

            _scheduleData == null
                ? Expanded(
                    child: Center(
                        child: Text('등록된 일정이 없습니다.',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade600))),
                  )
                : Expanded(
                    child: Column(
                      children: [
                        Expanded(
                            child: _buildScheduleCard('아침', morning, 'morning')),
                        Expanded(
                            child: _buildScheduleCard('점심', lunch, 'lunch')),
                        Expanded(
                            child: _buildScheduleCard('저녁', dinner, 'dinner')),
                        const Divider(thickness: 1),
                        const SizedBox(height: 4),
                        Text('총 $takenCount / 3 복용 완료',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (i) {
                              bool filled = i < takenCount;
                              return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.medication_rounded,
                                      color: filled
                                          ? Colors.blue
                                          : Colors.grey[400],
                                      size: 28));
                            })),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// 🔹 복용 카드 (시간 제한 + 날짜 제한 포함)
  Widget _buildScheduleCard(
      String title, Map<String, dynamic>? data, String period) {
    final time = data?['time'] ?? '미설정';
    final name = data?['name'] ?? '-';
    final taken = data?['taken'] ?? false;

    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final isFuture = _selectedDate.isAfter(now);
    final isPast = _selectedDate.isBefore(now);

    // 🔹 시간 파싱 (AM/PM 또는 24시간 형식 모두 처리)
    DateTime? scheduledTime;
    if (time != '미설정' && time.isNotEmpty) {
      try {
        final parsed = DateFormat('h:mm a').parseLoose(time);
        scheduledTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          parsed.hour,
          parsed.minute,
        );
      } catch (_) {
        try {
          final parts = time.split(':');
          scheduledTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } catch (_) {}
      }
    }

    // 🔹 현재 시간이 복용 시간 이후인지 여부
    bool isAfterTime = false;
    if (isToday && scheduledTime != null) {
      isAfterTime = now.isAfter(scheduledTime);
    }

    // 🔹 버튼 상태 결정
    String buttonText = '';
    Color buttonColor = Colors.grey;
    bool enabled = false;

    if (isFuture) {
      buttonText = '미래 일정';
    } else if (isPast && !isToday) {
      buttonText = '지난 일정';
    } else if (isToday && !isAfterTime) {
      buttonText = '시간 전';
    } else if (taken) {
      buttonText = '다시 확인';
      buttonColor = Colors.green;
      enabled = true;
    } else {
      buttonText = '복용 확인';
      buttonColor = Colors.blue;
      enabled = true;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: taken ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 텍스트
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('⏰ $time', style: const TextStyle(fontSize: 16)),
              Text('💊 $name', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 6),
              Text(taken ? '✅ 복용 완료' : '❌ 미복용',
                  style: TextStyle(
                      color: taken ? Colors.green[700] : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ],
          ),

          // 오른쪽 버튼
          ElevatedButton.icon(
            onPressed: enabled ? () => _markAsTaken(period) : null,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: Text(buttonText, style: const TextStyle(fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(115, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
