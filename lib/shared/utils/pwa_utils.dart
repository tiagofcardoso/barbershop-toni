import 'pwa_stub.dart' if (dart.library.html) 'pwa_web.dart';

void safeTriggerInstall() {
  triggerInstallPrompt();
}
