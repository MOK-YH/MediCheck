import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Firebase 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 입력 필드 컨트롤러
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _guardianController = TextEditingController();

  bool _isLoading = false;

  // 회원가입 함수
  Future<void> _registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final birth = _birthController.text.trim();
    final diagnosis = _diagnosisController.text.trim();
    final guardian = _guardianController.text.trim();

    // 입력값 검증
    if (email.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        birth.isEmpty ||
        diagnosis.isEmpty ||
        guardian.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Firebase Authentication: 이메일로 회원 생성
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2️⃣ Firestore에 사용자 정보 저장
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'birth': birth,
        'diagnosis': diagnosis,
        'guardian': guardian,
        'created_at': FieldValue.serverTimestamp(),
        'provider': 'email',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 완료!')),
      );

      // 🔹 입력창 초기화
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _birthController.clear();
      _diagnosisController.clear();
      _guardianController.clear();

      // 🔹 자동으로 홈화면으로 전환은 main.dart의 AuthWrapper에서 처리됨
    } on FirebaseAuthException catch (e) {
      String message = '회원가입 실패';
      if (e.code == 'email-already-in-use') {
        message = '이미 등록된 이메일입니다.';
      } else if (e.code == 'weak-password') {
        message = '비밀번호가 너무 짧습니다.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

// ✅ 추가: Google 로그인 함수
  Future<void> _signInWithGoogle() async {
    try {
      // 1️⃣ 구글 로그인 창 열기
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // 사용자가 로그인 취소한 경우

      // 2️⃣ 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3️⃣ Firebase Auth로 로그인 처리
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // 4️⃣ Firestore에 사용자 정보 없으면 새로 저장
      final uid = userCredential.user!.uid;
      final userDoc = _firestore.collection('users').doc(uid);

      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        await userDoc.set({
          'email': userCredential.user!.email,
          'name': googleUser.displayName ?? '',
          'birth': '',
          'diagnosis': '',
          'guardian': '',
          'provider': 'google',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google 로그인 성공!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google 로그인 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Text(
              '사용자 정보를 입력하세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 이메일
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),

            // 비밀번호
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 15),

            // 이름
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 생년월일
            TextField(
              controller: _birthController,
              decoration: const InputDecoration(
                labelText: '생년월일 (예: 1950-03-12)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 질병명
            TextField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: '질병명',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 보호자
            TextField(
              controller: _guardianController,
              decoration: const InputDecoration(
                labelText: '보호자 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),

            // 등록 버튼
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '등록하기',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
            ),

            const SizedBox(height: 30),

            // 🔴 Google 로그인 버튼
            Center(
              child: SizedBox(
                width: 250,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.network(
                    'https://developers.google.com/identity/images/g-logo.png',
                    height: 20,
                  ),
                  label: const Text(
                    'Google 계정으로 로그인',
                    style: TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),  
    );
  }
}
