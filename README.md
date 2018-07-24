# flutter_tflite_detector

A flutter plugin to run your custom retrain model from MobileNet. This plugin is under development API's might change.

## TODO
- [x] Android implementation
- [ ] iOS implementation
- [ ] Live preview

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

Here is a very good tutorial how to retrain a model using Cloud TPUs. By Sara Robinson, Aakanksha Chowdhery, and Jonathan Huang.

The sample project use the model from the Tensorflow repository for object detection and a pet breed detector built following this very good [tutorial](https://medium.com/tensorflow/training-and-serving-a-realtime-mobile-object-detector-in-30-minutes-with-cloud-tpus-b78971cf1193?linkId=54246631).

### Installation

```
dependencies:
  flutter_web_browser: 
    path: git: git@github.com:victorbonnet/flutter_tflite_detector.git
```

### Import the library

```
import 'package:flutter_tflite_detector/flutter_tflite_detector.dart';
```

### Execute you model with an image

 * Add the tflite file in your asset and the in pubspec.yaml
 * Add the labels file in your asset and the in pubspec.yaml
 * Create a detector with you custom model
   * Path of the custom model
   * Path of the label file
   * Image size expected by the model
   * Specify if the model is quantized
```dart
try {
  await FlutterTfliteDetector.createDetector(
      'assets/detector.tflite', 'assets/labels.txt', 300, true);
} on PlatformException catch (e) {
  debugPrint('Unable to create detector, ${e.message}');
}
``` 

 * Load an image and pass it to your detector
```dart
Future<bool> recognizeImageFromFile(String path) async {
  try {
    var imageBytes =
        (await rootBundle.load(path)).buffer;
  
    img.Image image = img.decodeJpg(imageBytes.asUint8List());
    image = img.copyResize(image, detector.imageSize, detector.imageSize); //stretch
  
      // Resize the image to the expected size for your model
      image = img.copyResize(image, detector.imageSize, detector.imageSize); //stretch
    
      var recognitions = await FlutterTfliteDetector.recognizeImage(image);
    return true;
  } on PlatformException {
    debugPrint('Unable to recognize image');
  }
  return false;
}

```