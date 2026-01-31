import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/app_module.dart';
import 'package:kazumi/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('ERROR: ${details.exception}');
  };

  runZonedGuarded(() async {
    // 初始化 Hive
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocDir.path);
    } catch (e) {
      Hive.init(Directory.systemTemp.path);
    }

    // 桌面平台
    if (!Platform.isAndroid) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await windowManager.ensureInitialized();
        WindowOptions windowOptions = const WindowOptions(
          size: Size(1280, 720),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
        );
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
      }
    }

    // TV 高刷新率
    if (Platform.isAndroid) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {
        debugPrint('Display error: $e');
      }
    }

    // 关键：强制 TV 模式，跳过检测
    try {
      await GStorage.init();
      // 强制设置为 TV 模式（跳过 Utils.isTV() 检测）
      await GStorage.setting.put(SettingBoxKey.isTV, true);
      debugPrint('Forced TV mode: true');
    } catch (e) {
      debugPrint('Storage error: $e');
    }
    
    runApp(ModularApp(module: AppModule(), child: const AppWidget()));
  }, (error, stack) {
    debugPrint('UNCAUGHT: $error');
  });
}
