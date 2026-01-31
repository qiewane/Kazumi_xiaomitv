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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  // TV 适配：检测 TV 设备并强制横屏（必须在其他初始化之前）
  if (Platform.isAndroid) {
    await _initTVMode();
  }
  
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
    
    // TV 适配：保存 TV 标记到存储
    if (Platform.isAndroid) {
      await _saveTVMode();
    }
  } catch (_) {
    if (Platform.isWindows) {
      await windowManager.ensureInitialized();
      windowManager.waitUntilReadyToShow(null, () async {
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
      titleBarStyle: (Platform.isMacOS || !showWindowButton)
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      windowButtonVisibility: showWindowButton,
      title: 'Kazumi',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
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

// TV 适配：检测是否为 TV 设备并设置横屏
Future<void> _initTVMode() async {
  try {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final data = MediaQueryData.fromView(view);
    final size = data.size;
    
    // TV 判断逻辑：短边大于 600 且为横屏
    bool isTVDevice = size.shortestSide > 600 && size.width > size.height;
    
    if (isTVDevice) {
      // TV 强制横屏
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  } catch (e) {
    // 检测失败时静默处理
    debugPrint('TV 检测失败: $e');
  }
}

// TV 适配：保存 TV 标记到存储
Future<void> _saveTVMode() async {
  try {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final data = MediaQueryData.fromView(view);
    final size = data.size;
    bool isTVDevice = size.shortestSide > 600 && size.width > size.height;
    await GStorage.setting.set(SettingBoxKey.isTV, isTVDevice);
  } catch (e) {
    debugPrint('保存 TV 标记失败: $e');
  }
}
