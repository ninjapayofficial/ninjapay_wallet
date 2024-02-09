import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';

class SpotifyService {
  late SpotifyApi _spotify;

  SpotifyService() {
    var credentials = SpotifyApiCredentials(
        'bff4fd813ab3425eb6ce7a40ede660aa', // Replace with your actual client ID
        '17c0d132732e488b935fea78a7592dbc' // Replace with your actual client secret
        );
    _spotify = SpotifyApi(credentials);
  }

  Future<void> authenticate() async {
    // Implement the authentication logic here
  }

  // Future<void> fetchUsersPlaylists(SpotifyApi spotify) async {
  //   print('\nUser\'s playlists:');
  //   var usersPlaylists =
  //       await _spotify.playlists.getUsersPlaylists('superinteressante').all();
  //   usersPlaylists.forEach((playlist) => print(playlist.name));
  // }

  Future<List<PlaylistSimple>> getUserPlaylists() async {
    var playlistsStream = await _spotify.playlists.me.all(); // Get the Stream
    var playlists = await playlistsStream.toList(); // Convert Stream to List
    print(playlists);
    return playlists;
  }

  Future<void> addToQueue(String uri) async {
    await _spotify.me.addToQueue(uri);
  }
}

// Future<void> fetchUsersPlaylists(SpotifyApi spotify) async {
//   print('\nUser\'s playlists:');
//   var usersPlaylists =
//       await spotify.playlists.getUsersPlaylists('superinteressante').all();
//   usersPlaylists.forEach((playlist) => print(playlist.name));
// }

class SpotifyView extends StatefulWidget {
  SpotifyView({Key? key}) : super(key: key);

  @override
  _SpotifyViewState createState() => _SpotifyViewState();
}

class _SpotifyViewState extends State<SpotifyView> {
  late SpotifyService _spotifyService;
  List<PlaylistSimple> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _spotifyService = SpotifyService();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      var playlists = await _spotifyService.getUserPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle the error properly
      print('Error loading playlists: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spotify Playlists'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                var playlist = _playlists[index];
                return ListTile(
                  title: Text(playlist.name ?? 'Unknown Playlist'),
                  onTap: () {
                    // Here you can add logic to handle playlist selection
                  },
                );
              },
            ),
    );
  }
}
