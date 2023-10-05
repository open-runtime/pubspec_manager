part of 'internal_parts.dart';

/// A representation of the loaded or created
/// pubspec.yaml.
/// All operations start here.
///
class PubSpec {
  /// Create an in memory pubspec.yaml.
  ///
  /// It can be saved to disk by calling [save].
  PubSpec(
      {required String name,
      required String version,
      required String description,
      required Environment environment}) {
    document = Document.loadFromString('');

    this.name =
        LineSection.fromLine(document.append(LineDetached('name: $name')));
    this.version = VersionAttached._fromLine(
        document.append(LineDetached('version: $version')));
    this.description = MultiLine.fromLine(
        document.append(LineDetached('description: $description')));

    _environment = environment._attach(this, document.lines.length + 1);
    homepage = HomepageAttached.missing(document);
    repository = RepositoryAttached.missing(document);
    issueTracker = IssueTrackerAttached.missing(document);
    documentation = DocumentationAttached.missing(document);
    dependencies = Dependencies._missing(this, 'dependencies');
    devDependencies = Dependencies._missing(this, 'dev_dependencies');
    dependencyOverrides = Dependencies._missing(this, 'dependency_overrides');
    platforms = SimpleSection.missing(document, 'platforms');
    executables = Executables._missing(this);
    funding = SimpleSection.missing(document, 'funding');
    falseSecrets = SimpleSection.missing(document, 'false_secrets');
    screenshots = SimpleSection.missing(document, 'screenshots');
    topics = SimpleSection.missing(document, 'topics');
  }

  /// Loads the content of a pubspec.yaml from the string [content].
  PubSpec.fromString(String content) {
    document = Document.loadFromString(content);

    name = document.getLineForRequiredKey('name');
    version =
        VersionAttached._fromLine(document.getLineForRequiredKey('version'));
    description = document.getMultiLineForRequiredKey('description');
    _environment = EnvironmentAttached.fromLine(
        document.getLineForRequiredKey(EnvironmentAttached._key));
    homepage = HomepageAttached._fromLine(document);
    repository = RepositoryAttached._fromLine(document);
    issueTracker = IssueTrackerAttached._fromLine(document);
    documentation = DocumentationAttached._fromLine(document);

    dependencies = _initDependencies('dependencies');
    devDependencies = _initDependencies('dev_dependencies');
    dependencyOverrides = _initDependencies('dependency_overrides');
    platforms = document.findSectionForKey('platforms');

    executables = _initExecutables();
    funding = document.findSectionForKey('funding');
    falseSecrets = document.findSectionForKey('falseSecrets');
    screenshots = document.findSectionForKey('screenshots');
    topics = document.findSectionForKey('topics');
  }

  /// Loads the pubspec.yaml file from the given [directory] or
  /// the current work directory if [directory] is not passed.
  ///
  /// If the pubspec is not found, we search
  /// up the directory tree looking for it unless [search] is set
  /// to false.
  ///
  /// If you pass [filename] then it can be loaded from
  /// a non-standard filename.
  ///
  /// If you don't pass [filename] then we will attempt to load
  /// the pubspec from the file 'pubspec.yaml'.
  ///
  ///
  /// If you don't provide a [directory] then we start the search
  /// from the current working directory.
  ///
  /// ```dart
  /// Pubspec.load()
  ///   ..dependencies
  ///     .append(HostedDependency(name: 'onepub', url:'https://onepub.dev'))
  ///   ..save();
  /// ```
  factory PubSpec.load(
      {String? directory,
      String filename = 'pubspec.yaml',
      bool search = true}) {
    final loadedFrom =
        _findPubSpecFile(directory ?? Directory.current.path, filename, search);
    final content = File(loadedFrom).readAsStringSync();

    final pubspec = PubSpec.fromString(content)
      .._loadedFromDirectory = dirname(loadedFrom)
      .._loadedFromFilename = basename(loadedFrom);
    return pubspec;
  }

  /// Allows you to load the pubspec from path which includes
  /// the directory and filename.
  ///
  /// @see [PubSpec.load] to load the project's pubspec.yaml
  factory PubSpec.loadFromPath(String pathTo) =>
      PubSpec.load(directory: dirname(pathTo), filename: basename(pathTo));

  // the path the pubspec.yaml was loaded from (including the filename)
  // If the pubpsec wasn't loaded from a file then this will be null.
  String? _loadedFromDirectory;
  String? _loadedFromFilename;

  /// [Document] that holds the lines read from the pubspec.yaml
  late Document document;

  /// attibutes of the pubspec.yaml follow.

