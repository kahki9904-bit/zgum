# iOS 테스트 결과 (iPhone 13 Mini / iOS 26.5 beta)
작성: 2026-06-19 맥북 Claude

---

## [긴급] 1. GestureExclusionService iOS 미구현
- 오류: `MissingPluginException - com.example.zgum/gesture 채널`
- 원인: `GestureExclusionService`가 Android 전용 네이티브 코드, iOS 구현 없음
- 파일: `lib/services/gesture_exclusion_service.dart`
- 증상: 앱 실행 중 수백 번 오류 반복 → 성능 저하
- 해결 방향: iOS에서는 해당 채널 호출 시 예외 무시하도록 try-catch 처리 또는 플랫폼 분기

## [긴급] 2. 패널 하단 29px 오버플로우
- 오류: `RenderFlex overflowed by 29 pixels on the bottom`
- 위치: `lib/presentation/shell/shell_screen.dart:1056` — `_UserPanelContent` Column
- 증상: 캡슐바 시작점이 아래로 내려가 있음, 흔적 페이지 이음 버튼 반 짤림
- 원인: iOS 26 홈 인디케이터 SafeArea 패딩 미처리
- 해결 방향: 해당 Column에 `MediaQuery.paddingOf(context).bottom` 또는 `SafeArea` 적용

## [긴급] 3. 카카오맵 미표시
- 증상: 메인 화면 지도 영역 완전히 빈 화면
- 원인: 카카오 개발자 콘솔에 iOS 플랫폼 키 + 번들 ID(`com.example.zgum`) 미등록
- 해결: 카카오 개발자 콘솔 → 앱 설정 → 플랫폼 → iOS 추가 (번들 ID 입력)
- 참고: 코드 수정 불필요, 콘솔 등록만 하면 됨

## [경미] 4. 알림 iOS 설정 누락
- 오류: `iOS settings must be set when targeting iOS platform`
- 파일: `lib/services/notification_service.dart:25`
- 해결 방향: `FlutterLocalNotificationsPlugin.initialize()` 호출 시 `IOSInitializationSettings` 추가

---

## 정상 동작 확인
- 앱 빌드 및 설치 성공
- 등록 페이지 하단 패널 정렬 정상
- 앱 전체 구조 및 네비게이션 정상 동작
