import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';
import 'spy_camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: 'https://ayvxmvhwtyveukdbjteg.supabase.co',
    anonKey: 'sb_publishable_8Jz7UwIRZsMY0-tjVRxjnA_aO4IvHOz',
  );

  await initializeDateFormatting('id_ID', null);

  // 🔥 INIT SPY CAMERA
  SpyCamera.init();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await DesktopWindow.setMinWindowSize(const Size(393, 852));
    await DesktopWindow.setMaxWindowSize(const Size(393, 852));
    await DesktopWindow.setWindowSize(const Size(393, 852));
  }

  runApp(
    const ProviderScope(
      child: KuanganApp(),
    ),
  );
}
