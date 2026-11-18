// 원래 문장과 DOM 구조를 유지하면서 페이지 문구와 접근성 설명을 전환합니다.
const englishCopy = {
  "소리를 보고, 진동으로 느끼는 스티밍 가이드. chic은 청각장애인 초보 바리스타를 위한 iPhone·Apple Watch 앱입니다.": "See the sound. Feel the feedback. chic is a milk-steaming guide for deaf and hard-of-hearing beginner baristas, on iPhone and Apple Watch.",
  "chic — 소리를 넘어, 나만의 한 잔으로": "chic — Beyond sound, toward your own perfect cup",
  "청각장애인 초보 바리스타를 위한 스티밍 파트너. 팀 빈둥빈둥의 디자인 이야기.": "A steaming companion for deaf and hard-of-hearing beginner baristas. The design story of Team Beandoong.",
  "본문으로 건너뛰기": "Skip to content",
  "chic 처음으로": "chic home",
  "주요 메뉴": "Main navigation",
  "언어 선택": "Language",
  "이야기": "Story",
  "앱 미리보기": "App preview",
  "팀 소개": "Team",
  "chic 앱과 Apple Watch를 사용하며 우유를 스티밍하는 바리스타": "A barista steaming milk with chic and Apple Watch",
  "스티밍 상태를": "See your steaming",
  "눈으로 확인해요": "at a glance",
  "우유에 공기를 넣어": "Adding air to milk",
  "부드러운 거품을 만드는 과정,": "to create silky foam:",
  "스티밍": "milk steaming",
  "뜨거운 스팀으로 우유를 데우며 공기를 넣고,": "Steam heats the milk and introduces air.",
  "우유를 회전시켜 거품을 고르게 섞어요.": "A gentle whirlpool blends the bubbles evenly.",
  "스팀 노즐로 우유에 공기를 넣어 부드러운 거품을 만드는 모습": "A steam wand introducing air into milk to create silky foam",
  "한 잔의 부드러움은": "A silky cup",
  "우유에서 시작돼요.": "starts with the milk.",
  "작고 고른 거품은 라떼의 부드러운 질감을 만들어요.": "Tiny, even bubbles give a latte its smooth texture.",
  "곱게 스티밍한 우유는 에스프레소와 어우러지고,": "Silky steamed milk blends with espresso",
  "라떼 아트를 그리는 바탕이 되기도 해요.": "and becomes the canvas for latte art.",
  "바리스타가 실제 커피잔에 스티밍한 우유를 붓는 장면": "A barista pouring steamed milk into a cup of coffee",
  "카페 테이블 위에 놓인 라떼 한 잔": "A latte on a café table",
  "스티밍은 소리를 단서로 배우는 과정.": "Sound helps us learn to steam milk.",
  "하지만 소리가 들리지 않는다면?": "But what if you cannot hear it?",
  "사진에 마우스를 올리거나 눌러 이야기를 펼쳐보세요.": "Hover over or tap a photo to explore the story.",
  "피처의 우유 표면과 스팀 노즐을 가까이에서 보는 모습": "A close-up of the milk surface and steam wand in a pitcher",
  "공기가 잘 들어가는 걸까?": "Is enough air getting in?",
  "많은 바리스타분들이 소리를 통해 공기 주입 여부를 판단해요.": "Many baristas listen to tell whether air is entering the milk.",
  "그러나 소리가 들리지 않는다면? 다른 소리를 통해 해당 감각을 익혀야 해서 시간이 오래 걸려요.": "Without access to that sound, learning to recognize aeration through other cues can take longer.",
  "두 손으로 스팀 노즐 아래 피처의 위치를 조절하는 모습": "Hands adjusting a pitcher beneath a steam wand",
  "피처를 어떻게 움직이면 될까?": "How should I move the pitcher?",
  "우유의 상태가 달라지면 피처의 위치도 조절해야 해요.": "As the milk changes, the pitcher position needs to change too.",
  "지금 피처를 올려야 할지, 내려야 할지. 소리의 변화를 듣기 어렵다면 다음 움직임을 정하는 순간에도 망설이게 돼요.": "Should you raise the pitcher or lower it? When changes in sound are hard to hear, choosing the next move can be uncertain.",
  "피처에서 흰 컵으로 흐르는 우유와 라떼 표면의 질감": "Milk flowing from a pitcher into a white cup, showing the texture of the latte",
  "이번 스티밍은 잘 된 걸까?": "Did this steaming go well?",
  "스티밍을 마친 뒤, 우유의 표면을 살펴봐요. 이번에는 공기가 충분히 들어갔을까요?": "After steaming, you look at the milk surface. Did enough air get in this time?",
  "과정을 돌아볼 단서가 없다면 무엇이 잘됐고, 다음에는 무엇을 바꿔야 할지 알기 어려워요.": "Without a way to review the process, it is hard to know what went well or what to change next time.",
  "우리가 풀고 싶은 것은": "The challenge we want to address",
  "들리지 않는 소리가 아니라,": "goes beyond unheard sound:",
  "스스로 판단할 수 없는 순간.": "moments when you cannot decide for yourself.",
  "소리에 담긴 공기 주입 정보를 다른 감각으로 전달해,": "We make aeration cues available through other senses,",
  "현재 상태를 이해하고 다음 행동을 선택하도록 돕습니다.": "helping you understand what is happening and choose your next move.",
  "지금의 상태를 보고,": "See what is happening.",
  "다음 움직임을 알아요.": "Know your next move.",
  "chic은 소리를 색상과 진동으로 바꾸는 스티밍 가이드 앱이에요.": "chic turns steaming sounds into colors and vibrations.",
  "공기 주입부터 롤링까지, 지금의 상태를 확인해요.": "Follow each stage, from aeration to rolling.",
  "캐러셀": "carousel",
  "스티밍 피드백 미리보기": "Steaming feedback preview",
  "슬라이드": "slide",
  "공기가 고르게 들어가고 있어요": "Air is going in evenly",
  "1/4 공기 주입": "1 of 4: Aeration",
  "공기가 고르게": "Air is going in",
  "들어가고 있어요": "evenly",
  "종료하기": "End Practice",
  "큰 기포가 생길 수 있어요": "Large bubbles may form",
  "2/4 버블링": "2 of 4: Bubbling",
  "피처를 살짝 올려": "Raise the pitcher",
  "노즐을 더 담가 주세요": "to submerge the tip",
  "공기 주입이 부족해요": "Too little air is going in",
  "3/4 스크래칭": "3 of 4: Screeching",
  "피처를 살짝": "Lower the pitcher",
  "내려 주세요": "slightly",
  "롤링이 안정적으로 진행되고 있어요": "The milk is rolling steadily",
  "4/4 롤링": "4 of 4: Rolling",
  "롤링이 안정적으로": "The milk is",
  "진행되고 있어요": "rolling steadily",
  "스티밍 상태 선택": "Choose a steaming state",
  "공기 주입": "Aeration",
  "버블링": "Bubbling",
  "스크래칭": "Screeching",
  "롤링": "Rolling",
  "시선을 붙잡지 않는 신호": "Feedback without looking",
  "계속 화면을 보고 있지 않아도": "No need to keep watching the screen.",
  "Apple Watch의 진동으로 변화를 알아차려요.": "Feel changes through vibrations on Apple Watch,",
  "손과 우유에 집중할 수 있도록.": "so you can focus on your hands and the milk.",
  "공기 주입, 롤링, 버블링, 스크래칭을 안내하는 네 가지 Apple Watch 화면": "Four Apple Watch screens showing aeration, rolling, bubbling, and screeching feedback",
  "스티밍을 마쳐도,": "Steaming ends.",
  "배움은 이어져요.": "Learning continues.",
  "방금의 스티밍을 기록으로 돌아보고,": "Review your latest steaming session",
  "다음 스티밍의 단서를 찾아요.": "and find a starting point for the next one.",
  "스티밍 결과 미리보기": "Steaming results preview",
  "스티밍 결과": "Steaming Results",
  "큰 기포가 섞인 거품층이": "A layer of bubbly foam",
  "위에 남았을 수 있어요": "may have stayed on top",
  "주의소리": "Caution",
  "전체 시간": "Total time",
  "24초": "24s",
  "정상 소리": "Normal",
  "16초": "16s",
  "주의 소리": "Caution",
  "8초": "8s",
  "스티밍 기록": "Steaming Record",
  "소리 유형": "Sound type",
  "비율": "Ratio",
  "시간": "Time",
  "공기 주입 감지 구간": "Timeline of detected aeration",
  "6초": "6s",
  "스크래칭 감지 구간": "Timeline of detected screeching",
  "2초": "2s",
  "버블링 감지 구간": "Timeline of detected bubbling",
  "롤링 소리": "Rolling sound",
  "롤링 소리 감지 구간": "Timeline of detected rolling",
  "10초": "10s",
  "스팀 가이드": "Steam Guide",
  "스티밍 피처의 우유 높이와 기준선": "Milk level and reference lines in a steaming pitcher",
  "마지막에 거품만 남나요?": "Is only foam left at the end?",
  "스티밍을 마친 뒤 피처를 가볍게 돌려 컵에 따라 보세요. 처음에는 묽은 우유만 나오고 끝에 뻣뻣한 거품이 남는다면 우유와 거품이 따로 층을 이룬 상태예요.": "After steaming, gently swirl the pitcher and pour. If thin milk comes out first and stiff foam remains at the end, the milk and foam have separated into layers.",
  "소리 분석에 따른 참고용 안내이며, 실제 공기량을 측정한 결과는 아니에요.": "This guidance is based on sound analysis. It does not measure the actual amount of air in the milk.",
  "언제 어떤 소리가 났는지 시간의 흐름으로 확인해요.": "See which sounds occurred throughout your session.",
  "화면 안을 아래로 스크롤해 스팀 가이드까지 살펴보세요.": "Scroll inside the screen to explore the steaming guide.",
  "이 사용한 기술": "is built with",
  "화면과 움직임": "Visuals and motion",
  "스티밍 상태를 색상과 움직임으로 전달해요.": "Colors and motion communicate the steaming state.",
  "실시간 소리 분석": "Real-time sound analysis",
  "마이크로 들어온 소리를 기기 안에서 분석해요.": "Microphone audio is analyzed on the device.",
  "손목으로 전달하는 신호": "Feedback on your wrist",
  "분석한 상태를 워치에 전달하고 진동으로 알려줘요.": "The detected state is sent to your watch as haptic feedback.",
  "연습 기록": "Practice history",
  "연습 결과를 기기에 저장하고 다시 살펴봐요.": "Save practice results on your device and revisit them later.",
  "노트북 앞에 모여 함께 이야기하는 빈둥빈둥 팀": "Team Beandoong gathered around a laptop",
  "모두의 가능성이": "Opening up possibilities,",
  "한 잔 더 넓어지도록.": "one cup at a time.",
  "빈둥빈둥 커피잔 로고": "Team Beandoong coffee cup logo",
  "빈둥빈둥": "Beandoong",  
  "우리는 일상의 작은 장벽을 발견하고,": "We notice the small barriers in everyday life",
  "기술과 디자인으로 새로운 배움의 방법을 만듭니다.": "and create new ways to learn through technology and design.",
  "팀원": "Team members",
  "Anne 프로필 사진": "Portrait of Anne",
  "Anne(조은아)": "Anne",
  "Maple 프로필 사진": "Portrait of Maple",
  "Maple(최서진)": "Maple",
  "Zen 프로필 사진": "Portrait of Zen",
  "Zen(김유진)": "Zen",
  "Remi 프로필 사진": "Portrait of Remi",
  "Remi(정필규)": "Remi",
  "Esther 프로필 사진": "Portrait of Esther",
  "Esther(정에스더)": "Esther",
  "Craig 프로필 사진": "Portrait of Craig",
  "Craig(김정훈)": "Craig",
  "멘토": "Mentors",
  "리이오 프로필 사진": "Portrait of Leeo",
  "세진 프로필 사진": "Portrait of Sejin",
  "세니 프로필 사진": "Portrait of Senny",
  "히즈빈스 공식 홈페이지": "HISBEANS official website",
  "히즈빈스 HISBEANS": "HISBEANS",
  "메아리학교 공식 홈페이지": "Meary School official website",
  "메아리학교": "Meary School",
  "맨 위로 ↑": "Back to top ↑",
  "정책 및 문의": "Policy and contact",
  "개인정보처리방침": "Privacy policy",
  "© 2026 빈둥빈둥. All rights reserved.": "© 2026 Beandoong. All rights reserved.",
};

