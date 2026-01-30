import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kazumi/app_module.dart';
import 'package:kazumi/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/settings/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:kazumi/request/request.dart';
import 'package:kazumi/utils/proxy_manager.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:kazumi/pages/error/storage_error_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// TV 设备检测（基于屏幕尺寸和系统特征）
bool _detectTV() {
  if (!Platform.isAndroid) return false;
  // 通过屏幕物理尺寸判断 TV（电视通常 > 10 英寸）
  // 实际运行时会根据屏幕尺寸自动判断
  // 也可以通过 Intent 查询 Leanback Launcher 特征（需要平台通道）
  // 这里简化为：Android 设备默认检查是否为 TV 模式
  return Utils.isTV(); // 需要在 Utils 中添加此方法，或使用屏幕尺寸判断
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  // TV 检测和适配（必须在 runApp 前完成）
  bool isTVDevice = false;
  if (Platform.isAndroid) {
    isTVDevice = _detectTV();
    if (isTVDevice) {
      // TV 端强制横屏，禁用竖屏
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // 移动端保持原有 edge-to-edge 设置
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ));
    }
  } else if (Platform.isIOS) {
    // iOS 保持原有设置
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));
  }

  if (Platform.isAndroid) {
    await Utils.checkWebViewFeatureSupport();
  }

  try {
    await Hive.initFlutter(
        '${(await getApplicationSupportDirectory()).path}/hive');
    await GStorage.init();
  } catch (_) {
    if (Platform.isWindows) {
      await windowManager.ensureInitialized();
      windowManager.waitUntilReadyToShow(null, () async {
        // Native window show has been blocked in `flutter_windows.cppL36` to avoid flickering.
        // Without this. the window will never show on Windows.
        await windowManager.show();
        await windowManager.focus();
      });
    }
    runApp(MaterialApp(
        title: '初始化失败',
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hans', countryCode: "CN")
        ],
        locale: const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hans', countryCode: "CN"),
        builder: (context, child) {
          return const StorageErrorPage();
        }));
    return;
  }
  bool showWindowButton = await GStorage.setting
      .get(SettingBoxKey.showWindowButton, defaultValue: false);
  if (Utils.isDesktop()) {
    await windowManager.ensureInitialized();
    bool isLowResolution = await Utils.isLowResolution();
    WindowOptions windowOptions = WindowOptions(
      size: isLowResolution ? const Size(840, 600) : const Size(1280, 860),
      center: true,
      skipTaskbar: false,
      // macOS always hide title bar regardless of showWindowButton setting
      titleBarStyle: (Platform.isMacOS || !showWindowButton)
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      windowButtonVisibility: showWindowButton,
      title: 'Kazumi',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Native window show has been blocked in `flutter_windows.cppL36` to avoid flickering.
      // Without this. the window will never show on Windows.
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  // TV 设备存储标记（供应用内使用）
  if (isTVDevice) {
    await GStorage.setting.set(SettingBoxKey.isTV, true);
  }
  
  Request();
  await Request.setCookie();
  ProxyManager.applyProxy();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ModularApp(
        module: AppModule(),
        child: const AppWidget(),
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));
  }

  if (Platform.isAndroid) {
    await Utils.checkWebViewFeatureSupport();
  }

  try {
    await Hive.initFlutter(
        '${(await getApplicationSupportDirectory()).path}/hive');
    await GStorage.init();
  } catch (_) {
    if (Platform.isWindows) {
      await windowManager.ensureInitialized();
      windowManager.waitUntilReadyToShow(null, () async {
        // Native window show has been blocked in `flutter_windows.cppL36` to avoid flickering.
        // Without this. the window will never show on Windows.
        await windowManager.show();
        await windowManager.focus();
      });
    }
    runApp(MaterialApp(
        title: '初始化失败',
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hans', countryCode: "CN")
        ],
        locale: const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hans', countryCode: "CN"),
        builder: (context, child) {
          return const StorageErrorPage();
        }));
    return;
  }
  bool showWindowButton = await GStorage.setting
      .get(SettingBoxKey.showWindowButton, defaultValue: false);
  if (Utils.isDesktop()) {
    await windowManager.ensureInitialized();
    bool isLowResolution = await Utils.isLowResolution();
    WindowOptions windowOptions = WindowOptions(
      size: isLowResolution ? const Size(840, 600) : const Size(1280, 860),
      center: true,
      skipTaskbar: false,
      // macOS always hide title bar regardless of showWindowButton setting
      titleBarStyle: (Platform.isMacOS || !showWindowButton)
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      windowButtonVisibility: showWindowButton,
      title: 'Kazumi',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Native window show has been blocked in `flutter_windows.cppL36` to avoid flickering.
      // Without this. the window will never show on Windows.
      await windowManager.show();
      await windowManager.focus();
    });
  }
  Request();
  await Request.setCookie();
  ProxyManager.applyProxy();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ModularApp(
        module: AppModule(),
        child: const AppWidget(),
      ),
    ),
  );
}
