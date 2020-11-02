import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_popular_wine_classifier/classifier.dart';
import 'package:image/image.dart' as img;

class ClassifierPage extends StatefulWidget {
  @override
  _ClassifierPageState createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  CameraController _controller;
  Classifier _classifier;

  @override
  void initState() {
    super.initState();
    initCamera();
    _classifier = Classifier();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    onNewCameraSelected(firstCamera);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (_controller.value.hasError) {
        print('Camera Error');
      }
    });

    try {
      await _controller.initialize();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: CameraPreview(_controller),
                ),
              ),
            ),
            Ink(
              width: 100,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[500],
                    offset: Offset(4.0, 4.0),
                    blurRadius: 15.0,
                    spreadRadius: 1.0,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-4.0, -4.0),
                    blurRadius: 15.0,
                    spreadRadius: 1.0,
                  )
                ],
              ),
              child: IconButton(
                iconSize: 50.0,
                onPressed: () {
                  _runModel(context);
                },
                icon: Icon(
                  Icons.wine_bar,
                  color: Colors.black,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _runModel(context) async {
    try {
      if (_controller == null || !_controller.value.isInitialized) {
        return;
      }

      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      await _controller.takePicture(path);

      var loadImage = await _classifier.loadImage(path);
      var loadResult = await _classifier.runModel(loadImage);
      _showModalBottomSheet(context, loadImage, loadResult);
    } catch (e) {
      print(e);
    }
  }

  void _showModalBottomSheet(context, loadImage, loadResult) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        builder: (BuildContext bc) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.only(
              top: 10,
              left: 5,
              right: 5,
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    img.encodeJpg(loadImage),
                    height: 300,
                  ),
                ),
                Expanded(
                  child: Container(
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${index + 1}. ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    loadResult[index]['label'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              loadResult[index]['value'].toString(),
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          ],
                        );
                      },
                      itemCount: loadResult.length,
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }
}
