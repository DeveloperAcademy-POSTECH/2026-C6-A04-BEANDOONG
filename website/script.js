const feedbackStates = {
  aeration: { title: ['공기가 고르게', '들어가고 있어요'], description: '지금 상태를 유지해 주세요', image: 'IllustFeedbackAeration', alt: '공기가 고르게 주입되는 우유 일러스트' },
  bubble: { title: ['큰 기포가', '생길 수 있어요'], description: '피처를 살짝 올려 노즐을 더 담가 주세요', image: 'IllustFeedbackBubble', alt: '큰 기포가 생기는 우유 일러스트' },
  moreAir: { title: ['공기 주입이', '부족해요'], description: '피처를 살짝 내려 주세요', image: 'IllustFeedbackMoreAir', alt: '공기 주입이 부족한 우유 일러스트' },
  milkFlow: { title: ['롤링이 안정적으로', '진행되고 있어요'], description: '우유가 한 방향으로 돌도록 유지해 주세요', image: 'IllustFeedbackMilkFlow', alt: '안정적으로 회전하는 우유 일러스트' },
};

const buttons = document.querySelectorAll('[data-state]');
const phone = document.querySelector('.demo-phone');
const title = document.querySelector('#feedback-title');
const description = document.querySelector('#feedback-description');
const illustration = document.querySelector('#feedback-image');

buttons.forEach((button) => {
  button.addEventListener('click', () => {
    const state = button.dataset.state;
    const feedback = feedbackStates[state];
    if (!feedback) return;
    buttons.forEach((item) => {
      const selected = item === button;
      item.classList.toggle('active', selected);
      item.setAttribute('aria-pressed', String(selected));
    });
    phone.dataset.feedback = state;
    title.replaceChildren(feedback.title[0], document.createElement('br'), feedback.title[1]);
    description.textContent = feedback.description;
    illustration.src = `./assets/${feedback.image}.png`;
    illustration.alt = feedback.alt;
  });
});
