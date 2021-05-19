import 'object-detection/combine_screen.dart';
import 'package:flutter/material.dart';
import 'text-to-speech/tts.dart';
import 'theme/model.dart';
import 'package:provider/provider.dart';

class RoadMap extends StatefulWidget {
  @override
  _RoadMapState createState() => _RoadMapState();
}

class _RoadMapState extends State<RoadMap> {
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Text-to-Speech',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            actions: <Widget>[
              Switch(
                  value: themeChange.darkTheme,
                  onChanged: (bool value) {
                    themeChange.darkTheme = value;
                  }),
            ],
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.mic,
                    color: Colors.white,
                  ),
                ),
                Tab(
                    icon: Icon(
                  Icons.image,
                  color: Colors.white,
                )),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Tts(),
              ),
              TextRecognition(),
            ],
          ),
        ));
  }
}
