import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewJS {

  static UserScript autoClickChatButtonJS = UserScript(
                      source: '''
                              const chatobserver = new MutationObserver((mutations, obs) => {
                              const form = document.querySelector('form[aria-describedby="welcomeTitle"]');
                              
                              if (form) {
                                const button = form.querySelector('button, input[type="submit"]');
                                if (button) {
                                  button.click();
                                  obs.disconnect();
                                }
                              }
                            });
                            chatobserver.observe(document.body, {
                              childList: true,
                              subtree: true
                            });
                              ''',
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                      forMainFrameOnly: false,
                      );

  static const String goBackJS = '''
    if (!window.backobserver) {
      function addGoBackLink() {
        const element = document.querySelector('nav');
        if (!document.getElementById('goback')) {
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

      window.backobserver.observe(document.body, { childList: true, subtree: true });
      addGoBackLink();

      setTimeout(() => {
        window.backobserver.disconnect();
        window.backobserver = null;
      }, 3000);
    }
  ''';
  
  static UserScript userScriptremoveBannerJS = UserScript(
                      source: '''
                              const observer = new MutationObserver(mutations => {
                                mutations.forEach(() => {
                                  const footer = document.querySelector('footer');
                                  if (footer) {
                                    footer.remove();
                                  }
                                });
                              });

                              observer.observe(document.body, { childList: true, subtree: true });
                              ''',
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                      forMainFrameOnly: false,
                      );

  static addSessionToLocalStorage(dynamic id, dynamic token) {
    return '''
      localStorage.setItem('Meteor.userId', '$id');
      localStorage.setItem('Meteor.loginToken', '$token');
    ''';
  }

}
