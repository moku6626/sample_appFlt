import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as imgpack;
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:share/share.dart';
import 'package:share_extend/share_extend.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Retouching Photo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image; //変換前の画像を入れる変数
  var rtchImage;
  final picker = ImagePicker();
  final GlobalKey shareKey = GlobalKey();

  /// 画像が取れたら、setState()で更新する
  Future getImageFromGallery() async {
    final image = await picker.getImage(source: ImageSource.gallery);  // ==追加==
    setState(() {
      _image = File(image.path); // ==追加==
    });
  }
  Future getImageFromCamera() async {
    final image = await picker.getImage(source: ImageSource.camera);  // ==追加==

    setState(() {
      _image = File(image.path); // ==追加==
    });
  }
  Future retouchImage() async {
    imgpack.Image tempImage;

    setState(() {
       tempImage = imgpack.copyRotate(imgpack.decodeImage(_image!.readAsBytesSync())!,90); // 変換
       rtchImage = imgpack.encodePng(tempImage);
       //_rtchImage.writeAsBytes(tempImage.buffer.asUint8List(tempImage.offsetInBytes, tempImage.lengthInBytes));
       //ImageGallerySaver.saveImage(tempImage.getBytes());
       //_rtchImage = tempImage.getBytes();
       //_rtchImage.writeAsBytes(tempList.writeAsBytesSync);
       //print(tempList);
       //_rtchImage!.writeAsBytesSync(tempImage.getBytes().buffer.asUint8List(tempImage.getBytes().offsetInBytes, tempImage.getBytes().lengthInBytes));
       //print(_rtchImage);
    });
  }
  Future saveRtchImage() async {
    setState(() {
      ImageGallerySaver.saveImage(rtchImage);
    });
  }
  //Widgetを画像化する
  Future<ByteData?> exportToImage(GlobalKey globalKey) async {
  final boundary =
  globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(
  pixelRatio: 3,
  );
  final byteData = await image.toByteData(
  format: ui.ImageByteFormat.png,
  );
  return byteData;
  }

  //作成した画像をアプリ内のディレクトリへ保存しパスを取得
  Future<File> getApplicationDocumentsFile(
  String text, List<int> imageData) async {
  final directory = await getApplicationDocumentsDirectory();

  final exportFile = File('${directory.path}/$text.png');
  if (!await exportFile.exists()) {
  await exportFile.create(recursive: true);
  }
  final file = await exportFile.writeAsBytes(imageData);
  return file;
  }

  //ディレクトへのパスを取得してシェア
  void shareImageAndText(String text, GlobalKey globalKey) async {
  //shareする際のテキスト
  try {
  //byte dataに
  final bytes = await exportToImage(globalKey);
  final widgetImageData =
  bytes?.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  //App directoryファイルに保存
  final applicationDocumentsFile =
  await getApplicationDocumentsFile(text, widgetImageData!);

  final path = applicationDocumentsFile.path;
  await ShareExtend.share(path, "image");
  //applicationDocumentsFile.delete();
  } catch (error) {
  print(error);
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  height: 300,
                  child: _image == null
                      ? Text('No image selected.')
                      : Image.file(_image!)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                //カメラボタン(カメラから写真を取得)
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.add_a_photo,
                    color: Colors.white,
                  ),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                  ),
                  onPressed:getImageFromCamera,
                ),
                //ギャラリーボタン(ギャラリーから写真を選択)
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                  ),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                  ),
                  onPressed: getImageFromGallery,
                ),
                //レタッチボタン
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.auto_fix_high ,
                    color: Colors.white,
                  ),
                  label: const Text('Retouch'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                    onPrimary: Colors.white,
                  ),
                  onPressed: _image == null
                      ? null
                      : retouchImage,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  height: 300,
                child: RepaintBoundary(
                    key: shareKey,//追加
                  child: rtchImage == null
                      ? Text('No image selected.')
                      : Image.memory(rtchImage!)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                //保存ボタン(レタッチ画像の保存)
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                  ),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                  ),
                  onPressed:rtchImage==null
                      ? null
                      : saveRtchImage,
                ),
                //SNS共有ボタン
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.share,
                    color: Colors.white,
                  ),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                  ),
                  onPressed:rtchImage==null
                      ? null
                      : () => shareImageAndText(
                      'sample_widget',
                      shareKey,
                ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
