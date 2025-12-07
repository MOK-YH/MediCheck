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
        _morningTime = _parseTime(data['morning']?['time']);
        _lunchTime = _parseTime(data['lunch']?['time']);
        _dinnerTime = _parseTime(data['dinner']?['time']);

        _morningController.text = data['morning']?['name'] ?? '';
        _lunchController.text = data['lunch']?['name'] ?? '';
        _dinnerController.text = data['dinner']?['name'] ?? '';
      });
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr == '미설정') return null;
    try {
      final parts = timeStr.split(" ");
      final hm = parts[0].split(":");
      int hour = int.parse(hm[0]);
      int minute = int.parse(hm[1]);

      if (parts[1] == "PM" && hour != 12) hour += 12;
      if (parts[1] == "AM" && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickTime(String period) async {
    final hourController = TextEditingController();
    final minuteController = TextEditingController(text: "00");
    String ampm = "AM";

    TimeOfDay? current;
    if (period == 'morning') current = _morningTime;
    if (period == 'lunch') current = _lunchTime;
    if (period == 'dinner') current = _dinnerTime;

    if (current != null) {
      int displayHour = current.hour % 12;
      if (displayHour == 0) displayHour = 12;
      hourController.text = displayHour.toString();
      minuteController.text = current.minute.toString().padLeft(2, "0");
      ampm = current.hour >= 12 ? "PM" : "AM";
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, top: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("시간 입력",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // 입력 UI
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: hourController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "시"),
                      ),
                    ),
                    const Text(":", style: TextStyle(fontSize: 22)),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: minuteController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "분"),
                      ),
                    ),
                    DropdownButton<String>(
                      value: ampm,
                      items: const [
                        DropdownMenuItem(value: "AM", child: Text("AM")),
                        DropdownMenuItem(value: "PM", child: Text("PM")),
                      ],
                      onChanged: (v) {
                        setState(() => ampm = v!);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      int h = int.tryParse(hourController.text) ?? 0;
                      int m = int.tryParse(minuteController.text) ?? 0;

                      if (h < 1 || h > 12 || m < 0 || m > 59) {
                        Navigator.pop(context);
                        return;
                      }

                      if (ampm == "PM" && h != 12) h += 12;
                      if (ampm == "AM" && h == 12) h = 0;

                      TimeOfDay selected = TimeOfDay(hour: h, minute: m);

                      setState(() {
                        if (period == 'morning') _morningTime = selected;
                        if (period == 'lunch') _lunchTime = selected;
                        if (period == 'dinner') _dinnerTime = selected;
                      });

                      Navigator.pop(context);
                    },
                    child: const Text("확인"),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveSchedule() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateId =
        "${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}";

    String format(TimeOfDay? t) {
      if (t == null) return "미설정";
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final minute = t.minute.toString().padLeft(2, '0');
      final ampm = t.period == DayPeriod.am ? "AM" : "PM";
      return "$hour:$minute $ampm";
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .doc(dateId)
        .set({
      'morning': {
        'time': format(_morningTime),
        'name': _morningController.text.trim(),
      },
      'lunch': {
        'time': format(_lunchTime),
        'name': _lunchController.text.trim(),
      },
      'dinner': {
        'time': format(_dinnerTime),
        'name': _dinnerController.text.trim(),
      },
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

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
          const Text('복용 시간과 약 종류를 등록하세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('저장하기',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlock(String title, String key, TimeOfDay? time,
      TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                time == null ? '미설정' : _formatDisplayTime(time),
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

  String _formatDisplayTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, "0");
    final ap = t.period == DayPeriod.am ? "AM" : "PM";
    return "$h:$m $ap";
  }
}
