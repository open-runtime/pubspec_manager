import 'package:strings/strings.dart';

import 'document/document.dart';
import 'document/line.dart';

/// All exceptions throw from this package are based
/// on this exception.
class PubSpecException implements Exception {
  PubSpecException(this.line, this.message) {
    document = line?.document;
  }
  PubSpecException.forDocument(this.document, this.message);

  PubSpecException.global(this.message);

  String message;
  Line? line;
  Document? document;

  @override
  String toString() {
    final error = StringBuffer();

    if (document != null) {
      error.write('''
Pubspec: ${document!.pathTo}
''');
    }

    if (line != null) {
      error.write('''
Line No.: ${line!.lineNo} 
Line Type: ${line!.type.name}
Section Indent: ${line!.indent} 
Line Content: ${Strings.orElse(line!.text, "<empty>")}
''');
    }
    error.write('Error: $message');
    return error.toString();
  }
}
