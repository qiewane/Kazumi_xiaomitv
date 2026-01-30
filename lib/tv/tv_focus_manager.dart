import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV 遥控器按键映射
class TVRemoteKey {
  static const ok = [LogicalKeyboardKey.select, LogicalKeyboardKey.enter];
  static const back = [LogicalKeyboardKey.escape, LogicalKeyboardKey.backspace];
  static const menu = [LogicalKeyboardKey.contextMenu];
  static const left = [LogicalKeyboardKey.arrowLeft];
  static const right = [LogicalKeyboardKey.arrowRight];
  static const up = [LogicalKeyboardKey.arrowUp];
  static const down = [LogicalKeyboardKey.arrowDown];
}

/// TV 焦点管理器
class TVFocusManager {
  static final TVFocusManager _instance = TVFocusManager._internal();
  factory TVFocusManager() => _instance;
  TVFocusManager._internal();

  final Map<String, FocusNode> _nodes = {};
  String? _currentRegion;

  void register(String id, FocusNode node) {
    _nodes[id] = node;
  }

  void unregister(String id) {
    _nodes.remove(id);
  }

  void requestFocus(String id) {
    if (_nodes.containsKey(id)) {
      _nodes[id]!.requestFocus();
    }
  }

  /// 处理遥控器按键
  bool handleKeyEvent(KeyEvent event, {
    VoidCallback? onLeft,
    VoidCallback? onRight,
    VoidCallback? onUp,
    VoidCallback? onDown,
    VoidCallback? onSelect,
    VoidCallback? onBack,
    VoidCallback? onMenu,
  }) {
    if (event is! RawKeyDownEvent) return false;

    final key = event.logicalKey;

    if (TVRemoteKey.left.contains(key)) {
      onLeft?.call();
      return true;
    } else if (TVRemoteKey.right.contains(key)) {
      onRight?.call();
      return true;
    } else if (TVRemoteKey.up.contains(key)) {
      onUp?.call();
      return true;
    } else if (TVRemoteKey.down.contains(key)) {
      onDown?.call();
      return true;
    } else if (TVRemoteKey.ok.contains(key)) {
      onSelect?.call();
      return true;
    } else if (TVRemoteKey.back.contains(key)) {
      onBack?.call();
      return true;
    } else if (TVRemoteKey.menu.contains(key)) {
      onMenu?.call();
      return true;
    }
    return false;
  }
}
