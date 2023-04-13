import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'likes.dart';
import 'whish.dart';
import 'game.dart';
import 'variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart' ;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'gamerank.dart';




class Accueil extends StatelessWidget {

  Accueil({Key? key}) : super(key: key);

  void _logout() async {

  }


  bool Liked = false;
  late Game game;
  String getLike(int Id) => 'isLiked_$Id';
  bool Wished = false;
  String getWish(Id) => 'isWishlisted_$Id';
  static void addWish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Convertir les clés int en chaînes de caractères
      Map<String, String> gameWish = {};
      for (var k in wishedGamesID.keys) {
        gameWish[k.toString()] = wishedGamesID[k]!;
      }

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      if (await docRef.get().then((doc) => doc.exists)) {
        // Le document existe déjà, on met à jour les données
        await docRef.update({'wishist': gameWish});
      } else {
        // Le document n'existe pas encore, on le crée avec les données
        await docRef.set({'wishlist': gameWish});
      }
    }
  }

  void addLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {


      for (var k in likedGames.keys) {
        likedGames[k.toString()] = likedGamesID[k]!;
      }

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      if (await docRef.get().then((doc) => doc.exists)) {

        await docRef.update({'liked': likedGames});
      } else {

        await docRef.set({'liked': likedGames});
      }
    }
  }
  static Future<void> getLikedGames() async {


    likedGamesID.clear();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {


      final userData =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();


      final Map<String, dynamic> data = userData.data()!;


      final Map<dynamic, dynamic> likedGames = data['liked'] ?? {};


      final Map<int, String> likes = {};

      for (final k in likedGames.keys) {


        likes[int.parse(k)] = likedGames[k];

      }


      likedGamesID= likes;

    }
  }
  static Future<void> getUsersGameWish() async {


    wishedGamesID.clear();


    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {


      final userData =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();


      final Map<String, dynamic> data = userData.data()!;


      final Map<dynamic, dynamic> gameWish = data['wishlist'] ?? {};


      final Map<int, String> wish = {};

      for (final k in gameWish.keys) {


        wish[int.parse(k)] = gameWish[k];

      }


      wishedGamesID = wish;
    }
  }
  void getDatas() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  Liked = prefs.getBool(getLike(game.id)) ?? false;
  Wished = prefs.getBool(getWish(game.id)) ?? false;

}



  @override
  Widget build(BuildContext context) {
    getDatas();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        backgroundColor: const Color(0xFF1A2025),
        actions: <Widget>[
          IconButton(
            icon: Liked ? Image.network("https://icons8.com/icon/Vc9YanbCBRjT/like"): Image.network("https://icons8.com/icon/Vc9YanbCBRjT/like"),
            onPressed: () async {

                Liked = !Liked;
                if (Liked) {

                  likedGamesID[game.id] = game.name;
                } else {
                  likedGamesID.remove(game.id);
                }
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setBool(getLike(game.id), Liked);
                addLike();



            },
          ),
          IconButton(
            icon: Wished ? Image.network("https://icons8.com/icon/Vc9YanbCBRjT/like"): Image.network("https://icons8.com/icon/Vc9YanbCBRjT/like") ,
            onPressed: () async {
              Wished = !Wished;
              if (!Wished) {

                wishedGamesID[game.id] = game.name;
              } else {
                wishedGamesID.remove(game.id);
              }
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setBool(getWish(game.id), Wished);
              addWish();

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Whishs()),
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF1A2025),
        ),
        child: Column(
          children: [
            searchBar,
            GameBro(),
            const SizedBox(height: 5),
            Flexible(child: ListGames())
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        tooltip: 'Déconnexion',
        backgroundColor: const Color(0xFF1A2025),
        shape: const CircleBorder(
          side: BorderSide(
            color: Colors.white,
            width: 3,
          ),
        ),

        child: const Icon(Icons.logout),
      ),
    );
  }

  Widget searchBar = const Searchbar();
}

class Searchbar extends StatefulWidget {
  const Searchbar({Key? key}) : super(key: key);


  @override
  State<Searchbar> createState() => _SearchbarState();
}

class _SearchbarState extends State<Searchbar> {
  static Future<List<Game>> searchGame(String query) async {
    final response = await http.get(
        Uri.parse('https://steamcommunity.com/actions/SearchApps/$query'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<String> Ids = List<String>.from(
          jsonResponse.map((game) => game['appid'] as String));
      final List<Game> games = [];

      for (final gameId in Ids) {
        print(gameId);
        final gameDetailsResponse = await http.get(Uri.parse(
            'https://store.steampowered.com/api/appdetails?appids=$gameId'));
        final gameDetailsJson = jsonDecode(gameDetailsResponse.body)['$gameId'];
        if (gameDetailsJson != null && gameDetailsJson['data'] != null) {
          final gameFinal = Game.fromJson(gameDetailsJson['data']);
          games.add(gameFinal);
        }
        //final gameDetails = gameDetailsJson[gameId]['data'];


      }

      return games;
    } else {
      throw Exception('Failed to load games');
    }
  }

  final TextEditingController _searchController = TextEditingController();

  void _performSearch() {
    // Appeler la fonction pour récupérer les jeux via l'API
    String searchTerm = _searchController.text;
    // ...
    // Naviguer vers la page pour afficher les résultats de recherche

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2025),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(1),
            spreadRadius: 2,
            blurRadius: 3,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Rechercher un jeu...",
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search),
            color: const Color(0xFF636AF6),
            onPressed: _performSearch,
          ),
        ],
      ),
    );
  }
}

class GameBro extends StatelessWidget {
  const GameBro({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/details');
      },
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/affiche.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Counter Strike\nGlobal Offensive',
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/details');
                },
                child: const Text('En savoir plus'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListGames extends StatelessWidget {
  const ListGames({Key? key}) : super(key: key);

  @override
  static Future<List<Game>> getGames() async {

    final response = await http.get(Uri.parse(
        'https://api.steampowered.com/ISteamChartsService/GetMostPlayedGames/v1/'));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body)['response']['ranks'];
      final gamePopular = List<GameRank>.from(
          jsonResponse.map((json) => GameRank.fromJson(json)));
      final List<Game> games = [];

      for (final game in gamePopular.take(50)) {
        final gameId = game.id;
        final gameDetailsResponse = await http.get(Uri.parse(
            'https://store.steampowered.com/api/appdetails?appids=$gameId'));
        final gameDetails = jsonDecode(gameDetailsResponse.body)['$gameId'];
        if (gameDetails != null && gameDetails['data'] != null) {
          final gameFinal = Game.fromJson(gameDetails['data']);
          games.add(gameFinal);
        }



      }

      return games;
    } else {
      throw Exception('Failed to load games');
    }
  }

  Widget build(BuildContext context) {
    return FutureBuilder<List<Game>>(
      future: getGames(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final gamesList = snapshot.data!;
          return ListView.builder(
            itemCount: gamesList.length,
            itemBuilder: (context, index) {
              final game = gamesList[index];
              return GameLoading(game: game);
            },
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Failed to load games'),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class GameLoading extends StatelessWidget {
  final Game game ;
  const GameLoading({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Container(
            height: 100,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    game.image,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Editeur: ${game.editor}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prix: ${game.price}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF636AF6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              onTap: () {

              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Center(
                  child: Text(
                    'En savoir plus',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
