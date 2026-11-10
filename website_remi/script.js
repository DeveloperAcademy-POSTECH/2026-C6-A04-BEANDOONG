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

  // 화면과 설명, 보조 기술에 전달되는 선택 상태를 함께 바꿉니다.
  function showSlide(index) {
    current = (index + slides.length) % slides.length;
    track.style.transform = `translateX(-${current * 100}%)`;
    slides.forEach((slide, i) => {
      slide.setAttribute("aria-hidden", String(i !== current));
      slide.inert = i !== current;
      buttons[i].setAttribute("aria-pressed", String(i === current));
    });
    caption.textContent = slides[current].dataset.caption;
  }

  buttons.forEach((button, i) => {
    button.addEventListener("click", () => showSlide(i));
    button.addEventListener("keydown", (event) => {
      if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
      event.preventDefault();
      showSlide(
        event.key === "Home"
          ? 0
          : event.key === "End"
            ? slides.length - 1
            : i + (event.key === "ArrowRight" ? 1 : -1),
      );
      buttons[current].focus();
    });
  });
  viewport.addEventListener("pointerdown", (event) => {
    if (!event.isPrimary || event.button !== 0) return;
    pointerStart = { x: event.clientX, y: event.clientY };
    viewport.setPointerCapture(event.pointerId);
  });
  viewport.addEventListener("pointerup", (event) => {
    if (!pointerStart) return;
    const dx = event.clientX - pointerStart.x;
    const dy = event.clientY - pointerStart.y;
    pointerStart = null;
    if (Math.abs(dx) > 40 && Math.abs(dx) > Math.abs(dy)) showSlide(current + (dx < 0 ? 1 : -1));
  });
  viewport.addEventListener("pointercancel", () => {
    pointerStart = null;
  });
});

// 각 내용이 화면에 들어올 때 아래에서 부드럽게 나타나며, 동작 줄이기 설정을 존중합니다.
const revealItems = document.querySelectorAll("[data-reveal]");
if ("IntersectionObserver" in window && !reducedMotion.matches) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.12 },
  );
  revealItems.forEach((element) => {
    element.classList.add("reveal", "reveal-pending");
    observer.observe(element);
  });
  reducedMotion.addEventListener("change", () => {
    if (!reducedMotion.matches) return;
    observer.disconnect();
    revealItems.forEach((element) => element.classList.add("is-visible"));
  });
}
