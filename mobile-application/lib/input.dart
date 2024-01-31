import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:test_app/past.dart';
import 'card.dart';
import 'post.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class MyHomePage extends StatefulWidget {

  final List<List<int>> audioFrames;
  const MyHomePage({super.key, required this.audioFrames});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late Future<List<Post>> postsFuture;
  late List<Post> allPosts = [];
  late List<int> added = [0,0,0,0,0];
  List<String> result_percentages = [];

  @override
  initState(){
    postsFuture = getPosts();
  }

  Future<List<Post>> getPosts() async {
    final List<String> searchResults = await getModelResult();

    List<String> result_key = [];

    for(String el in searchResults){
      result_key.add(el.split("%")[0]);
      result_percentages.add(el.split("%")[1]);
    }


    for (String searchTerm in result_key) {
      print("-------------");
      print(searchTerm);
      //var url = Uri.parse("http://172.20.104.143:8080/search?q=$searchTerm");
      var url = Uri.parse("https://spotify-czoggtcjyq-og.a.run.app/search?q=$searchTerm");


      try {
        final response = await http.get(url, headers: {"Content-Type": "application/json"});

        if (response.statusCode == 200) {
          final List body = json.decode(response.body);
          if (body.isNotEmpty) {
            // Return only the top result for each search term
            final topPost = Post.fromJson(body.first);
            print(topPost);
            allPosts.add(topPost);
          }
        } else {
          print("Request failed with status: ${response.statusCode}");
          print("Response body: ${response.body}");
          // Handle error for the specific search term
        }
      } catch (e) {
        print("Error during HTTP request: $e");
        // Handle error for the specific search term
      }
    }
    return allPosts;
  }



  Future<List<String>> getLyrics(String songTitle, String artist) async {
    var url = Uri.parse('https://lyrics-czoggtcjyq-og.a.run.app/lyrics?title=$songTitle&artist=$artist');
    //var url = Uri.parse("http://172.20.104.143:4040/lyrics?title=$songTitle&artist=$artist");


    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON
        List<dynamic> data = json.decode(response.body);
        List<String> result = List<String>.from(data);
        return result;
      } else {
        // If the server did not return a 200 OK response, throw an exception.
        throw Exception('Failed to load data');
      }

    }
    catch (e) {
      print("Error during HTTP request: $e");
      // Return an empty list instead of throwing an exception
      return [];
    }

  }

   Future<List<String>> getModelResult() async {
    //Uri url = Uri.parse('http://192.168.1.34:9000');
    Uri url = Uri.parse('https://recognition-czoggtcjyq-og.a.run.app/');
    try {
      Map<String, dynamic> requestBody = {'data': widget.audioFrames};
      http.Response response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Print the response from the server
      print(response.body);
      List<dynamic> data = json.decode(response.body);
      List<String> result = List<String>.from(data);
      print(result);
      return result;
    }
    catch (e) {
      print("Error during HTTP request: $e");
      // Return an empty list instead of throwing an exception
      return [];
    }

  }


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double topMarginRatio = 0.02; // Adjust this ratio according to your preference
    double bottomMarginRatio = 0.03;

    return Scaffold(
      backgroundColor: Color.fromARGB(1000,56,139,139), // Set your desired background color here
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // Remove the shadow
        leading: IconButton(
        icon: Icon(Icons.arrow_back, color:Colors.black),
        onPressed: () {
          Navigator.pop(context); // Navigate back to the MainPage
        },
        ),
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
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: screenHeight * topMarginRatio, bottom: screenHeight * bottomMarginRatio),
            child: Text(
              "Top Matches",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: FutureBuilder<List<Post>>(
                future: postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    final posts = snapshot.data!;
                    return buildPosts(posts);
                  } else {
                    print("I am here");
                    return Text("No data available");
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget buildPosts(List<Post> posts) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () async {
            // Fetch lyrics before navigating to the SecondPage
            final lyrics = await getLyrics(post.songTitle, post.artistName);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SecondPage(
                  songTitle: post.songTitle,
                  albumName: post.albumName,
                  albumImage: post.albumImage,
                  artistName: post.artistName,
                  previewURL: post.previewURL,
                  externalURL: post.externalURL,
                  lyrics: lyrics ?? ['Lyrics not available'],
                ),
              ),
            );
          },
          child: Card(
            color: Colors.black.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
            ),
            elevation: 5, // Adjust the elevation as needed
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              height: 80, //100
              width: double.maxFinite,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                      child: Image.network(post.albumImage, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 5), //10
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start (left)
                      children: [
                            Text(
                              post.songTitle.length > 15
                                  ? '${post.songTitle.substring(0, 15)}...'
                                  : post.songTitle,
                              style: TextStyle(
                                fontSize: 16, //18
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              post.artistName,
                              style: TextStyle(
                                fontSize: 14, //16
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Container(height:4),
                            Text(
                              "${result_percentages[index]}%",
                              style: TextStyle(
                                fontSize: 14, //16
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.bold
                              ),
                            ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                    IconButton(
                        icon: added[index] == 1
                            ? Icon(Icons.remove, size:45, color: Colors.white70)
                            : Icon(
                          Icons.add_circle, size:45, color:Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            // Here we changing the icon.
                            added[index] = 1-added[index];
                            updatePastMatches(index, added[index]);
                            toastification.show(
                              context: context,
                              title: added[index] == 1 ? 'Song successfully added' : 'Song successfully removed',
                              autoCloseDuration: const Duration(seconds: 2),
                              style: ToastificationStyle.fillColored,
                              primaryColor: Colors.black,
                              backgroundColor: Colors.black.withOpacity(0.4),
                              foregroundColor: Colors.white70,
                              alignment: Alignment.bottomCenter,
                              showProgressBar: false,
                              icon: const Icon(Icons.check),
                            );

                          });
                        }),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }


   updatePastMatches(index, addOperation) async {
    String songTitle = allPosts[index].songTitle;
    String artistName = allPosts[index].artistName;

    String key = "$artistName $songTitle";

    final prefs = await SharedPreferences.getInstance();
    List<String> loadedList = prefs.getStringList('PastResult') ?? [];

    if(addOperation == 1){
      if(loadedList.contains(key)){
        print("already in the past matched list.");
      }
      else{
        // Use the methods mentioned earlier to modify the loaded list:
        loadedList.add("$artistName $songTitle");

        // Save the modified list back to shared preferences:
        await prefs.setStringList('PastResult', loadedList);
      }
    }else{
      loadedList.remove(key);
      await prefs.setStringList('PastResult', loadedList);
    }



  }



}