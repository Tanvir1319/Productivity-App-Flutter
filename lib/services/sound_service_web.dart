// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playTaskDoneSoundPlatform() {
  try {
    if (js.context.hasProperty('playTaskCompleteSound')) {
      js.context.callMethod('playTaskCompleteSound');
    }
  } catch (_) {}
}
