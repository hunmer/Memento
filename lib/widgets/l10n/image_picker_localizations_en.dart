import 'image_picker_localizations.dart';

class ImagePickerLocalizationsEn extends ImagePickerLocalizations {
  ImagePickerLocalizationsEn(super.locale);

  @override
  String get name => 'Image Picker';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get cancel => 'Cancel';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get permissionDeniedMessage =>
      'Please enable camera and gallery access in settings to use this feature';

  @override
  String get settings => 'Settings';

  @override
  String get noCameraAvailable => 'No camera available';

  @override
  String get photoCaptureFailed => 'Photo capture failed';

  @override
  String get imageSelectionFailed => 'Image selection failed';

  @override
  String get imageProcessingFailed => 'Image processing failed';

  @override
  String get maxImagesReached => 'Maximum number of images reached';

  @override
  String get deleteImage => 'Delete';

  @override
  String get confirmDeleteImage =>
      'Are you sure you want to delete this image?';
  @override
  String get cropFailed => 'Image cropping failed';

  @override
  String get cropImage => 'Crop Image';

  @override
  String get saveCroppedImageFailed => 'Failed to save cropped image';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get selectImage => 'Select Image';

  @override
  String get selectImageFailed => 'Failed to select image';

  @override
  String get selectMultipleImages => 'Select Multiple Images';

  @override
  String get takePhotoFailed => 'Failed to take photo';
}
