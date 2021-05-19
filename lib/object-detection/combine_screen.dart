import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:clipboard/clipboard.dart';
import 'text_area_widget.dart';
import '../text-recognition/google_text.dart';

const String ssd = "SSD MobileNet";

enum TtsState { playing, stopped, paused, continued }

class TextRecognition extends StatefulWidget {
  @override
  _TextRecognitionState createState() => _TextRecognitionState();
}

class _TextRecognitionState extends State<TextRecognition> {
  FlutterTts flutterTts = FlutterTts();
  TtsState ttsState = TtsState.stopped;
  String text = '';
  int num = 1;

  String recObject = 'Recognised objects are: ';
  String model = ssd;
  File finalImage;
  bool busy = false;
  List finalRecognitions;

  double imageWidth;
  double imageHeight;

  @override
  void initState() {
    super.initState();
    busy = true;
    loadModel().then((val) {
      setState(() {
        busy = false;
      });
    });
  }

  loadModel() async {
    Tflite.close();
    try {
      String res;
      if (model == ssd) {
        res = await Tflite.loadModel(
            model: 'assets/tflite/ssd_mobilenet.tflite',
            labels: 'assets/tflite/ssd_mobilenet.txt');
      }
      print(res);
    } on PlatformException {
      print('Failed to load the model.');
    }
  }

  ssdMobileNet(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
      threshold: 0.55,
      path: image.path,
      numResultsPerClass: 10,
    );

    setState(() {
      finalRecognitions = recognitions;
    });
  }

  List<Widget> renderBoxes(Size screen) {
    if (finalRecognitions == null) return [];
    if (imageWidth == null || imageHeight == null) return [];

    double factorX = screen.width;
    double factorY = imageHeight / imageHeight + screen.width;
    Color color = Colors.red;

    return finalRecognitions
        .map((re) => Positioned(
              left: re['rect']['x'] * factorX,
              top: re['rect']['y'] * factorY,
              width: re['rect']['w'] * factorX,
              height: re['rect']['h'] * factorY,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: color,
                    width: 3.0,
                  ),
                ),
                child: Text(
                  "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    background: Paint()..color = color,
                    color: Colors.white,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ))
        .toList(
          growable: true,
        );
  }

  speak(String text) async {
    await flutterTts.setLanguage('en-IN');
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  saveFile(String text) async {
    await flutterTts.synthesizeToFile(
        text, Platform.isAndroid ? "tr$num.wav" : "tr$num.caf");
    num++;
  }

  Future stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  predictImage(File image) async {
    if (image == null) return;

    if (model == ssd) {
      await ssdMobileNet(image);
    }
  }

  boundingBox(File image) {
    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            imageWidth = info.image.width.toDouble();
            imageHeight = info.image.height.toDouble();
          });
        })));

    setState(() {
      finalImage = image;
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];
    stackChildren.add(
      Expanded(child: buildImage()),
    );
    stackChildren.addAll(renderBoxes(size));

    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            const SizedBox(height: 25),
            Stack(
              children: stackChildren,
            ),
            const SizedBox(height: 80),
            Row(
              children: [
                SizedBox(width: 10.0),
                ElevatedButton(
                  child: Text('  Camera  '),
                  onPressed: pickCameraImage,
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: pickImage,
                  child: Text('    Gallery    '),
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: clear,
                  child: Text('    Clear    '),
                ),
                SizedBox(width: 10.0),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: scanText,
                  child: Text('Scan Text'),
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  child: Text('Scan Object'),
                  onPressed: () => scanObject(finalImage),
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () => scanAll(finalImage),
                  child: Text('Scan All  '),
                ),
                SizedBox(width: 10.0),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () => speak(text),
                  child: Text('     Play     '),
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () => stop(),
                  child: Text('      Stop       '),
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () => saveFile(text),
                  child: Text('Download'),
                ),
                SizedBox(width: 10.0),
              ],
            ),
            const SizedBox(height: 40),
            TextAreaWidget(
              text: text,
              onClickedCopy: copyToClipboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImage() => Container(
        child: finalImage != null
            ? Image.file(finalImage)
            : Icon(Icons.photo, size: 80, color: Colors.black),
      );

  Future pickImage() async {
    final file = await ImagePicker().getImage(source: ImageSource.gallery);
    setImage(File(file.path));
    setState(() {
      busy = false;
    });
  }

  Future pickCameraImage() async {
    final file = await ImagePicker().getImage(source: ImageSource.camera);
    setImage(File(file.path));
    setState(() {
      busy = false;
    });
  }

  Future scanText() async {
    setState(() {
      busy = false;
    });
    clearField();
    showDialog(
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
      context: context,
    );

    final text = await TextIdentify.recogniseText(finalImage);
    setText(text);

    Navigator.of(context).pop();
  }

  Future scanObject(File image) async {
    setState(() {
      busy = true;
    });
    predictImage(File(image.path));
    boundingBox(image);

    for (dynamic element in finalRecognitions) {
      recObject = recObject + element['detectedClass'] + ', ';
    }

    clearField();
    showDialog(
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
      context: context,
    );

    setText(recObject);

    Navigator.of(context).pop();
    setState(() {
      recObject = 'Recognised objects are: ';
    });
  }

  Future scanAll(File image) async {
    setState(() {
      busy = true;
    });
    predictImage(File(image.path));
    boundingBox(image);
    for (dynamic element in finalRecognitions) {
      recObject = recObject + element['detectedClass'] + ', ';
    }
    clearField();
    showDialog(
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
      context: context,
    );

    final text = await TextIdentify.recogniseText(finalImage);
    setText(text + recObject);

    Navigator.of(context).pop();
    setState(() {
      recObject = 'Recognised objects are: ';
    });
  }

  void clear() {
    setImage(null);
    setText('');
    setState(() {
      busy = false;
      finalRecognitions = null;
    });
  }

  void clearField() {
    setText('');
  }

  void copyToClipboard() {
    if (text.trim() != '') {
      FlutterClipboard.copy(text);
    }
  }

  void setImage(File newImage) {
    setState(() {
      finalImage = newImage;
    });
  }

  void setText(String newText) {
    setState(() {
      text = newText;
    });
  }
}
