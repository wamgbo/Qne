import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

class Qrimage extends StatefulWidget {
  final ValueChanged<String>? onDecoded;

  const Qrimage({super.key, this.onDecoded});

  @override
  State<Qrimage> createState() => _Qrimage();
}

class _Qrimage extends State<Qrimage> {
  final picker = ImagePicker();
  String _qrcodeFile = '';
  String _data = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Image Decode')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _qrcodeFile.isEmpty
                  ? Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.photo, size: 72, color: Colors.grey),
                      ),
                    )
                  : Image.file(
                      File(_qrcodeFile),
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getPhotoByGallery,
                child: const Text('選擇相簿圖片'),
              ),
              const SizedBox(height: 12),
              Text('QR Code data: $_data'),
              const SizedBox(height: 8),
              if (_qrcodeFile.isNotEmpty) Text('Image path: $_qrcodeFile'),
            ],
          ),
        ),
      ),
    );
  }

  void _getPhotoByGallery() {
    picker
        .pickImage(source: ImageSource.gallery) //開圖庫
        .then((xfile) => xfile?.path)
        .then((path) {
          if (path != null) {
            setState(() {
              _qrcodeFile = path; //設定qrcodePath
            });
            decodeQR(path).then((data) {
              final result = data ?? 'Decode failed';
              if (data != null && data.isNotEmpty) {
                widget.onDecoded?.call(data);
              }
              setState(() => _data = result);
            });
          } else {
            setState(() {
              _data = 'Failed to load this file'; //讀不到檔案
            });
          }
        });
  }

  // Future<void> getPicByUrl(String url) async {
  //   var status = await Permission.photos.request();
  //   if (!status.isGranted) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text('權限被拒絕')));
  //     return;
  //   }

  //   try {
  //     // 存到相簿，使用隨機檔名
  //     final result = GallerySaver.saveImage(url);
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('圖片已儲存: $result')));
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('下載失敗: $e')));
  //   }
  // }

  Future<String?> decodeQR(String filePath) {
    return QrCodeToolsPlugin.decodeFrom(filePath);
  }
}
