import 'dart:typed_data';

class File {
  File(this.path);
  final String path;

  Future<void> writeAsBytes(Uint8List bytes) async {}
}
