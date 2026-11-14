# chic 웹사이트 시안

원본 웹사이트와 분리된 `website_remi` 시안입니다. React 없이 HTML·CSS·JavaScript로 구성되어 있습니다.

## 파일 구성

- `index.html`: 첫 화면, 이야기, 앱 미리보기, 빈둥빈둥 팀 소개
- `team.html`: 기존 주소를 `index.html#team`으로 연결
- `styles.css`: 공통 스타일, 화면별 스타일, 반응형, 동작 줄이기 설정
- `script.js`: 상태 캐러셀과 스크롤 등장 효과
- `assets/`, `fonts/`: 이미지와 앱 글꼴

## 저장하면서 미리보기

프로젝트 최상위 폴더에서 실행합니다.

```sh
npx --yes vite@6.4.1 website_remi --host 127.0.0.1 --port 8765 --strictPort
```

브라우저에서 <http://127.0.0.1:8765/>를 엽니다. CSS를 저장하면 스타일이 즉시 갱신되고, HTML·JavaScript를 저장하면 페이지가 자동으로 새로고침됩니다. 서버를 켠 동안 동작하며, 종료는 터미널에서 `Ctrl+C`입니다.

이전 정적 미리보기를 열어 두었다면 처음 한 번만 새로고침하세요. HTML 파일을 Finder에서 직접 열면 자동 갱신되지 않습니다.

## 이미지와 시안 출처

- 팀원 6명과 멘토 3명의 사진: 제공받은 `프로필 사진들` 폴더의 원본을 `assets/portraits/`에 복사했습니다. `index.html`의 각 `member-role`에 직책, `member-bio`에 소개를 입력하면 됩니다.
- 프로필 9장의 배경은 흰색으로 통일한 `assets/portraits/*.white.jpeg`를 사용합니다. 원본에서 가장자리와 연결된 배경색 영역만 흰색으로 치환하고 웹용 JPEG로 저장했습니다. 원본 파일은 보관하며, 인물 재생성이나 회색 배경 보정본은 사용하지 않습니다. 팀원·멘토 영역은 등장 효과 없이 바로 표시합니다.
- 팀원·멘토 사진은 공통 `.portrait` 스타일에서 상단 20%를 잘라 표시합니다. 너비와 인물 크기는 유지하고 표시 높이만 20% 줄였으며, 이미지 파일 자체는 자르지 않습니다.

- 첫 배너: `brand-original.png`을 보존하고 내장 이미지 편집 도구로 만든 `brand-right-extended.png`을 사용합니다. 편집 지시: 인물·머신·기기를 함께 오른쪽으로 옮기고, 왼쪽 벽과 조리대를 연장하며 원래 구도와 색상을 최대한 유지. 생성형 편집이므로 세부 묘사는 원본과 다를 수 있습니다.

