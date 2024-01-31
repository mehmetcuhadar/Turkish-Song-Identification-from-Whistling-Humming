import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marquee/marquee.dart';
import 'package:ticker_text/ticker_text.dart';


class SecondPage extends StatelessWidget {
   SecondPage(
      {Key? key, required this.songTitle, required this.albumImage, required this.albumName,
        required this.artistName, required this.externalURL, required this.previewURL, required this.lyrics}) : super(key: key);
  final String songTitle;
  final String albumName;
  final String albumImage;
  final String artistName;
  final String previewURL;
  final String externalURL;
  final List<String> lyrics;

  bool previewPlaying = false;
  AudioPlayer x = AudioPlayer();
  static const IconData play_circle = IconData(0xe4cc, fontFamily: 'MaterialIcons');
  static const IconData stop_icon = IconData(0xe6cc, fontFamily: 'MaterialIcons');

   @override
   Widget build(BuildContext context) {
     // Get the screen width
     double screenWidth = MediaQuery.of(context).size.width;

     // Set the percentage width for the lyrics card
     double lyricsCardWidthPercentage = 1; // Adjust the percentage as needed

     // Calculate the actual width of the lyrics card
     double lyricsCardWidth = screenWidth * lyricsCardWidthPercentage;

     return Scaffold(
       backgroundColor: Color.fromARGB(1000,56,139,139),
       appBar: AppBar(
         backgroundColor: Colors.transparent,
         elevation: 0, // Remove the shadow
         leading: IconButton(
           icon: Icon(Icons.arrow_back, color:Colors.black),
           onPressed: () {
             Navigator.pop(context); // Navigate back to the MainPage
           },
         ),
       ),
       body: SingleChildScrollView(
         child: Card(
           //color: Colors.blueGrey.withBlue(100),
           color: Color.fromARGB(1000,56,139,139),
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(8),
           ),
           clipBehavior: Clip.antiAliasWithSaveLayer,
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: <Widget>[
               Container(
                 margin: const EdgeInsets.all(8),
                child: Card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(albumImage),
                  ),
                )
               ),
               Container(
                 padding: const EdgeInsets.fromLTRB(14, 15, 0, 0),
                 child:
                     Row(
                       children: <Widget>[
                         Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: <Widget>[
                               songTitle.length > 15 ?
                               Container(
                                 width : 220,
                                   child:
                                   TickerText(
                                     // default values
                                     scrollDirection: Axis.horizontal,
                                     speed: 40,
                                     startPauseDuration: const Duration(seconds: 1),
                                     endPauseDuration: const Duration(seconds: 1),
                                     returnDuration: const Duration(milliseconds: 800),
                                     primaryCurve: Curves.linear,
                                     returnCurve: Curves.linear,

                                     child: Text(songTitle,
                                         style: const TextStyle(
                                           fontSize: 30,
                                           color: Colors.black,
                                           fontWeight: FontWeight.w700,
                                         ),),
                                   ),
                               )
                                   : Text(songTitle,
                                 style: const TextStyle(
                                   fontSize: 30,
                                   color: Colors.black,
                                   fontWeight: FontWeight.w700,
                                 ),),
                             Container(height: 5),
                             Text(
                               artistName,
                               style: const TextStyle(
                                 fontSize: 20,
                                 color: Colors.black,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ]
                         ),
                         const Spacer(),
                         IconButton(
                           icon: Icon(
                             previewPlaying ? stop_icon : play_circle,
                             color: Colors.black.withOpacity(0.8),
                           ),
                           iconSize: 35,
                           onPressed: () {
                             if (previewPlaying == false) {
                               x.play(UrlSource(previewURL));
                               previewPlaying = true;
                             } else {
                               x.stop();
                               previewPlaying = false;
                             }
                           },
                         ),
                         IconButton(
                           icon: Image.asset('images/spotify.png',
                               ),
                           iconSize: 35,
                           onPressed: () async {
                             final Uri url = Uri.parse(externalURL);
                             if (!await launchUrl(url)) {
                               throw Exception('Could not launch $url');
                             }
                           },
                         )
                       ],
                     ),
                 ),

               Container(
                 width: lyricsCardWidth,
                 padding: const EdgeInsets.all(8),
                 child: Card(
                   color: Colors.black.withOpacity(0.4),
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: lyrics.map((line) {
                         return Text(
                           line,
                           style: TextStyle(
                             fontSize: 20,
                             color: Colors.white70,
                             fontWeight: FontWeight.bold,
                             height: 1.75,
                           ),
                         );
                       }).toList(),
                     ),
                   ),
                 ),
               ),
               Container(height: 5),
             ],
           ),
         ),
       ),
     );
   }

   Widget buildAnimatedText(String text) => Marquee(
     text: text,
     style: const TextStyle(
       fontSize: 30,
       color: Colors.black,
       fontWeight: FontWeight.w700,
     ),
     //blankSpace: 30,
   );



}