class Post {
  String artistName = "";
  String songTitle = "";
  String albumName = "";
  String albumImage = "";
  String previewURL = "";
  String externalURL = "";

  Post({required this.artistName, required this.songTitle, required this.albumName,
    required this.albumImage, required this.previewURL, required this.externalURL});

  // Adjusted the fromJson method to correctly map the JSON properties
  Post.fromJson(Map<String, dynamic> json) {

    artistName = json['artists'][0]['name'];
    songTitle = json['track']['name'];
    albumName =  json['album']['name'];
    albumImage =  json['images'][0]['url'];
    previewURL = json['track']['preview_url'] ?? "";
    externalURL = json['track']['external_urls'];
  }
}
