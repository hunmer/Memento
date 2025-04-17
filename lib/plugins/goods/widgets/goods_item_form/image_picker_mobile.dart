import 'package:image_picker/image_picker.dart';

Future<String?> handlePickedImage(XFile file) async {
  return file.path;
}