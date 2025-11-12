import 'dart:math';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:tmp_path/tmp_path.dart';

abstract class DatabaseHelper {
  static Future<Database> openTemporaryFile({
    String prefix = '',
    String? parentDirectory,
  }) async {
    // Add random string to generate more unique filename
    final random = Random();
    final uniqueId = random.nextInt(1000000000);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniquePrefix = '$prefix${timestamp}_${uniqueId}_';

    final path =
        tmpPath(prefix: uniquePrefix, parentDirectory: parentDirectory);
    return DatabaseManager().openFile(path);
  }

  /// Open in-memory database (for testing)
  static Future<Database> openInMemory() async {
    return DatabaseManager().openInMemory();
  }
}
