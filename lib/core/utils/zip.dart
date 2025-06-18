import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:universal_platform/universal_platform.dart';

Future<String?> exportZIP(
  String filePath,
  String fileName, [
  String? title = '选择保存位置',
]) async {
  final zipBytes = await File(filePath).readAsBytes();
  String? savePath;
  if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
    // 移动平台：使用 FilePicker 保存字节数据
    savePath = await FilePicker.platform.saveFile(
      dialogTitle: title,
      fileName: fileName,
      bytes: zipBytes, // 提供字节数据
    );
  } else {
    // 桌面平台：先选择保存位置，然后写入文件
    savePath = await FilePicker.platform.saveFile(
      dialogTitle: title,
      fileName: fileName,
    );

    if (savePath != null) {
      await File(savePath).writeAsBytes(zipBytes);
    }
  }
  return savePath;
}
