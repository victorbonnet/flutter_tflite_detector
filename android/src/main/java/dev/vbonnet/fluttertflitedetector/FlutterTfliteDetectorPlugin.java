package dev.vbonnet.fluttertflitedetector;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterTfliteDetectorPlugin */
public class FlutterTfliteDetectorPlugin implements MethodCallHandler {

  private static Registrar registrar;
  private Classifier detector;

  /** Plugin registration. */
  public static void registerWith(Registrar reg) {
    registrar = reg;

    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_tflite_detector");
    channel.setMethodCallHandler(new FlutterTfliteDetectorPlugin());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    switch (call.method) {
      case "createDetector":
        createDetector(call, result);
        break;

      case "closeDetector":
        closeDetector(call, result);
        break;

      case "recognizeImage":
        recognizeImage(call, result);
        break;

      default:
        result.notImplemented();
    }
  }

  private void createDetector(MethodCall call, Result result) {
    Object modelFileParam = call.argument("modelFile");
    if (modelFileParam == null) {
      result.error("0", "Missing parameter", "modelFile parameter is missing");
      return;
    }

    Object labeslFileParam = call.argument("labelsFile");
    if (labeslFileParam == null) {
      result.error("0", "Missing parameter", "labelFile parameter is missing");
      return;
    }

    Object inputSizeParam = call.argument("inputSize");
    if (inputSizeParam == null) {
      result.error("0", "Missing parameter", "inputSize parameter is missing");
      return;
    }

    Object isQuantizedParam = call.argument("isQuantized");
    if (isQuantizedParam == null) {
      result.error("0", "Missing parameter", "isQuantized parameter is missing");
      return;
    }

    String assetModelKey = registrar.lookupKeyForAsset(String.valueOf(modelFileParam));
    String assetLabelsKey = registrar.lookupKeyForAsset(String.valueOf(labeslFileParam));
    int inputSize = (int) inputSizeParam;
    boolean isQuantized = (boolean) isQuantizedParam;

    try {
      detector =
              TFLiteObjectDetectionAPIModel.create(
                      registrar.context().getAssets(),
                      assetModelKey,
                      assetLabelsKey,
                      inputSize,
                      isQuantized);
      result.success("Detector created");
    } catch (final IOException e) {
      result.error("1", "Unable to create detector", e);
    }
  }

  private void closeDetector(MethodCall call, Result result) {
    if (detector == null) {
      result.error("0", "No detector", "No detector");
      return;
    }

    detector.close();
    detector = null;
    result.success("Detector closed");
  }

  private void recognizeImage(MethodCall call, Result result) {
    Object imgDataParam = call.argument("imgData");
    if (imgDataParam == null) {
      result.error("0", "Missing parameter", "imgData parameter is missing");
      return;
    }

    if (detector == null) {
      result.error("0", "Detector not created", "Detector not created");
      return;
    }


    List<Classifier.Recognition> recognitions = detector.recognizeImage(imgDataParam);
    List<Map> res = new ArrayList<>();
    for (Classifier.Recognition recognition : recognitions) {
      res.add(recognition.toMap());
    }

    result.success(res);

  }
}
