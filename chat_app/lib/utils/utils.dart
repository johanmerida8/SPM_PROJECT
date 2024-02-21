import 'package:image_picker/image_picker.dart';

pickImage(ImageSource src) async {
  final ImagePicker _imgPicker = ImagePicker();

  XFile? _file = await _imgPicker.pickImage(source: src);
  if (_file != null) {
    return await _file.readAsBytes();
  } else {
    throw Exception('Error picking image');
  } 
}