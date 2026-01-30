import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVSearchPage extends StatefulWidget {
  @override
  _TVSearchPageState createState() => _TVSearchPageState();
}

class _TVSearchPageState extends State<TVSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final FocusNode _keyboardFocus = FocusNode();
  bool _showKeyboard = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // 搜索输入框（适配 TV）
          Focus(
            onKey: (node, event) {
              if (event is RawKeyDownEvent && 
                  (event.logicalKey == LogicalKeyboardKey.select || 
                   event.logicalKey == LogicalKeyboardKey.enter)) {
                _showTVInputDialog();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _inputFocus.hasFocus ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.white70),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _controller.text.isEmpty ? '点击输入搜索关键词' : _controller.text,
                      style: TextStyle(
                        color: _controller.text.isEmpty ? Colors.grey : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white70),
                      onPressed: () => setState(() => _controller.clear()),
                    ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // 搜索结果网格（支持遥控器导航）
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 20, // 示例数据
              itemBuilder: (context, index) => _buildResultCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(int index) {
    return Focus(
      onKey: (node, event) {
        if (event is RawKeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.select || 
             event.logicalKey == LogicalKeyboardKey.enter)) {
          _openDetail(index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (context) {
        final focused = Focus.of(context).hasFocus;
        return AnimatedScale(
          scale: focused ? 1.05 : 1.0,
          duration: Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: focused ? Colors.blue : Colors.transparent,
                width: 3,
              ),
              boxShadow: focused ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                color: Colors.grey[700],
                child: Center(child: Text('番剧 $index')),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showTVInputDialog() {
    // 唤起小米 TV 输入法
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        child: Container(
          width: 600,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('搜索', style: TextStyle(color: Colors.white, fontSize: 20)),
              SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,  // 自动聚焦唤起输入法
                style: TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: '请输入番剧名称',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (text) {
                  Navigator.pop(context);
                  _performSearch(text);
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('取消', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _performSearch(_controller.text);
                    },
                    child: Text('搜索', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performSearch(String text) {
    setState(() {});
    // 执行搜索逻辑...
  }

  void _openDetail(int index) {
    // 打开详情页...
  }
}
