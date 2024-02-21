import 'dart:typed_data';
import 'package:http/http.dart' as http;

class NetworkHelper {
  static Future<Uint8List> loadImg(String imageUrl) async {
    final res = await http.get(Uri.parse(imageUrl));
    if (res.statusCode == 200) {
      return res.bodyBytes;
    } else {
      throw Exception('Error getting image');
    }
  }
}