import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'core/storage/app_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registers the foreground media service + notification/lock-screen controls.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'ir.soundify.soundify.playback',
    androidNotificationChannelName: 'Soundify playback',
    androidNotificationOngoing: true,
  );

  final prefs = await AppPrefs.load();
  runApp(SoundifyApp(prefs: prefs));
}
