import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tflite_detector/flutter_tflite_detector.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tflite_detector/model/recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

List<CameraDescription> cameras;

Future main() async {
  cameras = await availableCameras();
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

const MIN_CONFIDENCE = 0.5;

enum DetectorType {
  objects, pets
}

class Detector {
  final DetectorType detectorType;
  final String modelPath;
  final String labelsPath;
  final int imageSize;
  final bool isModelQuantized;

  Detector(
      this.detectorType,
      this.modelPath,
      this.labelsPath,
      this.imageSize,
      this.isModelQuantized,
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final GlobalKey globalKeyCamera = new GlobalKey();

  CameraController controller;
  String imagePath;
  String videoPath;

  List<Recognition> recognitions = [];

  static List<Detector> detectors = [
    Detector(DetectorType.objects, 'assets/detect_obj.tflite', 'assets/coco_labels_list.txt', 300, true),
    Detector(DetectorType.pets, 'assets/detect.tflite', 'assets/pets_labels_list.txt', 300, true),
  ];
  Detector detector = detectors[0];

  @override
  void initState() {
    super.initState();

    createSelectedDetector();

    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    FlutterTfliteDetector.closeDetector();
    super.dispose();
  }

  Future createSelectedDetector() async {
    try {
      await FlutterTfliteDetector.createDetector(
          detector.modelPath, detector.labelsPath, detector.imageSize, detector.isModelQuantized);
    } on PlatformException catch (e) {
      debugPrint('Unable to create detector, ${e.message}');
    }
  }

  Future<void> closeSelectedDetector() async {
    try {
      await FlutterTfliteDetector.closeDetector();
    } on PlatformException catch (e) {
      debugPrint('Unable to close detector, ${e.message}');
    }
  }

  Future<bool> recognizeImageFromFile(String path) async {
    try {
      DateTime t1 = DateTime.now();
      var imageBytes =
          (await rootBundle.load(path)).buffer;
      DateTime t11 = DateTime.now();
      debugPrint('Opening image file took ${t11.millisecondsSinceEpoch-t1.millisecondsSinceEpoch} ms');

      img.Image image = img.decodeJpg(imageBytes.asUint8List());
      DateTime t12 = DateTime.now();
      debugPrint('Decoding image took ${t12.millisecondsSinceEpoch-t11.millisecondsSinceEpoch} ms');

      image = img.copyResize(image, detector.imageSize, detector.imageSize); //stretch
      DateTime t13 = DateTime.now();
      debugPrint('Resizing image took ${t13.millisecondsSinceEpoch-t12.millisecondsSinceEpoch} ms');

      DateTime t2 = DateTime.now();
      debugPrint('Processing image took ${t2.millisecondsSinceEpoch-t1.millisecondsSinceEpoch} ms');

      await recognizeImage(image);
      return true;
    } on PlatformException {
      debugPrint('Unable to recognize image');
    }
    return false;
  }

  Future recognizeImage(img.Image image) async {

    DateTime t1 = DateTime.now();
    image = img.copyResize(image, detector.imageSize, detector.imageSize); //stretch
    DateTime t13 = DateTime.now();
    debugPrint('Resizing image took ${t13.millisecondsSinceEpoch-t1.millisecondsSinceEpoch} ms');

    recognitions.clear();
    debugPrint('Sending image byte at ${DateTime.now().millisecondsSinceEpoch}');
    var res = await FlutterTfliteDetector.recognizeImage(image);
    debugPrint('Image recognition result received at ${DateTime.now().millisecondsSinceEpoch}');
    res.forEach((r) {
      if (r.confidence >= MIN_CONFIDENCE) {
        recognitions.add(r);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: CustomPaint(
                foregroundPainter: DetectorPainter(detector, recognitions),
                child: imagePath == null
                    ? AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: RepaintBoundary(
                      key: globalKeyCamera,
                      child: CameraPreview(controller),),
                )
                    : Image.file(File(imagePath)),
              ),
            ),
          ),
          Container(
            height: 96.0,
            child: _captureControlRowWidget(),
          ),
        ],
      ),
    );
  }

  Widget _captureControlRowWidget() {
    return Row(
      children: <Widget>[
        Expanded(child: Container()),
        IconButton(
          iconSize: 32.0,
          icon: imagePath == null ? const Icon(Icons.camera) :  const Icon(Icons.cached),
          color: Colors.blue,
          onPressed: controller != null &&
              controller.value.isInitialized &&
              !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
        Expanded(child: IconButton(
          icon: detector.detectorType == DetectorType.pets
              ? const Icon(Icons.pets, color: Colors.white,)
              : const Icon(Icons.computer, color: Colors.white,),
          onPressed: () {
            if (detector.detectorType == DetectorType.pets) detector = detectors[0];
            else detector = detectors[1];

            recognitions.clear();
            setState(() {});

            closeSelectedDetector().then((d) {
              createSelectedDetector().then((d) {
                if (imagePath != null) recognizeImageFromFile(imagePath).then((b) {
                  if (b) setState(() {});
                });
              });
            });

          }),
        ),
      ],
    );
  }

  void onTakePictureButtonPressed() {
    if (imagePath == null) {
      DateTime t1 = DateTime.now();
      takePicture().then((String filePath) {
        DateTime t2 = DateTime.now();
        debugPrint('takePicture took ${t2.millisecondsSinceEpoch - t1.millisecondsSinceEpoch} ms');
        if (mounted && filePath != null) {
          setState(() {
            imagePath = filePath;
          });

          DateTime t3 = DateTime.now();
          recognizeImageFromFile(imagePath).then((b) {
            DateTime t4 = DateTime.now();
            debugPrint('recognizeImage took ${t4.millisecondsSinceEpoch - t3.millisecondsSinceEpoch} ms');

            if (b) setState(() {});
          });

        }
      });
    } else {
      setState(() {
        imagePath = null;
        recognitions.clear();
      });
    }
  }

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/tflite';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      debugPrint(e.toString());
      return null;
    }
    return filePath;
  }
}

class DetectorPainter extends CustomPainter {

  Detector detector;
  List<Recognition> recognitions;

  DetectorPainter(this.detector, this.recognitions);

  @override
  void paint(Canvas canvas, Size size) {

    if (recognitions == null || recognitions.isEmpty) return;

    recognitions.forEach((recognition) {
      var widthFactor = size.width/detector.imageSize;
      var heightFactor = size.height/detector.imageSize;

      var left = recognition.location.left * widthFactor;
      var top = recognition.location.top * heightFactor;
      var right = recognition.location.right * widthFactor;
      var bottom = recognition.location.bottom * heightFactor;

      var rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(
        rect,
        Paint()..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0,
      );

      TextSpan span = TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: 17.0,
          background: Paint()..color = Colors.blue,
        ),
        text: ' ${recognition.title} - ${(recognition.confidence*100).round()}% ',
      );
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(left, top));
    });
  }

  @override
  bool shouldRepaint(DetectorPainter oldDelegate) => true;
}
