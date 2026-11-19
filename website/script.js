const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");

// 각 미리보기는 선택 상태를 따로 유지하며 버튼, 키보드, 스와이프로 전환합니다.
document.querySelectorAll("[data-carousel]").forEach((carousel) => {
  const viewport = carousel.querySelector("[data-carousel-viewport]");
  const track = carousel.querySelector("[data-carousel-track]");
  const slides = [...carousel.querySelectorAll("[data-carousel-slide]")];
  const buttons = [...carousel.querySelectorAll("[data-slide]")];
  const caption = carousel.querySelector("[data-carousel-caption]");
  let current = 0;
  let pointerStart;
  let hovering = false;
  let focused = false;
  let timer;
  let wrappedSlide;

  // 경계에서는 실제 슬라이드를 옆에 놓고, 이동이 끝나면 같은 화면의 원래 좌표로 복귀합니다.
  function finishWrap() {
    if (!wrappedSlide) return;
    track.style.transition = "none";
    wrappedSlide.style.transform = "";
    wrappedSlide = undefined;
    track.style.transform = `translateX(-${current * 100}%)`;
    void track.offsetWidth;
    track.style.transition = "";
  }
  track.addEventListener("transitionend", (event) => {
    if (event.target === track && event.propertyName === "transform") finishWrap();
  });

  // 자동 재생 중에는 반복 알림을 끄고, 사용자가 읽거나 조작할 때 전환을 멈춥니다.
  function syncPlayback() {
    clearInterval(timer);
    timer = undefined;
    if (!reducedMotion.matches && !hovering && !focused && !pointerStart && !document.hidden) {
      timer = setInterval(() => showSlide(current + 1), 4000);
    }
    caption.setAttribute("aria-live", timer === undefined ? "polite" : "off");
  }

  // 화면과 설명, 보조 기술에 전달되는 선택 상태를 함께 바꿉니다.
  function showSlide(index) {
    finishWrap();
    const next = (index + slides.length) % slides.length;
    let position = next;
    if (!reducedMotion.matches && slides.length > 1) {
      if (current === slides.length - 1 && next === 0) position = slides.length;
      else if (current === 0 && next === slides.length - 1) position = -1;
    }
    if (position !== next) {
      wrappedSlide = slides[next];
      wrappedSlide.style.transform = `translateX(${(position - next) * 100}%)`;
    }
    current = next;
    track.style.transform = `translateX(${-position * 100}%)`;
    slides.forEach((slide, i) => {
      slide.setAttribute("aria-hidden", String(i !== current));
      slide.inert = i !== current;
      buttons[i].setAttribute("aria-pressed", String(i === current));
    });
    caption.textContent = translate(slides[current].dataset.caption);
  }

  buttons.forEach((button, i) => {
    button.addEventListener("click", (event) => {
      showSlide(i);
      // 포인터 선택은 자동 전환을 재개하고, 키보드 탐색의 일시 정지는 유지합니다.
      if (event.detail > 0) hovering = focused = false;
      syncPlayback();
    });
    button.addEventListener("keydown", (event) => {
      if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
      event.preventDefault();
      focused = true;
      showSlide(
        event.key === "Home"
          ? 0
          : event.key === "End"
            ? slides.length - 1
            : i + (event.key === "ArrowRight" ? 1 : -1),
      );
      buttons[current].focus();
      syncPlayback();
    });
  });
  viewport.addEventListener("pointerdown", (event) => {
    if (!event.isPrimary || event.button !== 0) return;
    pointerStart = { x: event.clientX, y: event.clientY };
    viewport.setPointerCapture(event.pointerId);
    syncPlayback();
  });
  viewport.addEventListener("pointerup", (event) => {
    if (!pointerStart) return;
    const dx = event.clientX - pointerStart.x;
    const dy = event.clientY - pointerStart.y;
    pointerStart = null;
    if (Math.abs(dx) > 40 && Math.abs(dx) > Math.abs(dy)) showSlide(current + (dx < 0 ? 1 : -1));
    syncPlayback();
  });
  viewport.addEventListener("pointercancel", () => {
    pointerStart = null;
    syncPlayback();
  });
  carousel.addEventListener("pointerenter", (event) => {
    if (event.pointerType !== "mouse") return;
    hovering = true;
    syncPlayback();
  });
  carousel.addEventListener("pointerleave", (event) => {
    if (event.pointerType !== "mouse") return;
    hovering = false;
    syncPlayback();
  });
  carousel.addEventListener("focusin", () => {
    focused = true;
    syncPlayback();
  });
  carousel.addEventListener("focusout", (event) => {
    focused = carousel.contains(event.relatedTarget);
    syncPlayback();
  });
  document.addEventListener("visibilitychange", syncPlayback);
  document.addEventListener("site-language-change", () => {
    showSlide(current);
    syncPlayback();
  });
  reducedMotion.addEventListener("change", () => {
    finishWrap();
    syncPlayback();
  });
  showSlide(0);
  syncPlayback();
});

// 각 내용이 화면에 들어올 때 아래에서 부드럽게 나타나며, 동작 줄이기 설정을 존중합니다.
const revealItems = document.querySelectorAll("[data-reveal]");
if ("IntersectionObserver" in window) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        entry.target.classList.toggle("is-visible", reducedMotion.matches || entry.isIntersecting);
      });
    },
    { threshold: 0.12 },
  );
  // 화면 밖으로 나가면 등장 상태를 초기화해 위아래 스크롤 모두에서 다시 실행합니다.
  function syncRevealMotion() {
    observer.disconnect();
    revealItems.forEach((element) => {
      element.classList.add("reveal", "reveal-pending");
      if (reducedMotion.matches) element.classList.add("is-visible");
      else observer.observe(element);
    });
  }
  reducedMotion.addEventListener("change", syncRevealMotion);
  syncRevealMotion();
}

// 호버는 마우스에서만 열고, 터치와 키보드는 기본 버튼 동작으로 전환합니다.
document.querySelectorAll(".problem-card").forEach((card) => {
  const button = card.querySelector(".problem-toggle");
  const panel = card.querySelector(".problem-panel");
  function setOpen(open) {
    button.setAttribute("aria-expanded", String(open));
    panel.setAttribute("aria-hidden", String(!open));
  }
  card.addEventListener("pointerenter", (event) => {
    if (event.pointerType === "mouse") setOpen(true);
  });
  card.addEventListener("pointerleave", (event) => {
    if (event.pointerType === "mouse") setOpen(false);
  });
  button.addEventListener("click", () => setOpen(button.getAttribute("aria-expanded") !== "true"));
  button.addEventListener("keydown", (event) => {
    if (event.key === "Escape") setOpen(false);
  });
  button.addEventListener("blur", () => setOpen(false));
});
