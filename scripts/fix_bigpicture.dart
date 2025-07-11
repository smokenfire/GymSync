import 'dart:io';

void main() async {
  // Get user home directory (cross-platform)
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) {
    print('Could not find the HOME directory.');
    return;
  }

  // List of possible pub-cache locations
  final pubCacheLocations = [
    Directory('$home${Platform.pathSeparator}.pub-cache${Platform.pathSeparator}hosted${Platform.pathSeparator}pub.dev'),
    // For Windows, also check AppData\Local\Pub\Cache\hosted\pub.dev
    if (Platform.isWindows)
      Directory('${home}${Platform.pathSeparator}AppData${Platform.pathSeparator}Local${Platform.pathSeparator}Pub${Platform.pathSeparator}Cache${Platform.pathSeparator}hosted${Platform.pathSeparator}pub.dev'),
  ];

  // The relative path to the file we want to fix
  final relativePath = [
    'flutter_local_notifications-15.1.3',
    'android',
    'src',
    'main',
    'java',
    'com',
    'dexterous',
    'flutterlocalnotifications',
    'FlutterLocalNotificationsPlugin.java'
  ].join(Platform.pathSeparator);

  bool found = false;

  for (final pubCache in pubCacheLocations) {
    if (!await pubCache.exists()) {
      print('Directory $pubCache not found.');
      continue;
    }

    // Recursively search for the target file
    await for (var entity in pubCache.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith(relativePath)) {
        found = true;
        final lines = await entity.readAsLines();
        final modifiedLines = lines.map((line) =>
          line.contains('bigPictureStyle.bigLargeIcon(null);')
            ? line.replaceAll('bigPictureStyle.bigLargeIcon(null);', 'bigPictureStyle.bigLargeIcon((Bitmap) null);')
            : line
        ).toList();

        await entity.writeAsString(modifiedLines.join('\n'));
        print('Modification completed at: ${entity.path}');
      }
    }
  }

  if (!found) {
    print('Target file not found in any known pub-cache location.');
  }
}