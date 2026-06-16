import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageProvider extends ChangeNotifier {
  final ImagePicker _imagePicker = ImagePicker();
  File? selectedImage;

  Future<File?> pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) {
      return null;
    }
    selectedImage = File(image.path);
    notifyListeners();
    return File(image.path);
  }
}
