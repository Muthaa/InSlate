import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadCaptureFonts(WidgetTester tester) async {
  final directory = Platform.environment['SLATE_FONT_DIR'];
  if (directory == null) return;
  await tester.runAsync(() async {
    final body = FontLoader('Roboto');
    for (final name in [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ]) {
      body.addFont(
        File('$directory/$name').readAsBytes().then(ByteData.sublistView),
      );
    }
    await body.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '$directory/MaterialIcons-Regular.otf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await icons.load();
  });
}

Future<void> captureWidget(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final directory = Platform.environment['SLATE_CAPTURE_DIR'];
  if (directory == null) return;
  await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File(
      '$directory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
