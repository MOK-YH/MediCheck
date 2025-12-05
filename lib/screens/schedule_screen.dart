import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'day_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<String, dynamic>? _todaySchedule; // Firestore에서 불러온 일정 저장용

  @override
  void initState() {
    super.initState();
    _loadTodaySchedule();
  }

  Future<void> _loadTodaySchedule() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateId =
        "${_focusedDay.year}-${_focusedDay.month}-${_focusedDay.day}";

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(dateId)
        .get();

    if (doc.exists) {
      setState(() {
        _todaySchedule = doc.data();
      });
    } else {
      setState(() {
        _todaySchedule = null;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _todaySchedule = null; // 초기화 후 다시 로드
    });
    await _loadTodaySchedule();
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        "${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 관리'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // 🗓 달력 전체 보기
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            calendarFormat: CalendarFormat.month, // ✅ 한 달 보기로 확대
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),

          const SizedBox(height: 10),
          Text(
            "선택된 날짜: $dateText",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),

          const SizedBox(height: 10),

          // 🗒 오늘 일정 카드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _todaySchedule == null
                  ? Center(
                      child: Text(
                        "등록된 일정이 없습니다.",
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600),
                      ),
                    )
                  : Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "🗓 오늘 일정",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _buildScheduleRow("아침", _todaySchedule?['morning']),
                            _buildScheduleRow("점심", _todaySchedule?['lunch']),
                            _buildScheduleRow("저녁", _todaySchedule?['dinner']),
                            const Spacer(),
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text(
                                  "세부 일정 수정",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 12),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DayDetailScreen(selectedDay: _selectedDay),
                                    ),
                                  ).then((_) => _loadTodaySchedule());
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, Map<String, dynamic>? data) {
    final name = data?['name'] ?? '미설정';
    final time = data?['time'] ?? '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text("$time | $name",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
