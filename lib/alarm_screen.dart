import 'package:flutter/material.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('복약 알림'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          '오늘의 복약 알림 없음',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
