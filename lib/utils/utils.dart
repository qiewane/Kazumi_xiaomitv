import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

class Utils {
  static final Random _random = Random();

  /// 检查是否为桌面端
  static bool isDesktop() {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// 检查是否为移动设备
  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// TV 设备检测
  /// 优先从存储读取，未设置则通过屏幕尺寸判断
  static bool isTV() {
    // 优先读取存储的标记（在 main.dart 初始化时设置）
    try {
      final storedValue = GStorage.isTVDevice;
      if (storedValue) return true;
    } catch (e) {
      // 如果存储未初始化，继续检测
    }

    if (!Platform.isAndroid) return false;
    
    try {
      // 获取屏幕信息
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final data = MediaQueryData.fromView(view);
      final size = data.size;
      final pixelRatio = data.devicePixelRatio;
      
      // 计算物理尺寸（英寸），160dpi 为 Android 基准密度
      final widthInches = size.width / pixelRatio / 160;
      final heightInches = size.height / pixelRatio / 160;
      final diagonalInches = sqrt(widthInches * widthInches + heightInches * heightInches);
      
      // TV 判断逻辑：对角线大于 10 英寸且为横屏，或短边大于 600 逻辑像素
      final isLargeScreen = diagonalInches > 10.0 || size.shortestSide > 600;
      final isLandscape = size.width > size.height;
      
      return isLargeScreen && isLandscape;
    } catch (e) {
      return false;
    }
  }

  /// 强制检测 TV 并保存结果（在 main.dart 初始化时调用）
  static Future<bool> detectTVDevice() async {
    if (!Platform.isAndroid) {
      await GStorage.setTVDevice(false);
      return false;
    }
    
    bool isTVDevice = false;
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final data = MediaQueryData.fromView(view);
      final size = data.size;
      
      // TV 判断：短边大于 600 逻辑像素且为横屏
      isTVDevice = size.shortestSide > 600 && size.width > size.height;
      
      // 保存检测结果到 Hive
      await GStorage.setTVDevice(isTVDevice);
    } catch (e) {
      isTVDevice = false;
      await GStorage.setTVDevice(false);
    }
    
    return isTVDevice;
  }

  /// 检查 WebView 功能支持（Android）
  static Future<void> checkWebViewFeatureSupport() async {
    // 原有实现保留
    if (!Platform.isAndroid) return;
    // TODO: 实现 WebView 检查逻辑
  }

  /// 检查是否为低分辨率屏幕（TV 和老设备适配）
  static Future<bool> isLowResolution() async {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final data = MediaQueryData.fromView(view);
      // 低于 720p 认为是低分辨率
      return data.size.width < 1280 || data.size.height < 720;
    } catch (e) {
      return false;
    }
  }

  /// 获取应用版本信息
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  /// 获取设备信息（TV 调试使用）
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final Map<String, dynamic> info = {};
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      info['model'] = androidInfo.model;
      info['brand'] = androidInfo.brand;
      info['version'] = androidInfo.version.release;
      info['sdk'] = androidInfo.version.sdkInt;
      info['isTV'] = isTV();
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      info['model'] = iosInfo.model;
      info['system'] = iosInfo.systemVersion;
    } else {
      info['platform'] = Platform.operatingSystem;
      info['version'] = Platform.operatingSystemVersion;
    }
    
    return info;
  }

  /// 调整屏幕亮度（TV 播放器使用）
  static Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness.instance.setScreenBrightness(brightness.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('设置亮度失败: $e');
    }
  }

  /// 获取当前亮度
  static Future<double> getBrightness() async {
    try {
      return await ScreenBrightness.instance.current;
    } catch (e) {
      return 1.0;
    }
  }

  /// 设置系统音量（TV 播放器使用）
  static void setVolume(double volume) {
    VolumeController.instance.setVolume(volume.clamp(0.0, 1.0));
  }

  /// 获取当前音量
  static Future<double> getVolume() async {
    try {
      return await VolumeController.instance.getVolume();
    } catch (e) {
      return 1.0;
    }
  }

  /// 显示音量/亮度调节 UI（TV 优化版 - 更大的显示尺寸）
  static void showVolumeIndicator(BuildContext context, double value, String label) {
    final isTV = Utils.isTV();
    final double fontSize = isTV ? 32.0 : 20.0;
    final double iconSize = isTV ? 48.0 : 32.0;
    final double padding = isTV ? 32.0 : 16.0;
    
    // 这里可以触发一个 Overlay 或通知 BLoC 显示调节界面
    debugPrint('[$label] ${(value * 100).toInt()}% (TV: $isTV)');
  }

  /// 生成随机字符串
  static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
    ));
  }

  /// 格式化时间（秒 -> HH:MM:SS），播放器使用
  static String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 清除缓存目录
  static Future<void> clearCache() async {
    final cacheDir = await getTemporaryDirectory();
    if (cacheDir.existsSync()) {
      await cacheDir.delete(recursive: true);
    }
  }

  /// 获取缓存大小
  static Future<int> getCacheSize() async {
    final cacheDir = await getTemporaryDirectory();
    if (!cacheDir.existsSync()) return 0;
    
    int totalSize = 0;
    await for (final file in cacheDir.list(recursive: true, followLinks: false)) {
      if (file is File) {
        totalSize += await file.length();
      }
    }
    return totalSize;
  }

  /// 安全解析 JSON
  static dynamic safeJsonDecode(String source) {
    try {
      return jsonDecode(source);
    } catch (e) {
      return null;
    }
  }

  /// 复制到剪贴板
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 从剪贴板粘贴
  static Future<String?> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    return data?.text;
  }

  /// 检查 URL 是否有效
  static bool isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }

  /// 防抖函数（TV 遥控器按键优化，防止重复触发）
  static VoidCallback debounce(VoidCallback action, Duration duration) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(duration, action);
    };
  }

  /// 节流函数（TV 遥控器按键优化，限制触发频率）
  static VoidCallback throttle(VoidCallback action, Duration duration) {
    DateTime? lastAction;
    return () {
      if (lastAction != null && DateTime.now().difference(lastAction!) < duration) {
        return;
      }
      lastAction = DateTime.now();
      action();
    };
  }

  /// 获取适配屏幕的间距（TV 需要更大的间距便于遥控器导航）
  static double getAdaptivePadding(BuildContext context) {
    return isTV() ? 24.0 : 16.0;
  }

  /// 获取适配屏幕的字体大小（TV 需要更大的字体）
  static double getAdaptiveFontSize(BuildContext context, double baseSize) {
    return isTV() ? baseSize * 1.25 : baseSize;
  }

  /// 判断是否需要显示 TV 专属 UI
  static bool shouldShowTVUI() {
    return isTV();
  }
}
