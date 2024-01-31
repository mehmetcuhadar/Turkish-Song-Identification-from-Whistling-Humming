import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'card.dart';
import 'main.dart';
import 'post.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPastPage extends StatefulWidget {
  const MyPastPage({super.key});

  @override
  State<MyPastPage> createState() => _MyPastPageState();
}

class _MyPastPageState extends State<MyPastPage> {

  late Future<List<Post>> postsFuture;

  @override
  initState(){
    postsFuture = getPosts();
  }

  Future<List<Post>> getPosts() async {
    final List<String> pastResults = await getPastResult();
    List<Post> allPosts = [];

    for (String searchTerm in pastResults) {
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

  Future<List<String>> getPastResult() async {
    // Load the list from shared preferences
    final prefs = await SharedPreferences.getInstance();
    List<String> loadedList = prefs.getStringList('PastResult') ?? [];
    return loadedList;
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
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: screenHeight * topMarginRatio, bottom: screenHeight * bottomMarginRatio),
            child: Text(
              "Past Matches",
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
              height: 80,
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
                  const SizedBox(width: 5),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          post.artistName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }



}