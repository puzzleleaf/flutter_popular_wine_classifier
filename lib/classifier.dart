import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Classifier {
  Interpreter _interpreter;
  Map<String, String> _labelDict;

  Classifier() {
    _loadModel();
    _loadLabel();
  }

  void _loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('models/popular_wine_V1_model.tflite');

    var inputShape = _interpreter.getInputTensor(0).shape;
    var outputShape = _interpreter.getOutputTensor(0).shape;

    print('Load Model - $inputShape / $outputShape');
  }

  void _loadLabel() async {
    final labelData = await rootBundle
        .loadString('assets/labels/popular_wine_V1_labelmap.txt');
    var dict = <String, String>{};

    final labelList = labelData.split('\n');
    for (var i = 0; i < labelList.length; i++) {
      var entry = labelList[i].trim().split('|');
      dict[entry[0]] = entry[1];
    }

    _labelDict = dict;

    print('Load Label');
  }

  Future<img.Image> loadImage(String imagePath) async {
    var originData = File(imagePath).readAsBytesSync();
    var originImage = img.decodeImage(originData);

    return originImage;
  }

  Future<List<dynamic>> runModel(img.Image loadImage) async {
    var modelImage = img.copyResize(loadImage, width: 224, height: 224);
    var modelInput = imageToByteListUint8(modelImage, 224);

    //[1, 409776]
    var outputsForPrediction = [List.generate(409776, (index) => 0.0)];

    _interpreter.run(modelInput.buffer, outputsForPrediction);

    Map<int, double> map = outputsForPrediction[0].asMap();
    var sortedKeys = map.keys.toList()
      ..sort((k1, k2) => map[k2].compareTo(map[k1]));

    List<dynamic> result = [];

    for (var i = 0; i < 30; i++) {
      result.add({
        'label': _labelDict[sortedKeys[i].toString()],
        'value': map[sortedKeys[i]],
      });
    }

    return result;
  }

  Uint8List imageToByteListUint8(img.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);

    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel);
        buffer[pixelIndex++] = img.getGreen(pixel);
        buffer[pixelIndex++] = img.getBlue(pixel);
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
