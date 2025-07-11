import 'dart:io';

Future<void> main() async {
  final tools = {
    'Flutter': 'flutter --version',
    'Dart': 'dart --version',
    'Node.js': 'node --version',
    'npm': 'npm --version',
  };

  for (var entry in tools.entries) {
    final result = await Process.run(
      entry.value.split(' ').first,
      entry.value.split(' ').sublist(1),
      runInShell: true,
    );

    if (result.exitCode == 0) {
      print('[OK] ${entry.key} is installed: ${result.stdout}${result.stderr}');
    } else {
      print('[WARNING] ${entry.key} is NOT installed or not in PATH.');
    }
  }
}
