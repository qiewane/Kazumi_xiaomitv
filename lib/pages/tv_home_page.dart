import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tv/tv_focus_manager.dart';

class TVHomePage extends StatefulWidget {
  @override
  _TVHomePageState createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  int _selectedIndex = 0;
  final List<String> _tabs = ['搜索', '热门', '收藏', '时间表', '历史', '设置'];
  final List<IconData> _icons = [Icons.search, Icons.whatshot, Icons.favorite, Icons.schedule, Icons.history, Icons.settings];
  
  final FocusNode _sidebarFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  final Map<int, FocusNode> _tabNodes = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _tabs.length; i++) {
      _tabNodes[i] = FocusNode();
    }
    // 初始聚焦第一个 tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabNodes[0]?.requestFocus();
    });
  }

  @override
  void dispose() {
    _sidebarFocus.dispose();
    _contentFocus.dispose();
    _tabNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // 根据选中项切换内容区
    _contentFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏 - 支持遥控器上下选择
          Container(
            width: 200,
            color: Colors.grey[900],
            child: Focus(
              focusNode: _sidebarFocus,
              child: ListView.builder(
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  return _buildNavItem(index);
                },
              ),
            ),
          ),
          
          // 右侧内容区
          Expanded(
            child: Focus(
              focusNode: _contentFocus,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    final isFocused = _tabNodes[index]?.hasFocus ?? false;

    return Focus(
      focusNode: _tabNodes[index]!,
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          // 下键：下一个菜单
          if (event.logicalKey == LogicalKeyboardKey.arrowDown && index < _tabs.length - 1) {
            _tabNodes[index + 1]?.requestFocus();
            return KeyEventResult.handled;
          }
          // 上键：上一个菜单
          if (event.logicalKey == LogicalKeyboardKey.arrowUp && index > 0) {
            _tabNodes[index - 1]?.requestFocus();
            return KeyEventResult.handled;
          }
          // 右键：进入内容区
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _onTabSelected(index);
            return KeyEventResult.handled;
          }
          // 确认键：选中
          if (event.logicalKey == LogicalKeyboardKey.select || 
              event.logicalKey == LogicalKeyboardKey.enter) {
            _onTabSelected(index);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (context) {
        final focused = Focus.of(context).hasFocus;
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: focused ? Colors.blue.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: focused ? Colors.blue : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icons[index],
                color: focused ? Colors.blue : Colors.white70,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                _tabs[index],
                style: TextStyle(
                  color: focused ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: focused ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContent() {
    // 根据 _selectedIndex 返回不同页面
    switch (_selectedIndex) {
      case 0:
        return TVSearchPage();  // TV 优化搜索页
      case 1:
        return PopularPageTV(); // TV 版热门页
      case 2:
        return FavoritePageTV();// TV 版收藏页
      // ... 其他页面
      default:
        return Center(child: Text('${_tabs[_selectedIndex]} 页面', style: TextStyle(color: Colors.white)));
    }
  }
}
