import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;

Future<String?> handlePickedImage(XFile file) async {
  try {
    // 读取文件内容
    final bytes = await file.readAsBytes();
    // 创建 Blob URL
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    return url;
  } catch (e) {
    print('处理Web图片时出错: $e');
    return null;
  }
}