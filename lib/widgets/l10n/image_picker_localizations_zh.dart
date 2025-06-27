import 'image_picker_localizations.dart';

class ImagePickerLocalizationsZh extends ImagePickerLocalizations {
  ImagePickerLocalizationsZh(super.locale);

  @override
  String get name => '图片选择器';

  @override
  String get takePhoto => '拍照';

  @override
  String get chooseFromGallery => '从相册选择';

  @override
  String get cancel => '取消';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get permissionDeniedMessage => '请在设置中启用相机和相册访问权限以使用此功能';

  @override
  String get settings => '设置';

  @override
  String get noCameraAvailable => '没有可用的相机';

  @override
  String get photoCaptureFailed => '拍照失败';

  @override
  String get imageSelectionFailed => '图片选择失败';

  @override
  String get imageProcessingFailed => '图片处理失败';

  @override
  String get maxImagesReached => '已达到最大图片数量';

  @override
  String get deleteImage => '删除';

  @override
  String get confirmDeleteImage => '确定要删除这张图片吗？';

  @override
  String get selectMultipleImages => '选择多张图片';

  @override
  String get selectImage => '选择图片';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get selectImageFailed => '选择图片失败';

  @override
  String get takePhotoFailed => '拍照失败';

  @override
  String get cropImage => '裁剪图片';

  @override
  String get saveCroppedImageFailed => '保存裁剪图片失败';

  @override
  String get cropFailed => '图片裁剪失败';
}
