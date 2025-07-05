import 'dart:developer';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:resize_image/utils/image_utils.dart';

/// top level hàm isolate
void resizeIsolate(List<dynamic> args) {
  final SendPort sendPort = args[0];
  final Uint8List rgba = args[1];
  final int srcW = args[2];
  final int srcH = args[3];
  final int dstW = args[4];
  final int dstH = args[5];
  Uint8List imageResize = ImageUtils.resizeNearest(rgba, srcW, srcH, dstW, dstH);
  sendPort.send(imageResize);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? img;
  bool isLoading = false;
  String title = "";
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  /// Tạo vùng isolate để xử lý
  Future<Uint8List> resizeRgbaInIsolate(
      Uint8List rgba, int srcW, int srcH, int dstW, int dstH) async {
    final rp = ReceivePort();
    await Isolate.spawn(resizeIsolate, [rp.sendPort, rgba, srcW, srcH, dstW, dstH]);
    return await rp.first as Uint8List;
  }

  /// decode ảnh và resize sau đó encode lại ảnh để display
  Future<Uint8List> resizeImagePng(Uint8List pngBytes, int newWidth, int newHeight) async {
    final decoded = await ImageUtils.decodePngToRgba(pngBytes);
    final Uint8List rgba = Uint8List.fromList(decoded['rgba']);
    final int width = decoded['width'] as int;
    final int height = decoded['height'] as int;

    final rgbaResized = await resizeRgbaInIsolate(
      rgba,
      width,
      height,
      newWidth,
      newHeight,
    );

    return await ImageUtils.encodeRgbaToPng(rgbaResized, newWidth, newHeight);
  }

  /// resize hình ảnh
  Future<void> resizePng() async {
    try {
      if (img == null) return;
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
      int? width = int.tryParse(widthController.text);
      if (width == null) {
        print("hi");
        setState(() {
          isLoading = false;
          title = "Chưa nhập width";
        });
        return;
      }
      int? height = int.tryParse(heightController.text);
      if (height == null) {
        setState(() {
          isLoading = false;
          title = "Chưa nhập height";
        });
        return;
      }
      Uint8List resizedPng = await resizeImagePng(img!, width!, height!);
      if (mounted) {
        setState(() {
          img = resizedPng;
          title = "Ảnh sau khi resize width = $width và height = $height";
          isLoading = false;
        });
      }
    } catch (e) {
      log(e.toString());
      setState(() {
        title = e.toString();
        isLoading = false;
      });
    }
  }

  /// Tải ảnh từ network về
  Future<void> fetchImageBytes(String url) async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            img = response.bodyBytes;
            title = "Ảnh gốc";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        title = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Demo resize image isolate"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: Colors.lightBlue
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                        onTap: () async {
                          /// truyền link ảnh bất kì để tải
                          await fetchImageBytes("https://cdn.pixabay.com/photo/2022/11/13/09/07/pembroke-welsh-corgi-7588703_1280.jpg");
                        }, child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text("Fetch Image", style: TextStyle(color: Colors.white)),
                    )
                    ),
                  )
              ),
              Visibility(
                visible: img != null && !isLoading,
                child: Container(
                    margin: const EdgeInsets.only(top: 15.0),
                    child: Text(title)),
              ),
              const SizedBox(height: 15.0),
              if (img != null && !isLoading)
                Image.memory(img!),
              Visibility(
                visible: isLoading,
                child: const CircularProgressIndicator()
              ),
              const SizedBox(height: 15.0),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: Colors.lightBlue
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await resizePng();
                    }, child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text("Resize image", style: TextStyle(color: Colors.white)),
                    )
                  ),
                )
              ),
              const SizedBox(height: 15.0),
              TextField(
                controller: widthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Nhập width ảnh resize",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Nhập height ảnh resize",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
