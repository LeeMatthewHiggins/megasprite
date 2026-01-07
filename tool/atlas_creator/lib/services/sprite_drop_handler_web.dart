import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';

Future<List<({String name, String path, Uint8List bytes})>> readDroppedFiles(
  DropDoneDetails details,
) async {
  final bytesFutures = details.files.map((file) async {
    try {
      return (name: file.name, path: file.name, bytes: await file.readAsBytes());
    } on Exception catch (e) {
      debugPrint('Failed to read ${file.name}: $e');
      return null;
    }
  }).toList();

  final results = await Future.wait(bytesFutures);
  return results.whereType<({String name, String path, Uint8List bytes})>().toList();
}
