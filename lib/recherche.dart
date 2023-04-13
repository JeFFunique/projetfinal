import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'details.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'game.dart';
import 'accueil.dart';

class Recherche extends StatefulWidget {
  String s;

  Recherche({Key? key, required this.s}) : super(key: key);

  @override
  State<Recherche> createState() => _RechercheState();
}

class _RechercheState extends State<Recherche> {
  static Future<List<Game>> searchGame(String query) async {
    final response = await http.get(
        Uri.parse('https://steamcommunity.com/actions/SearchApps/$query'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<String> appIds = List<String>.from(
          jsonResponse.map((game) => game['appid'] as String));
      final List<Game> games = [];

      for (final gameId in appIds) {
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
  static Future<List<Game>> search(String query) async {
    final response = await http.get(
        Uri.parse('https://steamcommunity.com/actions/SearchApps/$query'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<String> appIds = List<String>.from(
          jsonResponse.map((game) => game['appid'] as String));
      final List<Game> games = [];

      for (final gameId in appIds) {
        print(gameId);
        final gameDetails = await http.get(Uri.parse(
            'https://store.steampowered.com/api/appdetails?appids=$gameId'));
        final gameDetailsJson = jsonDecode(gameDetails.body)['$gameId'];
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

  List<Game> gamesFound = [];
  int count = 0;

  @override
  void initState() {
    super.initState();
    searchGame(widget.s).then((games) {
      setState(() {
        gamesFound = games;
        count = gamesFound.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _searchController = TextEditingController(text: widget.s);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1A2025),
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: SvgPicture.asset(
                "images/close.svg",
                height: 16,
                width: 16,
                color: Colors.white,
              ),
            ),
            const Text('Recherche'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '$count résultat(s) trouvé(s)',
              style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF1A2025),
        ),
        child: FutureBuilder<List<Game>>(
          future: searchGame(widget.s),
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
        ),
      ),
    );
  }
}