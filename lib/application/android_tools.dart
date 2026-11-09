import 'package:flutter/services.dart';

class AndroidTools {
  static const channel = MethodChannel('beat_roulette/android');

  Future<String> storagePath() async =>
      (await channel.invokeMethod<String>('storagePath'))!;
  Future<int> deadline() async =>
      await channel.invokeMethod<int>('deadline') ?? 0;
  Future<Map<String, bool>> status() async =>
      await channel.invokeMapMethod<String, bool>('status') ?? {};
  Future<void> setScreen(bool value) =>
      channel.invokeMethod<void>('screen', value);
  Future<void> start(int deadline) =>
      channel.invokeMethod<void>('start', {'deadline': deadline});
  Future<void> cancel() => channel.invokeMethod<void>('cancel');
  Future<void> finish() => channel.invokeMethod<void>('finish');
  Future<void> enableNotifications() =>
      channel.invokeMethod<void>('notifications');
  Future<void> exactSettings() => channel.invokeMethod<void>('exactSettings');
  Future<String> savePng(Uint8List bytes) async =>
      (await channel.invokeMethod<String>('savePng', {'bytes': bytes}))!;
}
