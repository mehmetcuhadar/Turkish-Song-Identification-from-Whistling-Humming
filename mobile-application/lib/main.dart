import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:test_app/past.dart';
import 'input.dart';
import 'package:flutter_voice_processor/flutter_voice_processor.dart';
import 'package:animated_icon/animated_icon.dart';


void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),

  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<StatefulWidget> createState() => FirstPage();
}

class FirstPage extends State<MyApp> {

  final int sampleRate = 44100;
  final int frameLength = 44100;
  final int volumeHistoryCapacity = 5;
  final double dbOffset = 50.0;

  final List<double> _volumeHistory = [];
  double _smoothedVolumeValue = 0.0;
  bool _isButtonDisabled = false;
  bool _isProcessing = false;
  String? _errorMessage;
  VoiceProcessor? _voiceProcessor;
  List<List<int>> audioFrames = [];
  bool listenerAdded = false;
  bool _animate = true;
  bool nav_flag = true;

  @override
  void initState() {
    super.initState();
    _initVoiceProcessor();
  }

  void _initVoiceProcessor() async {
    _voiceProcessor = VoiceProcessor.instance;
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double topMarginRatio = 0.25;

    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromARGB(1000,56,139,139),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0, // Remove the shadow
          actions: [
            IconButton(
              icon: Icon(Icons.history, size:30, color:Colors.black),
              onPressed: () {
                final myPastPage = MyPastPage();
                // Navigate to MyPastPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => myPastPage),
                );// Navigate to the past results
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: screenHeight * topMarginRatio),
                child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: buildStartButton(context),
                )

              ),

            ],
          ),
        ),

      ),
    );
  }

  navigatePastResults(){
    BuildContext currentContext = context;
    final myPastPage = MyPastPage();
    // Navigate to MyPastPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => myPastPage),
    );
  }

  buildStartButton(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        primary: Colors.white54,
        shape: CircleBorder(),
        textStyle: TextStyle(color: Colors.white));

    return [Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _isProcessing
                  ?
              const Text("Listening...",
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),):
              const Text("Tap to Start Humming",
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),),
             Container(height: 20),
            SizedBox(
              width: 150,
              height: 150,
              child: _isProcessing ?
              GestureDetector(
                onTap: ((_isButtonDisabled || _errorMessage != null) || (audioFrames.length < 8 && _isProcessing)) ?
                  null:
                    _toggleProcessing
                ,
                child:
                AvatarGlow(
                  startDelay: const Duration(milliseconds: 1000),
                  glowColor: Colors.white,
                  glowShape: BoxShape.circle,
                  animate: _animate,
                  curve: Curves.fastOutSlowIn,
                  child: const Material(
                    elevation: 8.0,
                    shape: CircleBorder(),
                    color: Colors.transparent,
                    child: CircleAvatar(
                      backgroundColor: Colors.white54,
                      radius: 50.0,
                      child: Icon(Icons.square_rounded, size:30, color:Colors.black),
                    ),
                  ),
                ),
              ) :
              ElevatedButton(
              style: buttonStyle,
              onPressed: _toggleProcessing,
              child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.mic, size: 50, color: Colors.black,)
              ],
              ),
              ),
            ),
            Container(height:10),
            (audioFrames.length < 8 && _isProcessing) ? const Text("Please continue", style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),) : const Text("")
          ]
      )

    )];
  }

  Future<void> _startProcessing() async {
    setState(() {
      _isButtonDisabled = true;
    });

    _voiceProcessor?.clearErrorListeners();
    _voiceProcessor?.clearFrameListeners();

    _voiceProcessor?.addFrameListener(_onFrame);
    _voiceProcessor?.addErrorListener(_onError);

    try {
      if (await _voiceProcessor?.hasRecordAudioPermission() ?? false) {
        await _voiceProcessor?.start(frameLength, sampleRate);
        bool? isRecording = await _voiceProcessor?.isRecording();
        setState(() {
          _isProcessing = isRecording as bool;
        });
      } else {
        setState(() {
          _errorMessage = "Recording permission not granted";
        });
      }
    } on PlatformException catch (ex) {
      setState(() {
        _errorMessage = "Failed to start recorder: " + ex.toString();
      });
    } finally {
      setState(() {
        _isButtonDisabled = false;
      });
    }
  }

  Future<void> _stopProcessing() async {
    setState(() {
      _isButtonDisabled = true;
    });

    try {
      await _voiceProcessor?.stop();
    } on PlatformException catch (ex) {
      setState(() {
        _errorMessage = "Failed to stop recorder: $ex";
      });
    } finally {
      bool? isRecording = await _voiceProcessor?.isRecording();
      setState(() {
        _isButtonDisabled = false;
        _isProcessing = isRecording as bool;
      });

      // Create a Map representation of the list of lists
      print(audioFrames.length);
      // Use the context provided in the build method
      BuildContext currentContext = context;
      final myHomePage = MyHomePage(audioFrames: audioFrames);
      // Navigate to MyHomePage

      audioFrames = [];
      if(nav_flag == true) {
        nav_flag = false;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => myHomePage),
        );
      }


    }
  }

  void _toggleProcessing() async {
    if (_isProcessing) {
      await _stopProcessing();
    } else {
      audioFrames = [];
      nav_flag = true;
      await _startProcessing();
    }
  }

  void _onFrame(List<int> frame) async {
    audioFrames.add(frame);
    if(audioFrames.length >= 10){
      await _stopProcessing();
    }
    double volumeLevel = 100;
    if (_volumeHistory.length == volumeHistoryCapacity) {
      _volumeHistory.removeAt(0);
    }
    _volumeHistory.add(volumeLevel);

    setState(() {
      _smoothedVolumeValue =
          _volumeHistory.reduce((a, b) => a + b) / _volumeHistory.length;
    });
  }

  void _onError(VoiceProcessorException error) {
    setState(() {
      _errorMessage = error.message;
    });
  }
}