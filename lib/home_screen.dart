import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic>? todaySchedule;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null).then((_) {
      _loadTodaySchedule();
    });
  }

  Future<void> _loadTodaySchedule() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final todayId = DateFormat('yyyy-M-d').format(DateTime.now());
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(todayId);

    final doc = await docRef.get();
    if (doc.exists) {
      setState(() {
        todaySchedule = doc.data();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(DateTime.now());
    final morning = todaySchedule?['morning'];
    final lunch = todaySchedule?['lunch'];
    final dinner = todaySchedule?['dinner'];

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
        child: todaySchedule == null
            ? const Center(
                child: Text(
                  '오늘 등록된 일정이 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📅 오늘 | $today',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ✅ 카드 영역 — 공백 없이 균등 분할
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: _buildScheduleCard('아침', morning, 'morning')),
                        Expanded(child: _buildScheduleCard('점심', lunch, 'lunch')),
                        Expanded(child: _buildScheduleCard('저녁', dinner, 'dinner')),
                      ],
                    ),
                  ),

                  const Divider(thickness: 1),
                  const SizedBox(height: 4),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '총 $takenCount / 3 복용 완료',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            bool filled = i < takenCount;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.medication_rounded,
                                color: filled ? Colors.blue : Colors.grey[400],
                                size: 28,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildScheduleCard(
      String title, Map<String, dynamic>? data, String period) {
    final time = data?['time'] ?? '미설정';
    final name = data?['name'] ?? '-';
    final taken = data?['taken'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: taken ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽 텍스트
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('⏰ $time', style: const TextStyle(fontSize: 16)),
              Text('💊 $name', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                taken ? '✅ 복용 완료' : '❌ 미복용',
                style: TextStyle(
                  color: taken ? Colors.green[700] : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // 오른쪽 복용 버튼
          ElevatedButton.icon(
            onPressed: () => _markAsTaken(period),
            icon: const Icon(Icons.camera_alt, size: 18),
            label: Text(
              taken ? '다시 확인' : '복용 확인',
              style: const TextStyle(fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: taken ? Colors.green : Colors.blue,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(115, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsTaken(String period) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || todaySchedule == null) return;

    final todayId = DateFormat('yyyy-M-d').format(DateTime.now());
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(todayId);

    final current = todaySchedule?[period] ?? {};
    final bool newTaken = !(current['taken'] ?? false);

    await docRef.set({
      period: {
        ...current,
        'taken': newTaken,
      },
    }, SetOptions(merge: true));

    setState(() {
      todaySchedule?[period]['taken'] = newTaken;
    });
  }
}
