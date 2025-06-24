import 'package:flutter/material.dart';

class ImagePickerLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'selectFromGallery': 'From Gallery',
      'takePhoto': 'Take Photo',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'selectImageFailed': 'Failed to select image: %s',
      'takePhotoFailed': 'Failed to take photo: %s',
      'saveCroppedImageFailed': 'Failed to save cropped image: %s',
      'cropFailed': 'Crop failed: %s',
      'selectImage': 'Select Image',
      'selectMultipleImages': 'Select Multiple Images',
      'cropImage': 'Crop Image',
    },
    'zh': {
      'selectFromGallery': '从相册选择',
      'takePhoto': '拍摄照片',
      'cancel': '取消',
      'confirm': '确定',
      'selectImageFailed': '选择图片失败: %s',
      'takePhotoFailed': '拍摄照片失败: %s',
      'saveCroppedImageFailed': '保存裁剪图片失败: %s',
      'cropFailed': '裁剪失败: %s',
      'selectImage': '选择图片',
      'selectMultipleImages': '选择多张图片',
      'cropImage': '裁剪图片',
    },
  };

  static String getSelectFromGallery(BuildContext context) =>
      _localizedValues[Localizations.localeOf(
        context,
      ).languageCode]!['selectFromGallery']!;

  static String getTakePhoto(BuildContext context) =>
      _localizedValues[Localizations.localeOf(
        context,
      ).languageCode]!['takePhoto']!;

  static String getCancel(BuildContext context) =>
      _localizedValues[Localizations.localeOf(
        context,
      ).languageCode]!['cancel']!;

  static String getConfirm(BuildContext context) =>
      _localizedValues[Localizations.localeOf(
        context,
      ).languageCode]!['confirm']!;

  static String getSelectImageFailed(BuildContext context, String error) =>
      _localizedValues[Localizations.localeOf(
            context,
          ).languageCode]!['selectImageFailed']!
          .replaceFirst('%s', error);

  static String getTakePhotoFailed(BuildContext context, String error) =>
      _localizedValues[Localizations.localeOf(
            context,
          ).languageCode]!['takePhotoFailed']!
          .replaceFirst('%s', error);

  static String getSaveCroppedImageFailed(BuildContext context, String error) =>
      _localizedValues[Localizations.localeOf(
            context,
          ).languageCode]!['saveCroppedImageFailed']!
          .replaceFirst('%s', error);

  static String getCropFailed(BuildContext context, String error) =>
      _localizedValues[Localizations.localeOf(
            context,
          ).languageCode]!['cropFailed']!
          .replaceFirst('%s', error);

  static String getSelectImage(BuildContext context) =>
      _localizedValues[Localizations.localeOf(
        context,
      ).languageCode]!['selectImage']!;

  static String getSelectMultipleImages(BuildContext context) =>
      _localizedValues[Localizations.localeOf(
        context,
      ).languageCode]!['selectMultipleImages']!;

  static String getCropImage(BuildContext context) =>
      _localizedValues[Localizations.localeOf(
        context,
      ).languageCode]!['cropImage']!;
}
