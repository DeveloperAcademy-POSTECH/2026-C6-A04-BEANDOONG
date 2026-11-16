# chic 쇼케이스 웹사이트

`website/`는 GitHub Pages에 배포되는 정적 웹사이트입니다. HTML·CSS·JavaScript로 동작하며, 앱 빌드나 패키지 설치는 필요하지 않습니다. 페이지 구성과 이미지 출처는 [웹사이트 README](../website/README.md)를 참고하세요.

## 로컬 미리보기

저장소 루트에서 실행한 뒤 <http://127.0.0.1:4173/>을 엽니다.

```sh
python3 -m http.server 4173 --directory website --bind 127.0.0.1
```

파일 저장 시 자동 새로고침이 필요하면 [웹사이트 README](../website/README.md)의 Vite 명령을 사용합니다.

## GitHub Pages 배포

`develop` 브랜치에서 `website/**` 또는 [배포 워크플로](../.github/workflows/deploy-website.yml)가 변경되면 GitHub Actions가 `website/`를 업로드하고 배포합니다. 워크플로는 **Actions → Deploy chic website to GitHub Pages**에서 확인하거나 수동으로 실행할 수 있습니다.

배포 주소: <https://developeracademy-postech.github.io/2026-C6-A04-BEANDOONG/>

저장소의 GitHub Pages Source는 **GitHub Actions**로 설정되어 있습니다. iOS 소스와 다른 문서는 배포 대상에 포함되지 않습니다.

## 수정 위치

- 문구와 페이지 구성: [`website/index.html`](../website/index.html)
- 색상과 반응형 레이아웃: [`website/styles.css`](../website/styles.css)
- 캐러셀과 카드 상호작용: [`website/script.js`](../website/script.js)
- 이미지와 웹 글꼴: [`website/assets/`](../website/assets/), [`website/fonts/`](../website/fonts/)
- Safari 탭 아이콘: [`website/favicon.svg`](../website/favicon.svg)

앱 미리보기는 화면 예시입니다. 브라우저에서 오디오 분석이나 Apple Watch 진동은 제공하지 않습니다.

## 변경 확인

```sh
node website/checks/carousel.test.cjs
node website/checks/problem-cards.test.cjs
```