- 스티밍 상태 화면: 최신 Figma `4310:11593`, `4310:11508`, `4310:11265`, `4310:11306`의 피처·노즐·체크·방향 화살표·롤링 그래픽과 안내 문구를 사용합니다. 상태 선택과 스와이프는 유지합니다. 소리 명칭은 요청에 따라 주황색은 버블링, 보라색은 스크레칭으로 통일하며 결과 타임라인에도 같은 명칭을 사용합니다.
- 워치 그래픽: Figma `4074:17682`의 배경 없는 SVG. 원본 워치와 화면은 유지하고 배경색·배경 광원·옆 화면만 제외했습니다.
- 분석 화면: 최신 Figma `4638:13976`을 HTML·CSS로 구현하고 원본 SVG 그래프와 연습 가이드를 사용합니다. 결과 요약·소리별 타임라인·연습 가이드를 한 페이지로 연결했습니다. 분석 수치는 Figma의 예시값입니다.
- 스티밍 소개 사진: 제공받은 `codex-clipboard-51ef6887-3846-4753-ae25-563e35a6afc0.jpg`.
- 라떼 사진: [Trent Erwin / Unsplash — 우유 붓기](https://unsplash.com/photos/person-pouring-milk-in-coffe--Rwjvuz6pXA), [Jeremy Yap / Unsplash — 카페의 라떼](https://unsplash.com/photos/selective-focus-photography-of-latte-in-teacup-jn-HaGWe4yw). 각 사진 페이지의 촬영자·촬영 장비 정보를 확인했습니다.
- 팀 소개 배경: 제공받은 `배경화면 2.png` 단체 사진을 `assets/team-background.png`에 복사했습니다. 배너의 좌우를 꽉 채우며 화면 비율에 따라 사진 일부가 잘립니다.
- 분석 화면은 다른 iPhone 미리보기와 같은 402×874 비율이며, 화면 안에서 세로로 스크롤할 수 있습니다. 결과 화면의 페이지 넘김은 제거했습니다. 상태 미리보기의 점·좌우 스와이프·키보드 전환은 유지합니다.
- 파트너 로고: [히즈빈스 공식 사이트](https://www.hisbeans.com/)와 [메아리학교 공식 사이트](https://school.use.go.kr/meary-s/)의 로고를 로컬 PNG로 저장했습니다.

## 상호작용 확인

```sh
node website_remi/checks/carousel.test.cjs
```

두 캐러셀의 독립 전환, 선택 표시, 키보드 순환, 스와이프와 세로 스크롤 구분, 등장 효과와 동작 줄이기 설정을 확인합니다.

## 문제 상황 사진 카드

`access-story`의 `problem-list`는 Figma `4907:12577`(기본), `4907:12594`(호버)의 세로 사진 비율과 하늘색 패널을 적용합니다. 제목은 기본 상태에서 좌측 하단, 호버 후 좌측 상단에 표시합니다. 이야기는 하단에서 왼쪽 정렬로 읽히도록 배치하고 카드 로고는 제거했습니다. 사진은 요청에 따라 사용 조건이 확인되는 실제 촬영 사진으로 교체했습니다.

- 데스크톱: 마우스를 올리면 패널이 위로 올라오고, 벗어나면 내려갑니다.
- 터치: 카드를 탭하면 열리고 다시 탭하면 닫힙니다.
- 키보드: Tab으로 이동하고 Enter/Space로 열고 닫습니다. Escape 또는 포커스 이동으로 닫힙니다. 동작 줄이기 설정에서는 애니메이션을 생략합니다.
- 이야기 입력: `index.html`의 세 `<div class="problem-story">` 안의 문단을 수정하세요. 두 번째와 세 번째 이야기는 초안을 채웠습니다. 제목은 해당 카드의 `h3`와 `problem-panel-title`을 함께 수정합니다. 본문은 카드에 들어갈 짧은 문단을 기준으로 마련했습니다.

2026-11-14에 각 원본 사진 페이지의 Free 라이선스와 [Pexels License](https://www.pexels.com/license/)를 확인했습니다. 웹사이트 사용·편집이 허용되며 출처 표기는 필수가 아닙니다. 아래 출처는 추적을 위해 보관합니다. 사진 속 인물이나 브랜드가 이 프로젝트를 추천한다는 의미로 사용하지 않습니다.

| 로컬 파일 | 주제 | 사진가 · 원본 |
| --- | --- | --- |
| `assets/story-air.jpg` | 우유 표면과 공기 주입 | [Ketut Subiyanto · 4350043](https://www.pexels.com/photo/crop-cafe-worker-using-coffeemaker-to-whip-milk-in-pitcher-4350043/) |
| `assets/story-movement.jpg` | 피처와 손의 위치 | [Anna Tarazevich · 4927154](https://www.pexels.com/photo/a-person-holding-stainless-mug-while-steaming-milk-4927154/) |
| `assets/story-result.jpg` | 피처에서 흐르는 우유와 라떼 표면의 질감 | [Quang Nguyen Vinh · 2159153](https://www.pexels.com/photo/person-pouring-milk-on-white-coffee-2159153/) |

사진은 Pexels에서 웹용 크기로 내려받아 로컬에 보관하며 AI 생성이나 인물 합성은 하지 않았습니다.

```sh
node website_remi/checks/problem-cards.test.cjs
```

## 팀 배너

문구는 배너 상단 왼쪽에서 한 번 부드럽게 나타납니다. 사진 고정이나 스크롤에 따른 문구 이동은 없습니다. 동작 줄이기 설정에서는 애니메이션을 생략합니다.

## 읽기 흐름과 여백

[밀리의 서재 브랜드 페이지](https://www.millie.co.kr/v3/brand)의 섹션별 묶음과 시각적 여백을 참고해 이 사이트에 맞게 조정했습니다. 원본 사이트의 CSS 수치를 그대로 복제한 것은 아닙니다. 섹션 위아래 여백은 데스크톱 140px, 모바일 90px를 기본으로 사용합니다. 같은 섹션 안의 큰 구간은 데스크톱 160px, 모바일 100px로 구분합니다. 문제 정의에서 앱 소개까지는 데스크톱 290px 간격을 유지합니다. 카드 간격은 가로·세로 모두 24px입니다. 데스크톱에서는 기존 6px 간격보다 늘어난 총 36px만큼 카드 묶음의 영역을 확장해 사진 너비와 비율을 유지합니다. 강제 최소 높이는 사용하지 않습니다. 카드 이야기는 `<p>`로 문단을 나누고, 문장 중간에는 강제 줄바꿈을 넣지 않습니다.
