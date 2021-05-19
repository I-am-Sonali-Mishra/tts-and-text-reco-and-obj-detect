import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class Tts extends StatefulWidget {
  @override
  _TtsState createState() => _TtsState();
}

class _TtsState extends State<Tts> {
  FlutterTts flutterTts;
  dynamic languages;
  dynamic voices;
  dynamic engines;
  String language;
  String voice;
  String engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  int num = 1;

  String newVoiceText;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  get isPaused => ttsState == TtsState.paused;

  get isContinued => ttsState == TtsState.continued;

  @override
  initState() {
    super.initState();
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();

    getLanguages();
    getVoices();

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        getEngines();
      }
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    if (kIsWeb || Platform.isIOS) {
      flutterTts.setPauseHandler(() {
        setState(() {
          print("Paused");
          ttsState = TtsState.paused;
        });
      });

      flutterTts.setContinueHandler(() {
        setState(() {
          print("Continued");
          ttsState = TtsState.continued;
        });
      });
    }

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);
  }

  Future getVoices() async {
    voices = await flutterTts.getVoices;
    if (voices != null) setState(() => voices);
  }

  Future getEngines() async {
    var engines = await flutterTts.getEngines;
    if (engines != null) {
      for (dynamic engine in engines) {
        print('Engine : $engine');
      }
    }
  }

  saveFile(String text) async {
    await flutterTts.synthesizeToFile(
        text, Platform.isAndroid ? "tts$num.wav" : "tts$num.caf");
    num++;
  }

  Future speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (newVoiceText != null) {
      if (newVoiceText.isNotEmpty) {
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(newVoiceText);
      }
    }
  }

  Future stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>.empty(growable: true);
    for (dynamic type in languages) {
      items.add(
          DropdownMenuItem(value: type as String, child: Text(type as String)));
    }
    return items;
  }

  void changedLanguageDropDownItem(String selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language);
    });
  }

  List<DropdownMenuItem<String>> getVoiceDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>.empty(growable: true);
    for (dynamic type in voices) {
      items.add(
          DropdownMenuItem(value: type as String, child: Text(type as String)));
    }
    return items;
  }

  void changedVoiceDropDownItem(String selectedType) {
    setState(() {
      voice = selectedType;
      flutterTts.setVoice(voice);
    });
  }

  void onChange(String text) {
    setState(() {
      newVoiceText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        inputSection(),
        btnSection(),
        languages != null ? languageDropDownSection() : Text(""),
        voices != null ? voiceDropDownSection() : Text(""),
        SizedBox(
          height: 50.0,
        ),
        buildSliders(),
        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => saveFile(newVoiceText),
            child: Text('Download'),
          ),
        ),
      ],
    );
  }

  Widget inputSection() => Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
      child: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
        ),
        toolbarOptions: ToolbarOptions(
          cut: true,
          copy: true,
          paste: true,
          selectAll: true,
        ),
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (String value) {
          onChange(value);
        },
      ));

  Widget btnSection() {
    if (!kIsWeb && Platform.isAndroid) {
      return Container(
          padding: EdgeInsets.only(top: 50.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            buildButtonColumn(Colors.green, Color(0xFF428e92), Icons.play_arrow,
                'PLAY', speak),
            buildButtonColumn(
                Colors.red, Colors.redAccent, Icons.stop, 'STOP', stop),
          ]));
    } else {
      return Container(
          padding: EdgeInsets.only(top: 50.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            buildButtonColumn(Colors.green, Colors.greenAccent,
                Icons.play_arrow, 'PLAY', speak),
            buildButtonColumn(
                Colors.red, Colors.redAccent, Icons.stop, 'STOP', stop),
            buildButtonColumn(
                Colors.blue, Colors.blueAccent, Icons.pause, 'PAUSE', pause),
          ]));
    }
  }

  Widget languageDropDownSection() => Container(
      padding: EdgeInsets.only(top: 50.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          hint: Text('Language'),
          underline: Container(
            height: 2.0,
            width: 50.0,
            color: Colors.lightBlueAccent,
          ),
          value: language,
          items: getLanguageDropDownMenuItems(),
          onChanged: changedLanguageDropDownItem,
        )
      ]));

  Widget voiceDropDownSection() => Container(
      padding: EdgeInsets.only(top: 50.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          hint: Text('                      Voice'),
          underline: Container(
            height: 2.0,
            width: 50.0,
            color: Colors.lightBlueAccent,
          ),
          value: voice,
          items: getVoiceDropDownMenuItems(),
          onChanged: changedVoiceDropDownItem,
        )
      ]));

  Column buildButtonColumn(Color color, Color splashColor, IconData icon,
      String label, Function func) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
              icon: Icon(icon),
              color: color,
              splashColor: splashColor,
              onPressed: () => func()),
          Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: color)))
        ]);
  }

  Widget buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 30.0,
          ),
          child: Text(
            'Volume',
          ),
        ),
        Volume(),
        Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: Text('Pitch'),
        ),
        Pitch(),
        Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: Text('Rate'),
        ),
        Rate()
      ],
    );
  }

  Widget Volume() {
    return Slider(
        value: volume,
        onChanged: (newVolume) {
          setState(() => volume = newVolume);
        },
        min: 0.0,
        max: 1.0,
        divisions: 10,
        label: "Volume: $volume");
  }

  Widget Pitch() {
    return Slider(
      value: pitch,
      onChanged: (newPitch) {
        setState(() => pitch = newPitch);
      },
      min: 0.5,
      max: 2.0,
      divisions: 15,
      label: "Pitch: $pitch",
    );
  }

  Widget Rate() {
    return Slider(
      value: rate,
      onChanged: (newRate) {
        setState(() => rate = newRate);
      },
      min: 0.0,
      max: 1.0,
      divisions: 10,
      label: "Rate: $rate",
    );
  }
}
