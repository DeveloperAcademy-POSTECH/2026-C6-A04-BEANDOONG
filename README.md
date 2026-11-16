<p align="center"><img src="docs/assets/chic-app-icon.png" alt="chic 앱 아이콘" width="120" /></p>

<h1 align="center">chic</h1>

<p align="center"><strong>소리를 보고, 진동으로 느끼는 스티밍 연습</strong></p>

<p align="center">청각장애인 초보 바리스타가 우유 스티밍의 현재 상태를 스스로 알아차리고,<br/>다음 한 잔을 준비할 수 있도록 돕는 iPhone · Apple Watch 앱입니다.</p>

<p align="center"><a href="https://apps.apple.com/kr/app/chic/id6830698769"><strong>App Store에서 다운로드</strong></a> · <a href="https://developeracademy-postech.github.io/2026-C6-A04-BEANDOONG/">프로젝트 웹사이트</a> · <a href="#chic이-하는-일">앱 살펴보기</a> · <a href="#team-beandoong">팀 소개</a></p>

---

## 왜 만들었나요?

바리스타는 우유의 움직임을 보고, 피처의 온도를 느끼고, 스티밍 소리를 들으며 공기 주입 상태를 판단합니다. 소리를 듣기 어려운 초보 바리스타도 **지금 무엇이 일어나는지 알고 스스로 조절할 수 있도록**, chic은 소리의 단서를 시각과 진동으로 옮깁니다.

> **소리를 넘어, 나만의 한 잔으로.**

## chic이 하는 일

| 01 · 준비 | 02 · 연습 | 03 · 돌아보기 |
| :--- | :--- | :--- |
| 마이크 권한과 연습 순서를 확인하고 스티밍을 준비합니다. | iPhone에서 소리를 분석해 공기 주입의 진행 정도를 비커 속 우유가 차오르는 모션으로 보여줍니다. 상태별 안내와 Apple Watch 진동도 함께 제공합니다. | 연습 결과에서 소리별 시간과 가이드를 확인하고, 지난 기록을 다시 볼 수 있습니다. |

공기 주입 소리가 감지되는 동안 **누적 공기 주입 시간에 맞춰 화면 속 우유 수위가 부드럽게 올라가고 잔물결이 움직입니다.** 주입이 멈추면 수위는 그 지점에 머물러, 다음 주입이 감지될 때 이어서 올라갑니다. 비커의 두 점선은 공기 주입 가이드 구간을 보여줍니다.

| 실시간 상태 | 화면 안내 |
| :--- | :--- |
| 공기 주입 | 파란 화면에서 우유 수위와 잔물결로 진행 정도를 보여줍니다. |
| 안정적인 롤링 | 초록 화면에서 안정적으로 진행 중임을 알립니다. |
| 큰 기포 | 주황 화면에서 피처를 살짝 올려 노즐을 더 담그도록 안내합니다. |
| 공기 주입 부족 | 보라 화면에서 피처를 살짝 내리도록 안내합니다. |

색상과 모션에 짧은 문장을 함께 사용합니다. Apple Watch가 없어도 iPhone에서 연습할 수 있습니다.

## 어떻게 동작하나요?

`마이크 입력` → `온디바이스 소리 분석` → `상태 안내·누적 공기 주입 모션` → `Apple Watch 진동` → `연습 결과·기록`

- **iPhone:** SwiftUI, AVAudioEngine, Core ML, SwiftData
- **Apple Watch:** SwiftUI, WatchConnectivity, 햅틱 피드백
- **데이터:** 마이크 소리는 실시간 분석에 사용하며, 새 연습의 원음 파일을 저장하지 않습니다. 연습 기록은 기기 안의 SwiftData에 저장합니다.

설계와 구현을 더 자세히 보려면 [소리 분석](docs/steaming-sound-model.md), [연습 결과와 데이터](docs/practice-results.md), [iPhone ↔ Apple Watch 연결](docs/watch-connectivity.md)을 참고하세요.

## 실행하기

1. Xcode 27 이상에서 `chic.xcodeproj`를 엽니다.
2. `chic` 스킴을 선택하고 iPhone에서 빌드·실행합니다. 프로젝트의 iOS 최소 버전은 **27.0**입니다.
3. 마이크 사용을 허용한 뒤 홈 화면에서 **연습하기**를 선택합니다.
4. Apple Watch 진동을 사용하려면 워치 앱을 설치하고 앱의 **설정 → 워치 페어링**에서 연결합니다. 워치 앱의 최소 버전은 **watchOS 10.6**입니다.

기기에서 실행할 때는 Xcode의 Signing & Capabilities에서 자신의 개발 팀과 서명 설정을 확인하세요. 웹 소개 페이지는 앱 빌드 없이 [별도로 미리 볼 수 있습니다](docs/website.md).

## 현지화

iPhone과 Apple Watch는 기기 또는 앱에서 선택한 언어에 따라 한국어·영어를 표시합니다. 한국어가 개발 언어이며, 화면 문구·오류·접근성 설명은 `Shared/Localizable.xcstrings`, 권한 안내는 `chic/InfoPlist.xcstrings`에서 관리합니다. 두 앱은 Shared 폴더의 카탈로그를 함께 포함합니다.

일반 `String`으로 전달하는 문구도 `String(localized:)`로 생성해야 합니다. 날짜와 회차는 번역 가능한 전체 문장으로 표시하고, 저장 데이터·통신 값의 식별자는 번역하지 않습니다. 홈 사진의 영어 버전은 `home.practice.image` 항목으로 선택합니다. 한국어 키의 공백 차이로 자동 생성 심벌이 충돌하므로 문자열 심벌 생성은 사용하지 않습니다.

알려진 연결 오류는 `ConnectionError.localized`로 번역 키를 전달하고 수신 기기에서 번역합니다. 이전 앱을 위해 기존 오류 문구도 함께 보냅니다. `sh Tests/verify-connection-errors.sh /path/to/chic.app`으로 서로 다른 언어와 이전 응답 형식의 호환성을 검증합니다.

번역·치환 형식 검증: `python3 Tests/verify-localization.py`. Debug 시뮬레이터 빌드 후 DerivedData 경로를 인자로 주면 컴파일러가 추출한 문자열의 번역 누락과 iPhone·Watch 앱 번들의 포함 여부도 확인합니다.

## Team BEANDOONG

서로 다른 감각이 모여, 더 많은 사람이 스스로 배울 수 있는 경험을 만듭니다.

|  |  |  |
| :---: | :---: | :---: |
| <img src="docs/assets/team/maple.jpg" alt="메이플, PM" width="180" /><br/><b>메이플 · Maple</b><br/>PM | <img src="docs/assets/team/craig.jpg" alt="크레이그, Developer" width="180" /><br/><b>크레이그 · Craig</b><br/>Developer | <img src="docs/assets/team/esther.jpg" alt="에스터, Developer" width="180" /><br/><b>에스터 · Esther</b><br/>Developer |
| <img src="docs/assets/team/ann.jpg" alt="앤, Designer" width="180" /><br/><b>앤 · Ann</b><br/>Designer | <img src="docs/assets/team/remi.jpg" alt="레미, Developer" width="180" /><br/><b>레미 · Remi</b><br/>Developer | <img src="docs/assets/team/jen.jpg" alt="젠, Designer" width="180" /><br/><b>젠 · Jen</b><br/>Designer |

<p align="center">Apple Developer Academy @ POSTECH · 2026</p>

---

<p align="center"><strong>A new sense of steaming.</strong></p>
