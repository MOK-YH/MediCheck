import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DateTime _selectedWeek = DateTime.now();
  Map<String, double> _weeklyCounts = {};   // 🔥 요일별 '횟수' 저장
  double _averageRate = 0.0;                // 🔥 평균 복약률 (%)

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  /// 주차 계산
  int weekOfMonth(DateTime date) {
    int firstDay = DateTime(date.year, date.month, 1).weekday;
    return ((date.day + firstDay - 1) / 7).ceil();
  }

  /// Firestore에서 해당 주차 데이터 로드
  Future<void> _loadWeeklyData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // 월요일 기준 주간 날짜 생성
    DateTime monday =
        _selectedWeek.subtract(Duration(days: _selectedWeek.weekday - 1));
    List<DateTime> weekDays =
        List.generate(7, (i) => monday.add(Duration(days: i)));

    Map<String, double> tempCounts = {};
    double totalRate = 0;
    int validDays = 0;

    for (var day in weekDays) {
      String dateId = "${day.year}-${day.month}-${day.day}";
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('schedules')
          .doc(dateId)
          .get();

      String weekday = DateFormat('E', 'ko_KR').format(day);

      if (doc.exists && doc.data() != null) {
        var data = doc.data()!;
        int taken = 0;
        int total = 0;

        for (var meal in ['morning', 'lunch', 'dinner']) {
          if (data[meal]['time'] != '미설정' && data[meal]['name'] != '') {
            total++;
            if (data[meal]['taken'] == true) taken++;
          }
        }

        // 🔥 그래프는 "횟수" 저장
        tempCounts[weekday] = taken.toDouble();

        // 🔥 평균은 기존대로 "복용률"로 계산
        totalRate += total > 0 ? taken / total : 0;
        if (total > 0) validDays++;
      } else {
        tempCounts[weekday] = 0;
      }
    }

    setState(() {
      _weeklyCounts = tempCounts;
      _averageRate = validDays > 0 ? (totalRate / validDays) * 100 : 0;
    });
  }

  void _goToPreviousWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
    });
    _loadWeeklyData();
  }

  void _goToNextWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.add(const Duration(days: 7));
    });
    _loadWeeklyData();
  }

  @override
  Widget build(BuildContext context) {
    List<String> weekDaysOrder = ['월', '화', '수', '목', '금', '토', '일'];

    // 🔥 요일 순서대로 횟수 배열 생성
    List<double> chartValues = weekDaysOrder.map((d) {
      return _weeklyCounts[d] ?? 0.0;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('복약 리포트'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 주차 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: _goToPreviousWeek,
                    icon: const Icon(Icons.arrow_left)),
                Text(
                  "${_selectedWeek.month}월 ${weekOfMonth(_selectedWeek)}주차",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: _goToNextWeek,
                    icon: const Icon(Icons.arrow_right)),
              ],
            ),

            const SizedBox(height: 10),

            // 🔹 주간 평균 복용률
            Row(
              children: const [
                Icon(Icons.calendar_today, color: Colors.red),
                SizedBox(width: 5),
                Text('주간 평균 복용률',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text("${_averageRate.toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 28, color: Colors.blue)),
            const SizedBox(height: 20),

            // 🔹 막대그래프
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData:
                      FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < weekDaysOrder.length) {
                            return Text(weekDaysOrder[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),

                  // 🔥 그래프에 '횟수' 그대로 표시
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: chartValues[i],
                          color: Colors.blue,
                          width: 18,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const Divider(height: 30, thickness: 1),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('💬 AI 복약 습관 분석',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            const Text(
              '이번 주에는 점심 시간 복용이 다소 누락되었습니다. 알림 시간을 조정해보세요.',
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
