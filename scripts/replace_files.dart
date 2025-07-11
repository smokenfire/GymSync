import 'dart:io';

void main() async {
  final replacements = [
    {
      'source': '.github/replace/AndroidManifest.xml',
      'target': 'apps/mobile_app/android/app/src/main/AndroidManifest.xml',
    },
    {
      'source': '.github/replace/build.gradle.kts',
      'target': 'apps/mobile_app/android/app/build.gradle.kts',
    },
  ];

  for (var file in replacements) {
    final sourceFile = File(file['source']!);
    final targetFile = File(file['target']!);

    if (!await sourceFile.exists()) {
      print('Source file not found: ${file['source']}');
      continue;
    }

    final content = await sourceFile.readAsString();
    await targetFile.writeAsString(content);

    print('Replaced: ${file['target']}');
  }
}