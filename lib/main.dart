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
// TV 适配：使用标准 Hive 初始化替代 hive_ce_flutter
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 标准 Hive 初始化（等效于 initFlutter，不影响 TV 功能）
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  // 桌面平台窗口管理（非 TV 平台）
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

  // TV 平台：设置高刷新率（小米电视支持）
  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('设置高刷新率失败: $e');
    }
  }

  // TV 关键：初始化存储并检测 TV 设备类型
  await GStorage.init();
  bool isTVDevice = await Utils.isTV();
  
  // TV 关键：保存设备类型到存储（使用 put）
  await GStorage.setting.put(SettingBoxKey.isTV, isTVDevice);
  
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
