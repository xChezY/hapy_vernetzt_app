class WebViewJS {
  static const String goBackJS = '''
    const element = document.querySelector('nav');
    if (element) {
      const arrowLink = document.createElement('a');
      arrowLink.id = 'goback'
      arrowLink.href = 'javascript:window.history.back();';
      arrowLink.style = 'padding: 8px';   
      arrowLink.innerHTML = `<i class="fas fa-chevron-left"></i>`;
      element.prepend(arrowLink);
    }
  ''';

  static const String removeBannerJS = '''
    if(document.querySelector('footer')) {
      document.querySelector('footer').remove();
    }
  ''';
}