// 줄바꿈과 인라인 요소를 보존하기 위해 문장이 들어 있는 텍스트 노드만 기록합니다.
const localizedText = [];
const walker = document.createTreeWalker(document.documentElement, NodeFilter.SHOW_TEXT);
while (walker.nextNode()) {
  const node = walker.currentNode;
  if (node.parentElement.closest("script, style, [data-carousel-caption]")) continue;
  const original = node.nodeValue;
  const english = englishCopy[original.trim().replace(/\s+/g, " ")];
  if (english) localizedText.push({ node, original, english });
}
const localizedAttributes = [];
document.querySelectorAll("[aria-label], [aria-roledescription], [alt], meta[content]").forEach((element) => {
  for (const attribute of ["aria-label", "aria-roledescription", "alt", "content"]) {
    const original = element.getAttribute(attribute);
    if (englishCopy[original]) localizedAttributes.push({ element, attribute, original });
  }
});

// 캐러셀처럼 내용이 바뀌는 요소도 현재 선택한 언어로 표시합니다.
function translate(copy) {
  return document.documentElement.lang === "en" ? englishCopy[copy] || copy : copy;
}

// 저장소를 사용할 수 없어도 언어 전환 자체는 정상 동작합니다.
function setLanguage(language) {
  document.documentElement.lang = language === "en" ? "en" : "ko";
  localizedText.forEach(({ node, original, english }) => {
    node.nodeValue = language === "en" ? original.replace(original.trim(), () => english) : original;
  });
  localizedAttributes.forEach(({ element, attribute, original }) => {
    element.setAttribute(attribute, translate(original));
  });
  document.querySelectorAll("[data-language]").forEach((button) => {
    button.setAttribute("aria-pressed", String(button.dataset.language === document.documentElement.lang));
  });
  document.querySelectorAll("[data-src-ko][data-src-en]").forEach((image) => {
    image.src = document.documentElement.lang === "en" ? image.dataset.srcEn : image.dataset.srcKo;
  });
  try { localStorage.setItem("chic-language", document.documentElement.lang); } catch {}
  document.dispatchEvent(new Event("site-language-change"));
}

document.querySelectorAll("[data-language]").forEach((button) => {
  button.addEventListener("click", () => setLanguage(button.dataset.language));
});
let savedLanguage = "ko";
try { savedLanguage = localStorage.getItem("chic-language") || "ko"; } catch {}
setLanguage(savedLanguage);
