import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class ImageUtils {
  /// resize theo thuật toán nearest neighbor
  static Uint8List resizeNearest(
      Uint8List rgbaBytes,
      int srcWidth,
      int srcHeight,
      int destWidth,
      int destHeight,
      ) {
    final resized = Uint8List(destWidth * destHeight * 4);
    final xRatio = srcWidth / destWidth;
    final yRatio = srcHeight / destHeight;

    for (int y = 0; y < destHeight; y++) {
      for (int x = 0; x < destWidth; x++) {
        final srcX = (x * xRatio).floor();
        final srcY = (y * yRatio).floor();
        final destIndex = (y * destWidth + x) * 4;
        final srcIndex = (srcY * srcWidth + srcX) * 4;

        resized[destIndex]     = rgbaBytes[srcIndex];
        resized[destIndex + 1] = rgbaBytes[srcIndex + 1];
        resized[destIndex + 2] = rgbaBytes[srcIndex + 2];
        resized[destIndex + 3] = rgbaBytes[srcIndex + 3];
      }
    }

    return resized;
  }

  /// decode ảnh
  static Future<Map<String, dynamic>> decodePngToRgba(Uint8List pngBytes) {
    final completer = Completer<Map<String, dynamic>>();

    ui.decodeImageFromList(pngBytes, (ui.Image image) {
      image.toByteData(format: ui.ImageByteFormat.rawRgba).then((byteData) {
        final rgba = byteData!.buffer.asUint8List();
        completer.complete({
          'rgba': Uint8List.fromList(rgba), // đảm bảo copy bộ nhớ
          'width': image.width,
          'height': image.height,
        });
      }).catchError((e) => completer.completeError(e));
    });

    return completer.future;
  }

  /// encode ảnh
  static Future<Uint8List> encodeRgbaToPng(Uint8List rgba, int w, int h) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: w,
      height: h,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}