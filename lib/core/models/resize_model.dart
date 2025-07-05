// import 'dart:isolate';
// import 'dart:typed_data';
//
// class ResizeModel {
//   final Uint8List pngBytes;
//   final int destWidth;
//   final int destHeight;
//   final SendPort sendPort;
//
//   ResizeModel({
//     required this.pngBytes,
//     required this.destWidth,
//     required this.destHeight,
//     required this.sendPort,
//   });
// }
//
// void isolateEntry(ResizeModel params) {
//   final decoded = img.decodeImage(params.pngBytes);
//   if (decoded == null) {
//     params.sendPort.send(null);
//     return;
//   }
//
//   final rgba = decoded.getBytes(format: img.Format.rgba);
//
//   final resized = resizeNearest(
//     rgba,
//     decoded.width,
//     decoded.height,
//     params.destWidth,
//     params.destHeight,
//   );
//
//   params.sendPort.send({
//     'bytes': resized,
//     'width': params.destWidth,
//     'height': params.destHeight,
//   });
// }
