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
  Map<String, dynamic>? _selectedSchedule;

  @override
  void initState() {
    super.initState();
    _loadSchedule(_selectedDay);
  }

  Future<void> _loadSchedule(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateId = "${date.year}-${date.month}-${date.day}";
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(dateId)
        .get();

    setState(() {
      _selectedSchedule = doc.exists ? doc.data() : null;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedSchedule = null;
    });
    await _loadSchedule(selectedDay);
  }

  void _createNewSchedule() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final dateId = "${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}";

    // 기본 템플릿 일정 생성
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(dateId)
        .set({
      "morning": {"time": "미설정", "name": "", "taken": false},
      "lunch": {"time": "미설정", "name": "", "taken": false},
      "dinner": {"time": "미설정", "name": "", "taken": false},
    });

    await _loadSchedule(_selectedDay);
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
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            calendarFormat: CalendarFormat.month,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _selectedSchedule == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("등록된 일정이 없습니다.",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade600)),
                          const SizedBox(height: 15),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("새 일정 추가"),
                            onPressed: _createNewSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
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
                              "📅 선택된 날짜 일정",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _buildScheduleRow("아침", _selectedSchedule?['morning']),
                            _buildScheduleRow("점심", _selectedSchedule?['lunch']),
                            _buildScheduleRow("저녁", _selectedSchedule?['dinner']),
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
                                  ).then((_) => _loadSchedule(_selectedDay));
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