  late LineSection name;
  late VersionAttached version;
  late MultiLine description;
  late EnvironmentAttached _environment;

  late final HomepageAttached homepage;
  late final RepositoryAttached repository;
  late final IssueTrackerAttached issueTracker;
  late final DocumentationAttached documentation;
  late final Dependencies dependencies;
  late final Dependencies devDependencies;
  late final Dependencies dependencyOverrides;
  late final SimpleSection platforms;
  late final Executables executables;
  late final SimpleSection funding;
  late final SimpleSection falseSecrets;
  late final SimpleSection screenshots;
  late final SimpleSection topics;

  EnvironmentAttached get environment => _environment;

  /// Returns the path that the pubspec was loaded from.
  ///
  /// If the pubspec hasn't been loaded from or
  /// save to a file then './pubspec.yaml' is returned.
  String get loadedFrom =>
      join(_loadedFromDirectory ?? '.', _loadedFromFilename);

  /// Initialises a dependencies section based in the passed [key].
  ///
  /// There are three dependencies sections in a pubspec.yaml
  /// * dependencies
  /// * dev_dependencies
  /// * dependency_overrides
  Dependencies _initDependencies(String key) {
    final line = document.findTopLevelKey(key);
    if (line.missing) {
      return Dependencies._missing(this, key);
    }

    final dependencies = Dependencies._fromLine(this, line);

    for (final child in line.childrenOf()) {
      if (child.type != LineType.key) {
        continue;
      }
      dependencies
          ._appendAttached(DependencyAttached._loadFrom(dependencies, child));
    }
    return dependencies;
  }

  Executables _initExecutables() {
    final line = document.findTopLevelKey(Executables.key);
    if (line.missing) {
      return Executables._missing(this);
    }

    final executables = Executables._fromLine(this, line);

    for (final child in line.childrenOf()) {
      if (child.type != LineType.key) {
        continue;
      }
      executables._appendAttached(ExecutableAttached._fromLine(child));
    }
    return executables;
  }

  /// Save the pubspec.yaml to [directory] with the given [filename].
  ///
  /// If you don't pass in the [directory] then
  /// we will save the pubspec back to the same
  /// location it was loaded from. If the
  /// pubspec wasn't loaded (but created) then
  /// we save the pubspec.yaml to the current directory.
  /// You may provide [filename] if you need to save
  /// the pubspec to a file other than 'pubspec.yaml'.
  void save({String? directory, String? filename}) {
    directory ??= _loadedFromDirectory ?? '.';
    filename ??= _loadedFromFilename ?? 'pubspec.yaml';

    /// after we save we update the loaded from to
    /// reflect the possibly modified location.
    _loadedFromDirectory = directory;
    _loadedFromFilename = filename;

    /// whilst the calls to [render] are ordered (for easy reading)
    /// the underlying lines control the order
    /// that each section is written to disk.
    DocumentWriter(document)
      ..render(name)
      ..render(version)
      ..render(description)
      ..render(_environment)
      ..render(homepage)
      ..render(repository)
      ..render(issueTracker)
      ..render(documentation)
      ..render(dependencies)
      ..render(devDependencies)
      ..render(dependencyOverrides)
      ..render(executables)
      ..render(platforms)
      ..render(funding)
      ..render(falseSecrets)
      ..render(screenshots)
      ..render(topics)
      ..renderMissing()
      ..write(join(directory, filename));
  }

  /// Allows you to save the pubpsec to the file
  /// located at [pathTo].
  /// [pathTo] must contains both the directory and file name.
  /// If only the filename is present then the pubspec is saved
  /// to the current working directory.
  /// @see you should normally use [save].
  void saveTo(String pathTo) {
    save(directory: dirname(pathTo), filename: basename(pathTo));
  }

  @override
  String toString() {
    final content = StringBuffer();
    // ignore: prefer_foreach
    for (final line in document.lines) {
      content.writeln(line);
    }
    return content.toString();
  }

  /// search up the directory tree (starting from [directory]to find
  /// a file with the name [filename] which will normally be
  /// pubspec.yaml
  static String _findPubSpecFile(
      String directory, String filename, bool search) {
    var path = join(directory, filename);
    var parent = directory;
    var found = true;
    while (!File(path).existsSync()) {
      if (!search) {
        throw NotFoundException(path);
      }
      if (isRoot(parent)) {
        found = false;
        break;
      }
      parent = dirname(parent);
    }
    path = join(parent, filename);

    if (!found) {
      throw NotFoundException(join(directory, filename));
    }

    return path;
  }

  static bool isRoot(String path) =>
      path.startsWith('/') || path.startsWith(RegExp(r'[a-zA-Z]:\\'));
}