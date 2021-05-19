import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';

class TextIdentify {
  static Future<String> recogniseText(File imageFile) async {
    if (imageFile == null) {
      return 'No selected image';
    } else {
      TextDetector textDetector = GoogleMlKit.vision.textDetector();
      final inputImage = InputImage.fromFilePath(imageFile.path);

      try {
        final visionText = await textDetector.processImage(inputImage);
        await textDetector.close();
        final text = extractText(visionText);

        return text.isEmpty ? 'No text found in the image' : text;
      } catch (error) {
        return error.toString();
      }
    }
  }

  static extractText(RecognisedText visionText) {
    String text = '';
    for (TextBlock block in visionText.textBlocks) {
      for (TextLine line in block.textLines) {
        for (TextElement word in line.textElements) {
          text = text + word.getText + ' ';
        }
        text = text + '\n';
      }
    }
    return text;
  }
}
