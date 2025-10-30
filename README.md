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
| OS | Android / iOS (iPhone SE2 테스트 예정) |

---

## 개발 환경 설정
```bash
# 1. Flutter 패키지 설치
flutter pub get

# 2. 앱 실행 (에뮬레이터 또는 실기기)
flutter run
