import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(MemoryGame());
}

class MemoryGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jeu de Mémoire',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: MemoryGameScreen(),
    );
  }
}

class MemoryGameScreen extends StatefulWidget {
  @override
  _MemoryGameScreenState createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  List<String> _data = [
    '🍎',
    '🍌',
    '🍇',
    '🍉',
    '🍓',
    '🍒',
    '🍑',
    '🍍',
    '🍎',
    '🍌',
    '🍇',
    '🍉',
    '🍓',
    '🍒',
    '🍑',
    '🍍'
  ];
  List<bool> _visible = [];
  List<int> _selected = [];
  bool _waiting = false;
  int _score = 0;
  int _attempts = 0;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _bestScore = 9999;

  @override
  void initState() {
    super.initState();
    _data.shuffle();
    _visible = List<bool>.filled(_data.length, false);
    _loadBestScore();
    _startTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void _resetGame() {
    setState(() {
      _data.shuffle();
      _visible = List<bool>.filled(_data.length, false);
      _selected.clear();
      _score = 0;
      _attempts = 0;
      _stopwatch.reset();
      _startTimer();
    });
  }

  void _loadBestScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('bestScore') ?? 9999;
    });
  }

  void _saveBestScore(int score) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('bestScore', score);
  }

  void _checkMatch() async {
    _attempts += 1;
    if (_data[_selected[0]] == _data[_selected[1]]) {
      setState(() {
        _score += 1;
        _selected.clear();
        if (_score == _data.length ~/ 2) {
          _stopTimer();
          int totalTime = _stopwatch.elapsed.inSeconds + _attempts;
          if (totalTime < _bestScore) {
            _saveBestScore(totalTime);
            _bestScore = totalTime;
          }
          _showGameOverDialog();
        }
      });
    } else {
      setState(() {
        _waiting = true;
      });
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _visible[_selected[0]] = false;
        _visible[_selected[1]] = false;
        _selected.clear();
        _waiting = false;
      });
    }
  }

  void _onCardTap(int index) {
    if (!_visible[index] && !_waiting) {
      setState(() {
        _visible[index] = true;
        _selected.add(index);
        if (_selected.length == 2) {
          _checkMatch();
        }
      });
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Jeu Terminé!'),
          content: Text(
              'Votre score est: ${_stopwatch.elapsed.inSeconds + _attempts}\n'
              'Meilleur score: $_bestScore'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: Text('Rejouer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jeu de Mémoire - Score: $_score'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Temps: ${_stopwatch.elapsed.inSeconds}s'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Essais: $_attempts'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Meilleur score: $_bestScore'),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _data.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onCardTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _visible[index]
                          ? Text(_data[index], style: TextStyle(fontSize: 32))
                          : Icon(Icons.help_outline,
                              size: 32, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
