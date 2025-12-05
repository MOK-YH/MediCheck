import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) return doc.data();
    return null;
  }

  Future<Map<String, dynamic>> _fetchMedicationStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {"avgRate": 0.0, "taken": 0, "total": 0};

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    int takenCount = 0;
    int totalCount = 0;

    // 최근 7일 데이터 불러오기
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dateId = "${day.year}-${day.month}-${day.day}";
      final doc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('schedules')
          .doc(dateId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        for (var meal in ['morning', 'lunch', 'dinner']) {
          if (data[meal]['time'] != '미설정' && data[meal]['name'] != '') {
            totalCount++;
            if (data[meal]['taken'] == true) takenCount++;
          }
        }
      }
    }

    final avgRate =
        totalCount == 0 ? 0.0 : (takenCount / totalCount * 100.0).toDouble();

    return {"avgRate": avgRate, "taken": takenCount, "total": totalCount};
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그아웃되었습니다.')),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F7),
      appBar: AppBar(
        title: const Text('프로필'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text("사용자 정보를 불러올 수 없습니다."));
          }

          final userData = userSnapshot.data!;
          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchMedicationStats(),
            builder: (context, statSnapshot) {
              if (statSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final stats = statSnapshot.data ?? {};
              final avgRate = stats['avgRate'] ?? 0.0;
              final taken = stats['taken'] ?? 0;
              final total = stats['total'] ?? 0;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Icon(Icons.account_circle,
                      size: 90, color: Colors.blueAccent),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      userData['name'] ?? '이름 없음',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Center(
                    child: Text(
                      userData['email'] ?? '이메일 없음',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),

                  // 기본 정보
                  const Text("👤 기본 정보",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  _buildInfoRow("생년월일", userData['birth']),
                  _buildInfoRow("진단명", userData['diagnosis']),
                  _buildInfoRow("보호자 이름", userData['guardian']),
                  _buildInfoRow("가입일", userData['created_at']),

                  const Divider(height: 30, thickness: 1),

                  // 복약 통계
                  const Text("📊 복약 통계 요약",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      "최근 7일 평균 복용률", "${avgRate.toStringAsFixed(1)}%"),
                  _buildInfoRow("총 복용 완료", "$taken회 / $total회"),

                  const SizedBox(height: 40),

                  // 로그아웃 버튼
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _signOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text(
                        '로그아웃',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    String displayValue = '';
    if (value == null) {
      displayValue = '정보 없음';
    } else if (value is Timestamp) {
      displayValue = DateFormat('yyyy-MM-dd').format(value.toDate());
    } else {
      displayValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Text(displayValue,
              style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}
