# chic 팀 앱 소개 웹사이트

`website/`의 HTML, CSS, JavaScript만으로 동작합니다. 앱 빌드나 npm 설치는 필요하지 않습니다.

## 로컬 미리보기

저장소 루트에서 실행한 후 http://localhost:4173 을 엽니다.

```sh
python3 -m http.server 4173 --directory website --bind 127.0.0.1
```

## GitHub Pages 배포

1. 저장소 **Settings → Pages → Build and deployment → Source**를 **GitHub Actions**로 선택합니다.
2. `website/`와 `.github/workflows/deploy-website.yml`을 `develop` 브랜치에 반영합니다.
3. **Actions → Deploy chic website to GitHub Pages**의 완료 여부를 확인합니다. 설정 이후 필요하면 **Run workflow → develop**으로 다시 실행합니다.

기본 배포 주소: https://developeracademy-postech.github.io/2026-C6-A04-BEANDOONG/

워크플로는 `website/`만 업로드하며 iOS 소스나 다른 문서는 배포하지 않습니다. 경로를 상대 경로로 작성했으므로 저장소 이름이 포함된 GitHub Pages 주소에서도 작동합니다.

## 수정 위치

- 문구와 섹션: `website/index.html`
- 색상과 반응형 레이아웃: `website/styles.css`
- 네 가지 피드백 체험: `website/script.js`
- 앱에서 가져온 일러스트: `website/assets/`

피드백 체험은 화면 예시입니다. 브라우저에서 오디오 분석이나 Apple Watch 진동은 제공하지 않습니다. 실제 다운로드 주소와 팀원 정보가 확인되면 별도로 추가할 수 있습니다.

GitHub 공식 안내: https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages

## 디자인 레퍼런스와 이미지

- LAY.ON: https://www.behance.net/gallery/237574561/LAYON — 넓은 제품 비주얼, 여백과 설명의 리듬
- Tagit: https://www.behance.net/gallery/196135501/Tagit — 브랜드 색면, 크게 배치한 로고와 오브젝트
- Hotcake: https://www.behance.net/gallery/232195829/Hotcake — 몰입감 있는 표지와 제품 중심 구성

레퍼런스의 이미지·로고는 복제하지 않았습니다. chic 로고와 피드백 일러스트는 앱의 기존 에셋을 사용합니다.

`website/assets/steaming-cover.jpg`는 내장 ImageGen으로 생성한 콘셉트 비주얼이며 실제 제품 사용 사진이 아닙니다. 생성 원본은 Codex generated_images에 보존했습니다. 웹 배포본은 JPEG로 최적화했습니다.

생성 프롬프트: cinematic editorial close-up of milk steaming in a brushed stainless steel barista pitcher, silky swirling microfoam, steam wand entering from top right, subtle steam, blurred dark espresso machine, ice-blue cafe setting, pitcher on right, negative space on left, realistic silver reflections and soft daylight, landscape 3:2, no text, logos, watermark, people or phone UI.
