import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<String> getAbsolutePath(String relativePath) async {
  final appDir = await getApplicationDocumentsDirectory();

  // 规范化路径，确保使用正确的路径分隔符
  String normalizedPath = relativePath.replaceFirst('./', '');
  
  // 使用 path.join 来确保跨平台兼容性
  return path.join(appDir.path, normalizedPath);
}