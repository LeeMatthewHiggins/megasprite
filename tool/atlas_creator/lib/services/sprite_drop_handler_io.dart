import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';

Future<List<({String name, String path, Uint8List bytes})>> readDroppedFiles(
  DropDoneDetails details,
) async {
  final results = <({String name, String path, Uint8List bytes})>[];

  for (final xfile in details.files) {
    final path = xfile.path;
    final fileType = FileSystemEntity.typeSync(path);

    if (fileType == FileSystemEntityType.directory) {
      final dirFiles = await _readDirectory(Directory(path), path);
      results.addAll(dirFiles);
    } else if (fileType == FileSystemEntityType.file) {
      try {
        final bytes = await File(path).readAsBytes();
        results.add((name: xfile.name, path: xfile.name, bytes: bytes));
      } on Exception catch (e) {
        debugPrint('Failed to read ${xfile.name}: $e');
      }
    }
  }

  return results;
}

Future<List<({String name, String path, Uint8List bytes})>> _readDirectory(
  Directory dir,
  String rootPath,
) async {
  final results = <({String name, String path, Uint8List bytes})>[];
  final rootName = dir.path.split(Platform.pathSeparator).last;

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) {
      try {
        final bytes = await entity.readAsBytes();
        final relativePath = entity.path.substring(rootPath.length + 1);
        final fullPath = '$rootName${Platform.pathSeparator}$relativePath';
        results.add(
          (
            name: entity.path.split(Platform.pathSeparator).last,
            path: fullPath,
            bytes: bytes,
          ),
        );
      } on Exception catch (e) {
        debugPrint('Failed to read ${entity.path}: $e');
      }
    }
  }

  return results;
}
