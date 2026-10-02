import 'package:flutter/services.dart';

/// Plays the website's looping duration alarm through the Android host.
class SessionAlarm {
  static const _channel = MethodChannel('game_terminal/session_alarm');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('start');
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.alert);
    } on PlatformException {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // The visible reminder remains available on platforms without a host.
    } on PlatformException {
      // A failed stop should not prevent the reminder from being dismissed.
    }
  }
}
