import 'dart:convert';
import 'dart:io';

import 'link_utils.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'qrScaner.dart';
import 'qrImage.dart';

class HistoryEntry {
  final String source;
  final String data;
  final DateTime time;

  HistoryEntry({required this.source, required this.data, required this.time});

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      source: json['source'] as String? ?? 'Unknown',
      data: json['data'] as String? ?? '',
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'data': data,
      'time': time.toIso8601String(),
    };
  }

  String get shortData {
    const maxLength = 40;
    if (data.length <= maxLength) {
      return data;
    }
    return '${data.substring(0, maxLength)}...';
  }

  String get timeLabel {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: HomePage(themeMode: _themeMode, onToggleTheme: _toggleTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController(
    text: 'Hello QR Code',
  );
  String _qrData = 'Hello QR Code';
  final List<HistoryEntry> _history = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateQrCode() {
    final text = _controller.text.trim();
    final value = text.isEmpty ? 'Hello QR Code' : text;
    setState(() {
      _qrData = value;
      _addHistory('Generate', value);
    });
  }

  void _addHistory(String source, String data) {
    setState(() {
      _history.add(
        HistoryEntry(source: source, data: data, time: DateTime.now()),
      );
      if (_history.length > 20) {
        _history.removeAt(0);
      }
    });
    _saveHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/history.json');
      if (!await file.exists()) {
        return;
      }

      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return;
      }

      final decoded = jsonDecode(contents) as List<dynamic>;
      final entries = decoded
          .map((item) => HistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
      setState(() {
        _history
          ..clear()
          ..addAll(entries);
      });
    } catch (_) {
      // If parsing fails, ignore and keep empty history.
    }
  }

  Future<void> _saveHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/history.json');
      final encoded = jsonEncode(_history.map((entry) => entry.toJson()).toList());
      await file.writeAsString(encoded);
    } catch (_) {
      // If saving fails, ignore.
    }
  }

  void _handleScanned(String code) {
    _addHistory('Scanner', code);
  }

  void _handleDecoded(String code) {
    _addHistory('Image', code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        widget.themeMode == ThemeMode.dark ||
        (widget.themeMode == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    final pages = <Widget>[
      _buildGeneratePage(theme),
      _buildScanPage(theme),
      _buildHistoryPage(theme),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Home'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? '切換為亮色模式' : '切換為暗色模式',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.create), label: '生成'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: '掃描',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '歷史'),
        ],
      ),
    );
  }

  Widget _buildGeneratePage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('輸入內容產生 QR Code', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'QR 內容',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _generateQrCode,
            child: const Text('產生 QR Code'),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('預覽', style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: PrettyQrView.data(
                      data: _qrData,
                      errorCorrectLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _qrData,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     setState(() {
          //       _currentIndex = 1;
          //     });
          //   },
          //   icon: const Icon(Icons.qr_code_scanner),
          //   label: const Text('前往掃描頁'),
          // ),
          // const SizedBox(height: 12),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     Navigator.of(context).push(
          //       MaterialPageRoute(
          //         builder: (context) => Qrimage(onDecoded: _handleDecoded),
          //       ),
          //     );
          //   },
          //   icon: const Icon(Icons.photo_library),
          //   label: const Text('從相簿解碼 QR'),
          // ),
          // const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildScanPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('掃描 QR Code', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 420,
            child: QRViewExample(onScanned: _handleScanned),
          ),
          const SizedBox(height: 16),
          Text('掃描頁已支援相機掃描，若要從相簿解碼請點選下方按鈕。', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Qrimage(onDecoded: _handleDecoded),
                ),
              );
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('從相簿解碼 QR'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoryPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('歷史紀錄', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            const Text('目前沒有歷史紀錄。')
          else
            ..._history.reversed.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(entry.shortData),
                  subtitle: Text('${entry.source} · ${entry.timeLabel}'),
                  trailing: const Icon(Icons.open_in_new, size: 18), // 改成「開啟外部」圖示
                  onTap: () {
                    LinkUtils.openUrl(entry.data, () async {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('無法開啟連結'),
                          content: const Text('這個 QR Code 的內容無法被識別為有效的 URL。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('確定'),
                            ),
                          ],
                        ),
                      );
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
