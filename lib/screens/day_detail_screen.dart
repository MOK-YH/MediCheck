import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime selectedDay;
  const DayDetailScreen({super.key, required this.selectedDay});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final TextEditingController _morningController = TextEditingController();
  final TextEditingController _lunchController = TextEditingController();
  final TextEditingController _dinnerController = TextEditingController();

  TimeOfDay? _morningTime;
  TimeOfDay? _lunchTime;
  TimeOfDay? _dinnerTime;

  // ✅ 페이지 진입 시 Firestore에서 기존 데이터 불러오기
  @override
  void initState() {
    super.initState();
    _loadExistingSchedule();
  }

  Future<void> _loadExistingSchedule() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateId =
        "${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}";

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(dateId);

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      setState(() {
        // 시간 값 불러오기
        final morningTimeStr = data['morning']?['time'];
        final lunchTimeStr = data['lunch']?['time'];
        final dinnerTimeStr = data['dinner']?['time'];

        _morningTime = _parseTime(morningTimeStr);
        _lunchTime = _parseTime(lunchTimeStr);
        _dinnerTime = _parseTime(dinnerTimeStr);

        // 약 종류 불러오기
        _morningController.text = data['morning']?['name'] ?? '';
        _lunchController.text = data['lunch']?['name'] ?? '';
        _dinnerController.text = data['dinner']?['name'] ?? '';
      });
    }
  }

  // ✅ "8:30 AM" 같은 문자열을 TimeOfDay로 변환하는 헬퍼
  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr == '미설정') return null;
    try {
      final format = TimeOfDayFormat.h_colon_mm_space_a;
      final time = TimeOfDay(
        hour: int.parse(timeStr.split(':')[0]),
        minute: int.parse(timeStr.split(':')[1].split(' ')[0]),
      );
      return time;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickTime(String period) async {
    TimeOfDay? selected;
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        int selectedHour = 8;
        int selectedMinute = 0;
        bool isUnset = false;

        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text('시간 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: 8),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      if (index == 0) {
                        setModalState(() => isUnset = true);
                      } else {
                        setModalState(() {
                          isUnset = false;
                          selectedHour = (index - 1) ~/ 2;
                          selectedMinute = ((index - 1) % 2) * 30;
                        });
                      }
                    },
                    children: [
                      const Center(child: Text('미설정')),
                      for (int h = 0; h < 24; h++)
                        for (int m in [0, 30])
                          Center(child: Text('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}')),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!isUnset) {
                      selected = TimeOfDay(hour: selectedHour, minute: selectedMinute);
                      setState(() {
                        if (period == 'morning') _morningTime = selected;
                        if (period == 'lunch') _lunchTime = selected;
                        if (period == 'dinner') _dinnerTime = selected;
                      });
                    } else {
                      setState(() {
                        if (period == 'morning') _morningTime = null;
                        if (period == 'lunch') _lunchTime = null;
                        if (period == 'dinner') _dinnerTime = null;
                      });
                    }
                  },
                  child: const Text('확인', style: TextStyle(color: Colors.blue, fontSize: 16)),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ✅ 병합 저장 적용 (기존 데이터 유지)
  Future<void> _saveSchedule() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateId =
        "${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}";

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(dateId)
        .set({
      'morning': {
        'time': _morningTime == null ? '미설정' : _morningTime!.format(context),
        'name': _morningController.text.trim(),
      },
      'lunch': {
        'time': _lunchTime == null ? '미설정' : _lunchTime!.format(context),
        'name': _lunchController.text.trim(),
      },
      'dinner': {
        'time': _dinnerTime == null ? '미설정' : _dinnerTime!.format(context),
        'name': _dinnerController.text.trim(),
      },
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // ✅ 기존 데이터와 병합

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('일정이 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateId =
        "${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}";
    return Scaffold(
      appBar: AppBar(
        title: Text('세부 일정 - $dateId'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '복용 시간과 약 종류를 등록하세요',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          _buildTimeBlock('아침', 'morning', _morningTime, _morningController),
          const Divider(),
          _buildTimeBlock('점심', 'lunch', _lunchTime, _lunchController),
          const Divider(),
          _buildTimeBlock('저녁', 'dinner', _dinnerTime, _dinnerController),

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('저장하기', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlock(String title, String key, TimeOfDay? time, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                time == null ? '미설정' : time.format(context),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => _pickTime(key),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('시간 선택'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '약 종류',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
