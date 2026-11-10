# chic 웹사이트 시안

원본 웹사이트와 분리된 `website_remi` 시안입니다. React 없이 HTML·CSS·JavaScript로 구성되어 있습니다.

## 파일 구성

- `index.html`: 첫 화면, 이야기, 앱 미리보기, 빈둥빈둥 팀 소개
- `team.html`: 기존 주소를 `index.html#team`으로 연결
- `styles.css`: 공통 스타일, 화면별 스타일, 반응형, 동작 줄이기 설정
- `script.js`: 상태·분석 캐러셀과 스크롤 등장 효과
- `assets/`, `fonts/`: 이미지와 앱 글꼴

## 저장하면서 미리보기

프로젝트 최상위 폴더에서 실행합니다.

```sh
npx --yes vite@6.4.1 website_remi --host 127.0.0.1 --port 8765 --strictPort
```

브라우저에서 <http://127.0.0.1:8765/>를 엽니다. CSS를 저장하면 스타일이 즉시 갱신되고, HTML·JavaScript를 저장하면 페이지가 자동으로 새로고침됩니다. 서버를 켠 동안 동작하며, 종료는 터미널에서 `Ctrl+C`입니다.

이전 정적 미리보기를 열어 두었다면 처음 한 번만 새로고침하세요. HTML 파일을 Finder에서 직접 열면 자동 갱신되지 않습니다.

## 이미지와 시안 출처

- 첫 배너: `brand-original.png`을 보존하고 내장 이미지 편집 도구로 만든 `brand-right-extended.png`을 사용합니다. 편집 지시: 인물·머신·기기를 함께 오른쪽으로 옮기고, 왼쪽 벽과 조리대를 연장하며 원래 구도와 색상을 최대한 유지. 생성형 편집이므로 세부 묘사는 원본과 다를 수 있습니다.

- 워치 그래픽: Figma `4074:17682`의 배경 없는 SVG. 원본 워치와 화면은 유지하고 배경색·배경 광원·옆 화면만 제외했습니다.
- 분석 화면: Figma `3893:44807`, `3893:44960`, `3893:45078`을 HTML·CSS로 구현하고 원본 SVG 그래프를 사용합니다. 분석 수치는 Figma의 예시값입니다.
- 스티밍 소개 사진: 제공받은 `codex-clipboard-51ef6887-3846-4753-ae25-563e35a6afc0.jpg`.
- 라떼 사진: [Trent Erwin / Unsplash — 우유 붓기](https://unsplash.com/photos/person-pouring-milk-in-coffe--Rwjvuz6pXA), [Jeremy Yap / Unsplash — 카페의 라떼](https://unsplash.com/photos/selective-focus-photography-of-latte-in-teacup-jn-HaGWe4yw). 각 사진 페이지의 촬영자·촬영 장비 정보를 확인했습니다.
- 팀 소개 배경: 기존 스티밍 설명에 있던 실습 사진 `IMG_1378 2.PNG`. 검은 상하 여백은 CSS로 숨기며 원본 파일을 보존합니다.
- 분석 화면의 긴 내용은 화면 안에서 세로로 스크롤할 수 있습니다. 화면 전환은 아래 점, 좌우 스와이프 또는 점에 포커스한 상태의 방향키·Home·End를 사용합니다.

## 상호작용 확인

```sh
node website_remi/checks/carousel.test.cjs
```

두 캐러셀의 독립 전환, 선택 표시, 키보드 순환, 스와이프와 세로 스크롤 구분, 등장 효과와 동작 줄이기 설정을 확인합니다.
