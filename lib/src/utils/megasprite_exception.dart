abstract class MegaSpriteException implements Exception {
  MegaSpriteException(this.message);

  final String message;

  String get _typeName;

  @override
  String toString() => '$_typeName: $message';
}

class AtlasBuildException extends MegaSpriteException {
  AtlasBuildException(super.message);

  @override
  String get _typeName => 'AtlasBuildException';
}

class ZipAtlasExportException extends MegaSpriteException {
  ZipAtlasExportException(super.message);

  @override
  String get _typeName => 'ZipAtlasExportException';
}

class ZipAtlasException extends MegaSpriteException {
  ZipAtlasException(super.message);

  @override
  String get _typeName => 'ZipAtlasException';
}
