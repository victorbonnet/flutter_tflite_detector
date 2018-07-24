import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_tflite_detector/model/recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image/image.dart';

class FlutterTfliteDetector {
  static const MethodChannel _channel =
      const MethodChannel('flutter_tflite_detector');

  static bool _isModelQuantized;
  static int _inputSize;
  static const double IMAGE_MEAN = 128.0;
  static const double IMAGE_STD = 128.0;

  static Future createDetector(String modelFile, String labelsFile, int inputSize, bool isModelQuantized) async {
    _inputSize = inputSize;
    _isModelQuantized = isModelQuantized;

    await _channel.invokeMethod('createDetector', {
      'modelFile': modelFile,
      'labelsFile': labelsFile,
      'inputSize': inputSize,
      'isQuantized': isModelQuantized,
    });
  }

  static Future closeDetector() async {
    _inputSize = null;
    _isModelQuantized = null;

    await _channel.invokeMethod('closeDetector');
  }


  static Future<List<Recognition>> recognizeImage(img.Image image) async {
    if (_inputSize == null) return null;

    var imgData;
    if (_isModelQuantized) {
      imgData = imageToByteList(image);
    } else {
      imgData = imageToFloatList(image);
    }

    final List result = await _channel.invokeMethod('recognizeImage', {
      'imgData': imgData,
    });

    List<Recognition> recognitions = [];
    result.forEach((i) {
      recognitions.add(Recognition.fromMap(i));
    });

    return recognitions;
  }

  static Uint8List imageToByteList(Image image) {
    var convertedBytes = new Uint8List(1 * _inputSize * _inputSize * 3);
    var buffer = new ByteData.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < _inputSize; i++) {
      for (var j = 0; j < _inputSize; j++) {
        var pixel = image.getPixel(i, j);
        buffer.setUint8(pixelIndex++, (pixel) & 0xFF);
        buffer.setUint8(pixelIndex++, (pixel >> 8) & 0xFF);
        buffer.setUint8(pixelIndex++, (pixel >> 16) & 0xFF);
      }
    }
    return convertedBytes;
  }

  static Float64List imageToFloatList(Image image) {
    var convertedBytes = new Float64List(1 * _inputSize * _inputSize * 3);
    var buffer = new ByteData.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < _inputSize; i++) {
      for (var j = 0; j < _inputSize; j++) {
        var pixel = image.getPixel(i, j);
        buffer.setFloat64(pixelIndex++, ((pixel & 0xFF) - IMAGE_MEAN) / IMAGE_STD);
        buffer.setFloat64(pixelIndex++, (((pixel >> 8) & 0xFF) - IMAGE_MEAN) / IMAGE_STD);
        buffer.setFloat64(pixelIndex++, (((pixel >> 16) & 0xFF) - IMAGE_MEAN) / IMAGE_STD);
      }
    }
    return convertedBytes;
  }
}
