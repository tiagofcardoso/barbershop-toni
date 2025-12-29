import 'dart:js' as js;

void triggerInstallPrompt() {
  js.context.callMethod('triggerInstall');
}
