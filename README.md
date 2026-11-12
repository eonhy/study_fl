# Dayline

Dayline은 마감일과 우선순위로 할 일을 관리하는 한국어 Flutter 앱입니다. 데이터는 기기에 JSON으로 저장됩니다.

## 주요 기능

- 할 일 추가, 수정, 삭제 및 완료 상태 전환
- 제목과 메모 검색, 진행 중·완료 필터
- 마감일 표시와 기한 초과 안내
- 미완료 우선, 마감일 오름차순, 우선순위 내림차순 정렬
- 전체 할 일의 완료 진행률과 시스템 테마에 따른 다크 모드

## 실행

최신 stable Flutter SDK와 Android 또는 iOS 개발 환경이 필요합니다. iOS 실행에는 macOS와 Xcode가 필요합니다.

압축을 푼 후 `dayline` 폴더에서 아래 명령을 실행합니다. 첫 번째 명령은 플랫폼별 실행 파일과 설정을 생성합니다.

```sh
flutter create --empty --no-pub --platforms=android,ios --project-name dayline .
flutter pub get
flutter analyze
flutter run
```

실행 대상이 여러 개라면 `flutter devices`에서 기기 ID를 확인하고 `flutter run -d <기기_ID>`를 실행합니다. Android에서 `path_provider`를 사용하려면 앱의 최소 SDK가 API 24 이상이어야 합니다. Flutter 템플릿이 더 낮은 값을 지정하면 `android/app/build.gradle.kts`의 `defaultConfig`에서 `minSdk`를 24 이상으로 설정합니다.

GitHub에 올릴 때는 생성한 `android/`, `ios/`, `pubspec.lock`도 함께 커밋하면 같은 설정으로 프로젝트를 열 수 있습니다.

## 파일 구조

```text
lib/
├── main.dart                  # 테마와 한국어 로캘
├── data/
│   └── task_store.dart         # 앱 데이터 디렉터리의 JSON 읽기와 저장
├── models/
│   └── task.dart               # 할 일 모델, 검색, 필터, 정렬
└── screens/
    ├── task_board.dart         # 목록, 진행률, 검색 및 완료 처리
    └── task_editor.dart        # 입력 검증, 우선순위 및 날짜 선택
```

## 문서

- [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli)
- [path_provider](https://pub.dev/packages/path_provider)
