# MediCheck
Firebase + Flutter 기반 건강관리 앱 (Capstone Project 2025)

## 프로젝트 소개
MediCheck은 사용자의 복약 일정과 건강 관리를 돕는 스마트 헬스케어 애플리케이션입니다.  
Firebase를 기반으로 한 실시간 데이터 동기화와 알림 기능을 제공합니다.

---

## 주요 기능
| 기능 | 설명 |
|------|------|
| 복약 알림 | 사용자가 설정한 시간에 알림을 받아 복약 관리 가능 |
| Firebase 연동 | 실시간 데이터 저장 및 조회 |
| 건강기록 관리 | 사용자별 건강 데이터 시각화 및 통계 제공 |
| 음성 안내 (스피커 연동 예정) | 알림 및 음성 출력 기능을 통한 접근성 강화 |

---

## 기술 스택
| 구분 | 사용 기술 |
|------|------------|
| Frontend | Flutter (Dart) |
| Backend | Firebase (Firestore, Authentication, Hosting) |
| Tools | VSCode, Android Studio, GitHub |
| OS | Android / iOS (테스트 예정) |

---

## 개발 환경 설정
```bash
# 1. Flutter 패키지 설치
flutter pub get

# 2. 앱 실행 (에뮬레이터 또는 실기기)
flutter run
```
---

## 🧩 1일차 (2025.10.28) 진행 요약  
**🎯 목표:** Flutter + Android Studio + Emulator + VSCode 환경 세팅 완료  

- Flutter SDK 설치 및 환경 변수 설정  
- Android Studio 설치 및 SDK Tools 구성  
- Android Emulator 실행 및 테스트 (Pixel 6 → Pixel 4 대체 성공)  
- Flutter Demo App 빌드 및 실행 확인 (Flutter Demo Home Page)  
- VSCode와 Flutter 프로젝트 연동 완료  

✅ **결과:** 개발 환경 완전 구축 (Flutter 앱 실행 가능 상태)  

---

## 🧩 2일차 (2025.10.29) 진행 요약  
**🎯 목표:** Firebase 프로젝트 생성 및 Flutter 연동  

- Firebase Console에서 MediCheck 프로젝트 생성  
- Flutter 프로젝트에 Firebase 연결 (firebase_options.dart 생성 완료)  
- pubspec.yaml에 Firebase SDK 추가  
  - firebase_core: ^3.3.0  
  - cloud_firestore: ^5.4.0  
- VSCode에서 Firebase 초기화 코드 삽입 및 실행 확인  
- Android Emulator에서 “Firebase Connected Successfully” 문구 출력  
- GitHub 저장소(MOK-YH/MediCheck) 생성 및 초기 커밋 완료  

✅ **결과:** Firebase 연동 및 GitHub 리포지토리 설정 완료  

---

## 🧩 3일차 (2025.10.30) 진행 요약  
**🎯 목표:** MediCheck UI 프로토타입 완성 및 GitHub 버전 관리  

- Flutter + Firebase Core 연동 완료  
- MediCheck 홈 화면(HomeScreen) 제작  
- 복약 알림 화면(AlarmScreen) 제작  
- 홈 → 알림 화면 전환 기능 구현  
- GitHub 업로드 및 커밋 완료  

✅ **결과:** MediCheck 앱 프로토타입 완성 (시연 가능한 단계)  

---

