import 'dart:io';

class FixtureLoader {
  FixtureLoader._();

  static List<String> load(String fileName) {
    final file = File('test/fixtures/$fileName');

    return file
        .readAsLinesSync()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
