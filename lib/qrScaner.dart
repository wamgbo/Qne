import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QRViewExample extends StatefulWidget {
  final ValueChanged<String>? onScanned;

  const QRViewExample({super.key, this.onScanned});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  String? _lastScannedCode;
  double _zoom = 0.0;
  bool _askBeforeOpen = true;
  final MobileScannerController controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await controller.start();
        if (!mounted) return;
        setState(() {});
      } catch (_) {
        // ignore startup errors for now; errorBuilder will show failures.
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrl = _isUrl(result?.rawValue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 320,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildQrView(context),
            ),
          ),
          const SizedBox(height: 12),
          if (!controller.value.isInitialized || !controller.value.isRunning)
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  controller.value.isInitialized
                      ? 'Camera initializing...'
                      : 'Waiting for camera permission / initialization...',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.zoom_out),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider.adaptive(
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          value: _zoom,
                          label: '${(_zoom * 100).round()}%',
                          onChanged: (value) async {
                            setState(() {
                              _zoom = value;
                            });
                            if (controller.value.isInitialized &&
                                controller.value.isRunning) {
                              await controller.setZoomScale(_zoom);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.zoom_in),
                    ],
                  ),
                  Text(
                    'Camera zoom: ${(_zoom * 100).round()}%',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (result != null)
                    Text(
                      'Barcode Type: ${result!.format.name}   Data: ${result!.rawValue}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  else
                    const Text(
                      'Scan a code',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 12),
                  if (isUrl)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Ask before opening'),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _askBeforeOpen,
                                  onChanged: (value) {
                                    setState(() {
                                      _askBeforeOpen = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final code = result?.rawValue;
                                if (code != null) {
                                  if (_askBeforeOpen) {
                                    await _confirmAndOpenUrl(code);
                                  } else {
                                    await _openUrl(code);
                                  }
                                }
                              },
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text('開啟瀏覽器前往'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (controller.value.isInitialized &&
                              controller.value.isRunning) {
                            await controller.toggleTorch();
                            setState(() {});
                          }
                        },
                        child: ValueListenableBuilder<MobileScannerState>(
                          valueListenable: controller,
                          builder: (context, state, child) {
                            return Text('Flash: ${state.torchState.name}');
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (controller.value.isInitialized) {
                            await controller.switchCamera();
                            setState(() {});
                          }
                        },
                        child: ValueListenableBuilder<MobileScannerState>(
                          valueListenable: controller,
                          builder: (context, state, child) {
                            return Text(
                              'Camera: ${state.cameraDirection.name}',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    const overlayBorderWidth = 10.0;
    final scanArea =
        (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _onDetect,
          fit: BoxFit.cover,
          errorBuilder: (context, error) {
            return Container(
              color: Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Text(
                'Camera error:\n${error.errorCode.name}\n${error.toString()}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            );
          },
          placeholderBuilder: (context) {
            return const Center(child: CircularProgressIndicator());
          },
        ),
        Center(
          child: Container(
            width: scanArea,
            height: scanArea,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: overlayBorderWidth),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Point camera at the QR code',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first;
    final scanCode = barcode.rawValue;
    if (scanCode == null || scanCode == _lastScannedCode) return;

    setState(() {
      result = barcode;
      _lastScannedCode = scanCode;
    });
    widget.onScanned?.call(scanCode);

    final displayText = scanCode.length > 40 ? '${scanCode.substring(0, 40)}...' : scanCode;
    final isUrl = _isUrl(scanCode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned: $displayText'),
        duration: const Duration(seconds: 4),
        action: isUrl
            ? SnackBarAction(
                label: '開啟瀏覽器前往',
                onPressed: () async {
                  await _openUrl(scanCode);
                },
              )
            : null,
      ),
    );

    if (isUrl) {
      if (_askBeforeOpen) {
        _confirmAndOpenUrl(scanCode);
      } else {
        _openUrl(scanCode);
      }
    }
  }

  bool _isUrl(String? code) {
    if (code == null) return false;
    final uri = Uri.tryParse(code);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _confirmAndOpenUrl(String url) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Open link?'),
          content: Text('Do you want to open this link?\n$url'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('開啟瀏覽器前往'),
            ),
          ],
        );
      },
    );

    if (shouldOpen == true) {
      await _openUrl(url);
    }
  }

  Future<void> _openUrl(String url) async {
    var uri = Uri.tryParse(url);
    if (uri == null) {
      await _showOpenUrlError();
      return;
    }

    if (!uri.hasScheme) {
      uri = Uri.parse('https://$url');
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await _showOpenUrlError();
      }
    } catch (_) {
      await _showOpenUrlError();
    }
  }

  Future<void> _showOpenUrlError() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('無法開啟瀏覽器，請確認 URL 是否正確。')),
    );
  }
}
