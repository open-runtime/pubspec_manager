part of 'internal_parts.dart';

/// represents a dependency that has a 'path' key
/// A path dependency is located on the local file
/// system. The path is a relative or absolute path
/// to the dependant package.
/// A path dependency takes the form of:
/// dependencies:
///   dcli:
///     path: ../dcli
class PathDependency extends Section implements Dependency {
  PathDependency({required String name, required String path})
      : _name = name,
        _path = path;

  PathDependency._fromLine(this._line) {
    _name = _line.key;
    _path = (_pathLine = _line.findRequiredKeyChild('path')).value;
    comments = Comments(this);
  }
  static const key = 'path';

  late final Line _line;

  late final String _name;
  late final String _path;

  @override
  String get name => _name;

  @override
  Line get line => _line;

  late final Line _pathLine;

  @override
  Document get document => line.document;

  @override
  List<Line> get lines => [...comments.lines, _line, _pathLine];

  @override
  late final Comments comments;

  @override
  void _attach(Pubspec pubspec, int lineNo) {
    _line = Line.forInsertion(pubspec.document, '  $_name:');
    pubspec.document.insert(_line, lineNo);

    _line = Line.forInsertion(pubspec.document, '  path: $_path');
    pubspec.document.insert(_line, lineNo);
  }

  @override
  int get lineNo => _line.lineNo;

  /// The last line number used by this  section
  @override
  int get lastLineNo => lines.last.lineNo;

  @override
  sm.VersionConstraint get versionConstraint => sm.VersionConstraint.any;

  @override
  // ignore: avoid_setters_without_getters
  set version(String version) {
    // ignored as a git dep doesn't use a version.
  }
}
