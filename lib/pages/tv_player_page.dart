import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';  // 假设使用此播放器

class TVPlayerPage extends StatefulWidget {
  final String videoUrl;
  
  TVPlayerPage({required this.videoUrl});

  @override
  _TVPlayerPageState createState() => _TVPlayerPageState();
}

class _TVPlayerPageState extends State<TVPlayerPage> {
  late VideoPlayerController _controller;
  bool _showControls = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final FocusNode _playerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _duration = _controller.value.duration;
        });
        _controller.play();
        _isPlaying = true;
      });
    
    _controller.addListener(_onPositionChanged);
    
    // 初始聚焦播放器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerFocus.requestFocus();
    });
  }

  void _onPositionChanged() {
    setState(() {
      _position = _controller.value.position;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _playerFocus.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _seekForward() {
    final newPos = _position + Duration(seconds: 10);
    _controller.seekTo(newPos < _duration ? newPos : _duration);
    _showSeekHint('+10s');
  }

  void _seekBackward() {
    final newPos = _position - Duration(seconds: 10);
    _controller.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
    _showSeekHint('-10s');
  }

  void _showSeekHint(String text) {
    // 显示跳转提示...
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: TextStyle(fontSize: 20)),
        duration: Duration(milliseconds: 800),
        backgroundColor: Colors.black54,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _playerFocus,
        autofocus: true,
        onKey: (node, event) {
          if (event is RawKeyDownEvent) {
            // 下键：打开播放菜单
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() => _showControls = true);
              return KeyEventResult.handled;
            }
            // 上键：关闭菜单（如果打开）
            if (event.logicalKey == LogicalKeyboardKey.arrowUp && _showControls) {
              setState(() => _showControls = false);
              return KeyEventResult.handled;
            }
            // 左键：快退
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _seekBackward();
              return KeyEventResult.handled;
            }
            // 右键：快进
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _seekForward();
              return KeyEventResult.handled;
            }
            // 确认键：播放/暂停
            if (event.logicalKey == LogicalKeyboardKey.select || 
                event.logicalKey == LogicalKeyboardKey.enter) {
              _togglePlayPause();
              return KeyEventResult.handled;
            }
            // 返回键：退出播放
            if (event.logicalKey == LogicalKeyboardKey.escape || 
                event.logicalKey == LogicalKeyboardKey.backspace) {
              if (_showControls) {
                setState(() => _showControls = false);
                return KeyEventResult.handled;
              }
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // 视频层
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : CircularProgressIndicator(),
            ),
            
            // 控制层（下键触发）
            if (_showControls) _buildControls(),
            
            // 播放状态指示器
            if (!_isPlaying && !_showControls)
              Center(child: Icon(Icons.pause, size: 64, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 进度条（支持左右键调整）
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: Slider(
                    value: _position.inSeconds.toDouble(),
                    max: _duration.inSeconds.toDouble(),
                    onChanged: (value) {
                      _controller.seekTo(Duration(seconds: value.toInt()));
                    },
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          
          // 控制按钮
          Container(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(Icons.replay_10, '快退', _seekBackward),
                SizedBox(width: 32),
                _buildControlButton(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  _isPlaying ? '暂停' : '播放',
                  _togglePlayPause,
                ),
                SizedBox(width: 32),
                _buildControlButton(Icons.forward_10, '快进', _seekForward),
                SizedBox(width: 32),
                _buildControlButton(Icons.settings, '设置', () {
                  // 打开设置
                }),
              ],
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
    return Focus(
      onKey: (node, event) {
        if (event is RawKeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.select || 
             event.logicalKey == LogicalKeyboardKey.enter)) {
          onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (context) {
        final focused = Focus.of(context).hasFocus;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: focused ? Colors.blue : Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: focused ? Colors.blue : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
