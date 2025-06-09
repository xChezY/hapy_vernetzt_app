if (!window.backobserver) {
  function addGoBackLink() {
    const element = document.querySelector('nav');
    if (element && !document.getElementById('goback')) {
      const arrowLink = document.createElement('a');
      arrowLink.id = 'goback';
      arrowLink.href = 'javascript:window.history.back();';
      arrowLink.style.padding = '8px';
      arrowLink.innerHTML = `<i class="fas fa-chevron-left"></i>`;
      element.prepend(arrowLink);
    }
  }

  window.backobserver = new MutationObserver(() => {
    addGoBackLink();
  });

  console.log("Test: " + window.backobserver);

  window.backobserver.observe(document.body, { childList: true, subtree: true });
  addGoBackLink();

  setTimeout(() => {
    window.backobserver.disconnect();
    window.backobserver = null; // sauber aufräumen
  }, 3000);
}