import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/app_module.dart';
import 'package:kazumi/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:kazumi/utils/constans.dart';
import 'package:kazumi/utils/utils.dart';
// 关键修改1：删除 hive_ce_flutter，改为标准 hive_ce + path_provider
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 关键修改2：替换 Hive.initFlutter() 为标准初始化
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  // 桌面平台窗口管理（保持不变）
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Android 高刷新率（保持不变）
  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('设置高刷新率失败: $e');
    }
  }

  // 初始化存储（保持不变）
  await GStorage.init();
  bool isTVDevice = await Utils.isTV();
  
  // 关键修改3：确保使用 put（你已完成，保持即可）
  await GStorage.setting.put(SettingBoxKey.isTV, isTVDevice);
  
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
