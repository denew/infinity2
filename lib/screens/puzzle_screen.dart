import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../colours.dart';
import '../models.dart';
import '../game_engine.dart';
import '../hex_models.dart';
import '../hex_painters.dart';
import '../hex_game_engine.dart';
import '../strings.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart'; // For paymentService
import '../widgets/tip_dialog.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({Key? key}) : super(key: key);

  @override
  _PuzzleScreenState createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  int cols = 4;
  int rows = 4;
  String _boardSizeStr = '4 x 4';
  DisplayMode _displayMode = DisplayMode.colours;

  late GameEngine engine;
  HexGameEngine? hexEngine;
  bool _isHexMode = false;

  int? draggedIndex;
  bool isSolving = false;

  bool _showSplash = false;
  bool _splashOptOutChecked = false;
  bool _showHelpInfo = false;
  bool _showTimer = false;
  bool _isFlatMode = false;
  bool _isUnlocked = false;
  double _sliderValue = 1.0;
  Timer? _timer;
  int _secondsElapsed = 0;
  List<List<PatternData>> _splashPatterns = [];

  @override
  void initState() {
    super.initState();
    engine = GameEngine(cols, rows);
    _showSplash = true;
    _initSplashPatterns();
    _loadPrefs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initSplashPatterns() {
    math.Random random = math.Random();
    _splashPatterns = List.generate(9, (_) {
      return [
        PatternData(
            Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
            Colors.black,
            0,
            0),
        PatternData(
            Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
            Colors.black,
            0,
            0),
        PatternData(
            Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
            Colors.black,
            0,
            0),
        PatternData(
            Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
            Colors.black,
            0,
            0),
      ];
    });
  }

  void _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showSplash = prefs.getBool('showSplash') ?? true;
      _splashOptOutChecked = !_showSplash;
      _showTimer = prefs.getBool('showTimer') ?? false;
      _isFlatMode = prefs.getBool('isFlatMode') ?? false;
      _isUnlocked = prefs.getBool('isUnlocked') ?? false;
    });

    String? savedSize = prefs.getString('boardSizeStr');
    if (savedSize != null) {
      _applyBoardSize(savedSize, initGame: true, loadState: true);
    } else {
      _initGame();
    }
  }

  void _applyBoardSize(String sizeStr,
      {bool initGame = false, bool loadState = false}) {
    List<String> parts;
    int val1 = 4, val2 = 4;

    if (sizeStr.startsWith('Hex')) {
      _isHexMode = true;
      parts = sizeStr.replaceAll('Hex ', '').split(' x ');
    } else {
      _isHexMode = false;
      parts = sizeStr.split(' x ');
    }

    val1 = int.parse(parts[0]);
    val2 = int.parse(parts[1]);

    if (!mounted) return;
    setState(() {
      _boardSizeStr = sizeStr;
      switch (sizeStr) {
        case '3 x 3':
          _sliderValue = 0.0;
          break;
        case '4 x 4':
          _sliderValue = 1.0;
          break;
        case '4 x 5':
          _sliderValue = 2.0;
          break;
        case '6 x 4':
          _sliderValue = 3.0;
          break;
        case '7 x 4':
          _sliderValue = 4.0;
          break;
        case '8 x 4':
          _sliderValue = 5.0;
          break;
        case 'Hex 3 x 3':
          _sliderValue = 6.0;
          break;
        case 'Hex 4 x 4':
          _sliderValue = 7.0;
          break;
        case 'Hex 5 x 4':
          _sliderValue = 8.0;
          break;
      }
      double screenW = MediaQuery.of(context).size.width;
      double screenH = MediaQuery.of(context).size.height;
      if (screenH > screenW) {
        rows = math.max(val1, val2);
        cols = math.min(val1, val2);
      } else {
        cols = math.max(val1, val2);
        rows = math.min(val1, val2);
      }
      if (_isHexMode) {
        hexEngine = HexGameEngine(cols, rows);
      } else {
        engine = GameEngine(cols, rows);
      }
    });

    if (initGame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initGame(loadState: loadState);
        }
      });
    }
  }

  void _setSplashPrefs(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showSplash', val);
  }

  void _toggleTimer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTimer', value);
    setState(() {
      _showTimer = value;
      if (value) {
        _startTimer();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  void _toggleFlatMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFlatMode', value);
    setState(() {
      _isFlatMode = value;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    if (_showTimer) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (engine.isSolved() || _secondsElapsed >= 5999) {
          timer.cancel();
        } else {
          setState(() {
            _secondsElapsed++;
          });
        }
      });
    }
  }

  void _initGame({bool loadState = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (_isHexMode && hexEngine != null) {
        hexEngine!.initGame();
        if (loadState) {
          String? s = prefs.getString('saved_hex_state');
          if (s != null) hexEngine!.importState(s);
        }
      } else {
        engine.initGame();
        if (loadState) {
          String? s = prefs.getString('saved_square_state');
          if (s != null) engine.importState(s);
        }
      }
      draggedIndex = null;
      _secondsElapsed = loadState ? (prefs.getInt('saved_time') ?? 0) : 0;
      isSolving = false;
      if (_showTimer) {
        _startTimer();
      }
    });
  }

  void _hint() async {
    if (isSolving) return;

    List<int> incompleteIndices = [];
    if (_isHexMode && hexEngine != null) {
      for (int i = 0; i < hexEngine!.grid.length; i++) {
        if (hexEngine!.grid[i].id != i || hexEngine!.grid[i].turns % 6 != 0) {
          incompleteIndices.add(i);
        }
      }
    } else {
      for (int i = 0; i < engine.grid.length; i++) {
        if (engine.grid[i].id != i || engine.grid[i].turns % 4 != 0) {
          incompleteIndices.add(i);
        }
      }
    }

    if (incompleteIndices.isEmpty) return;

    incompleteIndices.shuffle();
    int missingPieceId = incompleteIndices.first;

    if (missingPieceId == -1) return;

    setState(() {
      isSolving = true;
    });

    if (_isHexMode && hexEngine != null) {
      hexEngine!.hintCount++;
      int currentIdx =
          hexEngine!.grid.indexWhere((p) => p.id == missingPieceId);
      if (currentIdx != missingPieceId) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() {
          var temp = hexEngine!.grid[missingPieceId];
          hexEngine!.grid[missingPieceId] = hexEngine!.grid[currentIdx];
          hexEngine!.grid[currentIdx] = temp;
          hexEngine!.moveCount++;
        });
      }

      if (hexEngine!.grid[missingPieceId].turns % 6 != 0) {
        int rotsNeeded = (6 - (hexEngine!.grid[missingPieceId].turns % 6)) % 6;
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() {
          for (int r = 0; r < rotsNeeded; r++) {
            hexEngine!.grid[missingPieceId].rotate();
            hexEngine!.moveCount++;
          }
        });
      }
    } else {
      engine.hintCount++;
      int currentIdx = engine.grid.indexWhere((p) => p.id == missingPieceId);

      if (currentIdx != missingPieceId) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() {
          PieceData temp = engine.grid[missingPieceId];
          engine.grid[missingPieceId] = engine.grid[currentIdx];
          engine.grid[currentIdx] = temp;
          engine.moveCount++;
        });
      }

      if (engine.grid[missingPieceId].turns % 4 != 0) {
        int rotsNeeded = (4 - (engine.grid[missingPieceId].turns % 4)) % 4;
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() {
          for (int r = 0; r < rotsNeeded; r++) {
            engine.grid[missingPieceId].rotate();
            engine.moveCount++;
          }
        });
      }
    }

    if (mounted) {
      setState(() {
        isSolving = false;
      });
    }
  }

  void _giveUp() async {
    if (isSolving) return;
    setState(() {
      isSolving = true;
      if (_isHexMode && hexEngine != null) {
        hexEngine!.usedGiveUp = true;
      } else {
        engine.usedGiveUp = true;
      }
    });

    List<PuzzleMove> moves = [];

    if (_isHexMode && hexEngine != null) {
      List<HexPieceData> tempGrid = hexEngine!.grid
          .map((p) =>
              HexPieceData(p.id, List.from(p.baseEdges))..turns = p.turns)
          .toList();

      List<int> toFix = List.generate(tempGrid.length, (i) => i);
      toFix.shuffle();

      for (int i in toFix) {
        int targetIdx = tempGrid.indexWhere((p) => p.id == i);
        if (targetIdx != i) {
          moves.add(PuzzleMove.swap(i, targetIdx));
          var temp = tempGrid[i];
          tempGrid[i] = tempGrid[targetIdx];
          tempGrid[targetIdx] = temp;
        }
        if (tempGrid[i].turns % 6 != 0) {
          int rotsNeeded = (6 - (tempGrid[i].turns % 6)) % 6;
          moves.add(PuzzleMove.rotate(i, rotsNeeded));
          for (int r = 0; r < rotsNeeded; r++) {
            tempGrid[i].rotate();
          }
        }
      }

      for (var move in moves) {
        if (!mounted) break;
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          if (move.type == 'swap') {
            var temp = hexEngine!.grid[move.idx1];
            hexEngine!.grid[move.idx1] = hexEngine!.grid[move.idx2];
            hexEngine!.grid[move.idx2] = temp;
            hexEngine!.moveCount++;
          } else if (move.type == 'rotate') {
            for (int i = 0; i < move.rotations; i++) {
              hexEngine!.grid[move.idx1].rotate();
              hexEngine!.moveCount++;
            }
          }
        });
      }
    } else {
      List<PieceData> tempGrid = engine.grid
          .map((p) =>
              PieceData(p.id, p.baseTop, p.baseRight, p.baseBottom, p.baseLeft)
                ..turns = p.turns)
          .toList();

      List<int> toFix = List.generate(tempGrid.length, (i) => i);
      toFix.shuffle();

      for (int i in toFix) {
        int targetIdx = tempGrid.indexWhere((p) => p.id == i);
        if (targetIdx != i) {
          moves.add(PuzzleMove.swap(i, targetIdx));
          PieceData temp = tempGrid[i];
          tempGrid[i] = tempGrid[targetIdx];
          tempGrid[targetIdx] = temp;
        }
        if (tempGrid[i].turns % 4 != 0) {
          int rotsNeeded = (4 - (tempGrid[i].turns % 4)) % 4;
          moves.add(PuzzleMove.rotate(i, rotsNeeded));
          for (int r = 0; r < rotsNeeded; r++) {
            tempGrid[i].rotate();
          }
        }
      }

      for (var move in moves) {
        if (!mounted) break;
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          if (move.type == 'swap') {
            PieceData temp = engine.grid[move.idx1];
            engine.grid[move.idx1] = engine.grid[move.idx2];
            engine.grid[move.idx2] = temp;
            engine.moveCount++;
          } else if (move.type == 'rotate') {
            for (int i = 0; i < move.rotations; i++) {
              engine.grid[move.idx1].rotate();
              engine.moveCount++;
            }
          }
        });
      }
    }

    if (mounted) {
      setState(() {
        isSolving = false;
      });
    }
  }

  void _swapPieces(int sourceIdx, int targetIdx) {
    if (sourceIdx == targetIdx || isSolving) return;
    setState(() {
      if (_isHexMode && hexEngine != null) {
        var temp = hexEngine!.grid[sourceIdx];
        hexEngine!.grid[sourceIdx] = hexEngine!.grid[targetIdx];
        hexEngine!.grid[targetIdx] = temp;
        hexEngine!.moveCount++;
      } else {
        PieceData temp = engine.grid[sourceIdx];
        engine.grid[sourceIdx] = engine.grid[targetIdx];
        engine.grid[targetIdx] = temp;
        engine.moveCount++;
      }
      draggedIndex = null;
    });
  }

  void _onSliderChanged(double value) {
    if (isSolving) return;

    if (!_isUnlocked && value > 2) {
      value = 2;
    }

    setState(() {
      _sliderValue = value;
    });
  }

  void _onSliderChangeEnd(double value) async {
    if (isSolving) return;

    if (!_isUnlocked && value > 2) {
      value = 2;
    }

    int intValue = value.round();

    String newSize;
    switch (intValue) {
      case 0:
        newSize = '3 x 3';
        break;
      case 1:
        newSize = '4 x 4';
        break;
      case 2:
        newSize = '4 x 5';
        break;
      case 3:
        newSize = '6 x 4';
        break;
      case 4:
        newSize = '7 x 4';
        break;
      case 5:
        newSize = '8 x 4';
        break;
      case 6:
        newSize = 'Hex 3 x 3';
        break;
      case 7:
        newSize = 'Hex 4 x 4';
        break;
      case 8:
        newSize = 'Hex 5 x 4';
        break;
      default:
        newSize = '4 x 4';
        break;
    }

    if (newSize != _boardSizeStr) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('boardSizeStr', newSize);
      _applyBoardSize(newSize, initGame: true);
    }
  }

  void _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_moves',
        _isHexMode ? (hexEngine?.moveCount ?? 0) : engine.moveCount);
    await prefs.setInt('saved_hints',
        _isHexMode ? (hexEngine?.hintCount ?? 0) : engine.hintCount);
    await prefs.setInt('saved_time', _secondsElapsed);

    if (_isHexMode && hexEngine != null) {
      await prefs.setString('saved_hex_state', hexEngine!.exportState());
    } else {
      await prefs.setString('saved_square_state', engine.exportState());
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.gameStateSaved)),
      );
    }
  }

  void _showUnlockDialog() async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => TipDialog(paymentService: paymentService),
    );

    if (success == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isUnlocked', true);
      setState(() {
        _isUnlocked = true;
      });
    }
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(AppStrings.difficulty,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    inactiveTrackColor: _isUnlocked
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    activeTrackColor: Colors.blue,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    min: 0,
                    max: 8,
                    divisions: 8,
                    onChanged: _onSliderChanged,
                    onChangeEnd: _onSliderChangeEnd,
                    label: [
                      "3x3",
                      "4x4",
                      "4x5",
                      "6x4",
                      "7x4",
                      "8x4",
                      "Hex 3x3",
                      "Hex 4x4",
                      "Hex 5x4"
                    ][_sliderValue.round()],
                    activeColor: _sliderValue > 2 && !_isUnlocked
                        ? Colors.grey
                        : Colors.blue,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_isUnlocked ? Icons.save : Icons.lock,
                    color: Colors.amber),
                onPressed: _isUnlocked ? _saveGame : _showUnlockDialog,
              ),
            ],
          ),
          Text(
              _showTimer
                  ? '${AppStrings.progress}: ${_isHexMode ? (hexEngine?.moveCount ?? 0) : engine.moveCount}, ${AppStrings.hints}: ${_isHexMode ? (hexEngine?.hintCount ?? 0) : engine.hintCount} / ${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, "0")}'
                  : '${AppStrings.moves}: ${_isHexMode ? (hexEngine?.moveCount ?? 0) : engine.moveCount}, ${AppStrings.hints}: ${_isHexMode ? (hexEngine?.hintCount ?? 0) : engine.hintCount}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool solved =
        _isHexMode ? (hexEngine?.isSolved() ?? false) : engine.isSolved();
    double screenWidth = MediaQuery.of(context).size.width - 32;
    double screenHeight = MediaQuery.of(context).size.height -
        240 -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: _showSplash
          ? null
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Indefinitely',
                      style: GoogleFonts.secularOne(fontSize: 22)),
                  Text(AppStrings.crazyToTry,
                      style: const TextStyle(
                          fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                if (!solved)
                  TextButton(
                    onPressed: isSolving ? null : _hint,
                    child: Text(AppStrings.hint,
                        style: const TextStyle(
                            color: Colors.yellowAccent,
                            fontWeight: FontWeight.bold)),
                  ),
                if (!solved)
                  TextButton(
                    onPressed: isSolving ? null : _giveUp,
                    child: Text(AppStrings.giveUp,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: isSolving ? null : () => _initGame(),
                )
              ],
            ),
      drawer: _showSplash
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Color(0xFF1E1E2C)),
                    child: Text('Indefinitely',
                        style: TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: Text(AppStrings.showTimer),
                    trailing: Switch(
                      value: _showTimer,
                      onChanged: (val) {
                        _toggleTimer(val);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Opacity(
                    opacity: _isHexMode ? 0.5 : 1.0,
                    child: ListTile(
                      leading: const Icon(Icons.style),
                      title: Text(AppStrings.flatStyle),
                      enabled: !_isHexMode,
                      trailing: Switch(
                        value: _isFlatMode,
                        onChanged: _isHexMode
                            ? null
                            : (val) {
                                _toggleFlatMode(val);
                                Navigator.pop(context);
                              },
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: Text(AppStrings.displayMode),
                    trailing: DropdownButton<DisplayMode>(
                      value: _displayMode,
                      underline: const SizedBox(),
                      iconEnabledColor: Colors.white,
                      dropdownColor: const Color(0xFF2C2C3E),
                      style: const TextStyle(color: Colors.white),
                      items: DisplayMode.values.map((DisplayMode value) {
                        return DropdownMenuItem<DisplayMode>(
                          value: value,
                          child: Text(AppStrings.getDisplayMode(value)),
                        );
                      }).toList(),
                      onChanged: (DisplayMode? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _displayMode = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(AppStrings.language),
                    trailing: DropdownButton<String>(
                      value: AppStrings.currentLanguageCode,
                      underline: const SizedBox(),
                      iconEnabledColor: Colors.white,
                      dropdownColor: const Color(0xFF2C2C3E),
                      style: const TextStyle(color: Colors.white),
                      items: AppStrings.supportedLanguages.map((lang) {
                        return DropdownMenuItem<String>(
                          value: lang['code'],
                          child: Text('${lang['flag']} ${lang['name']}'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) async {
                        if (newValue != null) {
                          await AppStrings.setLanguage(newValue);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_open),
                    title: Text(AppStrings.resetPadlock),
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isUnlocked', false);
                      setState(() {
                        _isUnlocked = false;
                        _sliderValue = 2.0;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(AppStrings.help),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _showHelpInfo = true;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: Text(AppStrings.showSplashScreen),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _showSplash = true;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Exit Game'),
                    onTap: () {
                      SystemNavigator.pop();
                    },
                  ),
                ],
              ),
            ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildControls(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Opacity(
                    opacity: solved ? 1.0 : 0.0,
                    child: Text(
                        (_isHexMode
                                ? (hexEngine?.usedGiveUp ?? false)
                                : engine.usedGiveUp)
                            ? AppStrings.puzzleSolved
                            : AppStrings.puzzleSolvedGreatJob,
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                _buildGameGrid(screenWidth, screenHeight),
              ],
            ),
          ),
          if (_showHelpInfo && !_showSplash) _buildHelpOverlay(),
          if (_showSplash) _buildSplashScreen(),
        ],
      ),
    );
  }

  Widget _buildGameGrid(double screenWidth, double screenHeight) {
    if (_isHexMode && hexEngine != null) {
      double pieceSizeW = screenWidth / ((cols - 1) * 0.75 + 1.0);
      double pieceSizeH = screenHeight / ((rows + 0.5) * math.sqrt(3) / 2);
      double pieceSize = math.min(pieceSizeW, pieceSizeH);
      if (pieceSize <= 0) pieceSize = 50.0;
      double hexW = pieceSize;
      double hexH = pieceSize * math.sqrt(3) / 2;

      double boardWidth = ((cols - 1) * 0.75 + 1.0) * hexW;
      double boardHeight = (rows + 0.5) * hexH;

      return Expanded(
        child: Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: hexEngine!.grid.asMap().entries.map((entry) {
                int idx = entry.key;
                HexPieceData piece = entry.value;

                int col = idx % cols;
                int row = idx ~/ cols;

                double left = col * hexW * 0.75;
                double top = row * hexH + (col % 2 == 1 ? hexH / 2 : 0);

                Widget pieceWidget = GestureDetector(
                  onTap: isSolving
                      ? null
                      : () {
                          setState(() {
                            piece.rotate();
                            hexEngine!.moveCount++;
                          });
                        },
                  onDoubleTap: isSolving
                      ? null
                      : () {
                          setState(() {
                            piece.rotateAntiClockwise();
                            hexEngine!.moveCount++;
                          });
                        },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedRotation(
                        turns: piece.turns / 6.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: CustomPaint(
                          size: Size(hexW - 2, hexH - 2),
                          painter: HexPiecePainter(
                            mode: _displayMode,
                            isFlat: _isFlatMode,
                            pieceTurns: piece.turns,
                            edgeData: [
                              hexEngine!.patterns[piece.baseEdges[0]]!,
                              hexEngine!.patterns[piece.baseEdges[1]]!,
                              hexEngine!.patterns[piece.baseEdges[2]]!,
                              hexEngine!.patterns[piece.baseEdges[3]]!,
                              hexEngine!.patterns[piece.baseEdges[4]]!,
                              hexEngine!.patterns[piece.baseEdges[5]]!,
                            ],
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: Size(hexW - 2, hexH - 2),
                        painter: HexOverlayPainter(
                          mode: _displayMode,
                          isFlat: _isFlatMode,
                          edgeData: [
                            hexEngine!.patterns[piece.getEdge(0)]!,
                            hexEngine!.patterns[piece.getEdge(1)]!,
                            hexEngine!.patterns[piece.getEdge(2)]!,
                            hexEngine!.patterns[piece.getEdge(3)]!,
                            hexEngine!.patterns[piece.getEdge(4)]!,
                            hexEngine!.patterns[piece.getEdge(5)]!,
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                return AnimatedPositioned(
                  key: ValueKey(piece.id),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: left,
                  top: top,
                  width: hexW,
                  height: hexH,
                  child: DragTarget<int>(
                    onWillAccept: (src) {
                      return src != idx;
                    },
                    onAccept: (sourceIdx) {
                      _swapPieces(sourceIdx, idx);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Draggable<int>(
                        data: idx,
                        maxSimultaneousDrags: isSolving ? 0 : 1,
                        childWhenDragging:
                            Opacity(opacity: 0.3, child: pieceWidget),
                        feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                                width: hexW, height: hexH, child: pieceWidget)),
                        child: pieceWidget,
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    } else {
      double pieceSizeW = screenWidth / cols;
      double pieceSizeH = screenHeight / rows;
      double pieceSize = math.min(pieceSizeW, pieceSizeH);
      if (pieceSize <= 0) pieceSize = 50.0;
      double boardWidth = pieceSize * cols;
      double boardHeight = pieceSize * rows;

      return Expanded(
        child: Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Stack(
              children: engine.grid.asMap().entries.map((entry) {
                int idx = entry.key;
                PieceData piece = entry.value;

                double left = (idx % cols) * pieceSize;
                double top = (idx ~/ cols) * pieceSize;

                Widget pieceWidget = GestureDetector(
                  onTap: isSolving
                      ? null
                      : () {
                          setState(() {
                            piece.rotate();
                            engine.moveCount++;
                          });
                        },
                  onDoubleTap: isSolving
                      ? null
                      : () {
                          setState(() {
                            piece.rotateAntiClockwise();
                            engine.moveCount++;
                          });
                        },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedRotation(
                        turns: piece.turns / 4.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: CustomPaint(
                          size: Size(pieceSize - 2, pieceSize - 2),
                          painter: PiecePainter(
                            mode: _displayMode,
                            isFlat: _isFlatMode,
                            pieceTurns: piece.turns,
                            topData: engine.patterns[piece.baseTop]!,
                            rightData: engine.patterns[piece.baseRight]!,
                            bottomData: engine.patterns[piece.baseBottom]!,
                            leftData: engine.patterns[piece.baseLeft]!,
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: Size(pieceSize - 2, pieceSize - 2),
                        painter: OverlayPainter(
                          mode: _displayMode,
                          isFlat: _isFlatMode,
                          topData: engine.patterns[piece.top]!,
                          rightData: engine.patterns[piece.right]!,
                          bottomData: engine.patterns[piece.bottom]!,
                          leftData: engine.patterns[piece.left]!,
                        ),
                      ),
                    ],
                  ),
                );

                return AnimatedPositioned(
                  key: ValueKey(piece.id),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: left,
                  top: top,
                  width: pieceSize,
                  height: pieceSize,
                  child: DragTarget<int>(
                    onWillAccept: (src) {
                      return src != idx;
                    },
                    onAccept: (sourceIdx) {
                      _swapPieces(sourceIdx, idx);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Draggable<int>(
                        data: idx,
                        maxSimultaneousDrags: isSolving ? 0 : 1,
                        onDragStarted: () => setState(() => draggedIndex = idx),
                        onDragEnd: (details) =>
                            setState(() => draggedIndex = null),
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.8,
                            child: Container(
                              width: pieceSize,
                              height: pieceSize,
                              decoration: BoxDecoration(boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(4, 4))
                              ]),
                              child: pieceWidget,
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: pieceWidget,
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          child: pieceWidget,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildHelpOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showHelpInfo = false;
        });
      },
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: const Color(0xFF2C2C3E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.helpPara1,
                    style: const TextStyle(
                        fontSize: 17, color: Colors.white, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.helpPara2,
                    style: const TextStyle(
                        fontSize: 17, color: Colors.white, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildHelpBullet(AppStrings.helpBullet1),
                  const SizedBox(height: 8),
                  _buildHelpBullet(AppStrings.helpBullet2),
                  const SizedBox(height: 8),
                  _buildHelpBullet(AppStrings.helpBullet3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6.0, right: 8.0),
          child: Icon(Icons.circle, size: 6, color: Colors.white70),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 14, color: Colors.white70, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildSplashScreen() {
    return Container(
        color: const Color(0xFF1E1E2C),
        child: Center(
            child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              Text('Indefinitely',
                  style: GoogleFonts.secularOne(
                      fontSize: 44,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                      letterSpacing: 2)),
              const SizedBox(height: 10),
              Text(AppStrings.crazyToTry,
                  style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey)),
              const SizedBox(height: 60),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 60,
                    right: 40,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(-math.pi / 3.54)
                        ..rotateZ(-math.pi / 4),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: 0.6,
                        child: SizedBox(
                          width: 154,
                          height: 154,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: List.generate(9, (index) {
                              int col = index % 3;
                              int row = index ~/ 3;
                              double hexW = 154 / 3;
                              double hexH = hexW * math.sqrt(3) / 2;
                              double left = col * hexW * 0.75;
                              double top =
                                  row * hexH + (col % 2 == 1 ? hexH / 2 : 0);
                              var patterns = _splashPatterns[index];
                              var edges = [
                                patterns[0],
                                patterns[1],
                                patterns[2],
                                patterns[3],
                                patterns[0],
                                patterns[1]
                              ];
                              return Positioned(
                                left: left,
                                top: top,
                                width: hexW,
                                height: hexH,
                                child: Container(
                                  decoration: BoxDecoration(boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(2, 2))
                                  ]),
                                  child: CustomPaint(
                                    painter: HexPiecePainter(
                                      mode: DisplayMode.colours,
                                      isFlat: _isFlatMode,
                                      pieceTurns: 0,
                                      edgeData: edges,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(-math.pi / 3.54)
                      ..rotateZ(-math.pi / 4),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: SizedBox(
                          width: 154,
                          height: 154,
                          child: GridView.builder(
                              padding:
                                  const EdgeInsets.only(bottom: 4, right: 4),
                              clipBehavior: Clip.none,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 2,
                                      mainAxisSpacing: 2),
                              itemCount: 9,
                              itemBuilder: (context, index) {
                                var patterns = _splashPatterns[index];
                                return Container(
                                  decoration: BoxDecoration(boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(2, 2))
                                  ]),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CustomPaint(
                                        painter: PiecePainter(
                                          mode: DisplayMode.colours,
                                          isFlat: _isFlatMode,
                                          pieceTurns: 0,
                                          topData: patterns[0],
                                          rightData: patterns[1],
                                          bottomData: patterns[2],
                                          leftData: patterns[3],
                                        ),
                                      ),
                                      CustomPaint(
                                        painter: OverlayPainter(
                                          mode: DisplayMode.colours,
                                          isFlat: _isFlatMode,
                                          topData: patterns[0],
                                          rightData: patterns[1],
                                          bottomData: patterns[2],
                                          leftData: patterns[3],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                      value: _splashOptOutChecked,
                      onChanged: (val) {
                        setState(() {
                          _splashOptOutChecked = val ?? false;
                        });
                        _setSplashPrefs(!_splashOptOutChecked);
                      }),
                  Text(AppStrings.doNotShowAgain,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15)),
                onPressed: () {
                  setState(() {
                    _showSplash = false;
                    _showHelpInfo = false;
                  });
                },
                child: Text(AppStrings.startGame,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(height: 40),
            ]))));
  }
}

class PiecePainter extends CustomPainter {
  final DisplayMode mode;
  final bool isFlat;
  final int pieceTurns;
  final PatternData topData;
  final PatternData rightData;
  final PatternData bottomData;
  final PatternData leftData;

  PiecePainter({
    required this.mode,
    required this.isFlat,
    required this.pieceTurns,
    required this.topData,
    required this.rightData,
    required this.bottomData,
    required this.leftData,
  });

  void _drawQuadrant(Canvas canvas, Path path, PatternData data,
      Offset centroid, Size size, double angle) {
    Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = data.bgColor;
    canvas.drawPath(path, paint);

    if (data.bgColor == neutralColour() || mode == DisplayMode.colours) return;

    Paint fgPaint = Paint()
      ..color = data.fgColor
      ..style = PaintingStyle.fill;
    Paint linePaint = Paint()
      ..color = data.fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    double r = math.min(size.width, size.height) *
        (isFlat && mode == DisplayMode.patterns ? 0.20 : 0.12);

    canvas.save();
    canvas.translate(centroid.dx, centroid.dy);
    canvas.rotate(angle);

    if (mode == DisplayMode.patterns) {
      switch (data.shape) {
        case 0: // Circle
          canvas.drawCircle(Offset.zero, r, fgPaint);
          break;
        case 1: // Square
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset.zero, width: r * 1.6, height: r * 1.6),
              fgPaint);
          break;
        case 2: // Diamond
          Path p = Path()
            ..moveTo(0, -r * 1.2)
            ..lineTo(r * 1.2, 0)
            ..lineTo(0, r * 1.2)
            ..lineTo(-r * 1.2, 0)
            ..close();
          canvas.drawPath(p, fgPaint);
          break;
        case 3: // Cross
          canvas.drawLine(Offset(-r, -r), Offset(r, r), linePaint);
          canvas.drawLine(Offset(-r, r), Offset(r, -r), linePaint);
          break;
        case 4: // Triangle
          Path p = Path()
            ..moveTo(0, -r)
            ..lineTo(r * 0.866, r * 0.5)
            ..lineTo(-r * 0.866, r * 0.5)
            ..close();
          canvas.drawPath(p, fgPaint);
          break;
      }
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (isFlat && mode == DisplayMode.patterns) {
      canvas.clipRect(Offset.zero & size);
    }
    Offset center = Offset(size.width / 2, size.height / 2);

    Path topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(center.dx, center.dy)
      ..close();
    Offset topCentroid = (isFlat && mode == DisplayMode.patterns)
        ? Offset(size.width / 2, 0)
        : Offset(size.width / 2, size.height / 4);
    _drawQuadrant(canvas, topPath, topData, topCentroid, size, 0);

    Path rightPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(center.dx, center.dy)
      ..close();
    Offset rightCentroid = (isFlat && mode == DisplayMode.patterns)
        ? Offset(size.width, size.height / 2)
        : Offset(size.width * 0.75, size.height / 2);
    _drawQuadrant(
        canvas, rightPath, rightData, rightCentroid, size, math.pi / 2);

    Path bottomPath = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(center.dx, center.dy)
      ..close();
    Offset bottomCentroid = (isFlat && mode == DisplayMode.patterns)
        ? Offset(size.width / 2, size.height)
        : Offset(size.width / 2, size.height * 0.75);
    _drawQuadrant(
        canvas, bottomPath, bottomData, bottomCentroid, size, math.pi);

    Path leftPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(center.dx, center.dy)
      ..close();
    Offset leftCentroid = (isFlat && mode == DisplayMode.patterns)
        ? Offset(0, size.height / 2)
        : Offset(size.width / 4, size.height / 2);
    _drawQuadrant(
        canvas, leftPath, leftData, leftCentroid, size, 3 * math.pi / 2);

    Paint linePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
        const Offset(0, 0), Offset(size.width, size.height), linePaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), linePaint);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), linePaint);
  }

  @override
  bool shouldRepaint(covariant PiecePainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.isFlat != isFlat ||
        oldDelegate.pieceTurns != pieceTurns ||
        oldDelegate.topData != topData ||
        oldDelegate.rightData != rightData ||
        oldDelegate.bottomData != bottomData ||
        oldDelegate.leftData != leftData;
  }
}

class OverlayPainter extends CustomPainter {
  final DisplayMode mode;
  final bool isFlat;
  final PatternData topData;
  final PatternData rightData;
  final PatternData bottomData;
  final PatternData leftData;

  OverlayPainter({
    required this.mode,
    required this.isFlat,
    required this.topData,
    required this.rightData,
    required this.bottomData,
    required this.leftData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double r = math.min(size.width, size.height) * 0.12;

    if (mode == DisplayMode.numbers) {
      void drawNumber(PatternData data, Offset center) {
        if (data.bgColor == neutralColour()) return;

        TextPainter tp = TextPainter(
          text: TextSpan(
              text: '${data.number}',
              style: TextStyle(
                  color: textColourForBackground(data.bgColor),
                  fontSize: r * 1.5,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas,
            Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
      }

      drawNumber(topData, Offset(size.width / 2, size.height / 4));
      drawNumber(rightData, Offset(size.width * 0.75, size.height / 2));
      drawNumber(bottomData, Offset(size.width / 2, size.height * 0.75));
      drawNumber(leftData, Offset(size.width / 4, size.height / 2));
    }

    if (!isFlat) {
      double bw = size.width * 0.08;
      if (bw < 2.0) bw = 2.0;

      Path topBevel = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width - bw, bw)
        ..lineTo(bw, bw)
        ..close();
      canvas.drawPath(topBevel, Paint()..color = Colors.white.withOpacity(0.4));

      Path leftBevel = Path()
        ..moveTo(0, 0)
        ..lineTo(0, size.height)
        ..lineTo(bw, size.height - bw)
        ..lineTo(bw, bw)
        ..close();
      canvas.drawPath(
          leftBevel, Paint()..color = Colors.white.withOpacity(0.2));

      Path rightBevel = Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - bw, size.height - bw)
        ..lineTo(size.width - bw, bw)
        ..close();
      canvas.drawPath(
          rightBevel, Paint()..color = Colors.black.withOpacity(0.15));

      Path bottomBevel = Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - bw, size.height - bw)
        ..lineTo(bw, size.height - bw)
        ..close();
      canvas.drawPath(
          bottomBevel, Paint()..color = Colors.black.withOpacity(0.25));
    }
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.isFlat != isFlat ||
        oldDelegate.topData != topData ||
        oldDelegate.rightData != rightData ||
        oldDelegate.bottomData != bottomData ||
        oldDelegate.leftData != leftData;
  }
}
