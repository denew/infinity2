import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'models.dart';
import 'colours.dart';

class GameEngine {
  int cols;
  int rows;
  List<PieceData> grid = [];
  Map<int, PatternData> patterns = {};
  int moveCount = 0;
  int hintCount = 0;
  bool usedGiveUp = false;

  GameEngine(this.cols, this.rows);

  void initGame() {
    grid.clear();
    patterns.clear();
    moveCount = 0;
    hintCount = 0;
    usedGiveUp = false;

    patterns[0] = PatternData(neutralColour(), neutralColour(), 0, 0);

    int numPatterns = cols * rows * 2;
    List rawPairs = pairs(numPatterns + 10);

    math.Random random = math.Random();

    // Create a shuffled list of unique 2-digit numbers
    List<int> uniqueNumbers = List.generate(90, (index) => index + 10);
    uniqueNumbers.shuffle(random);

    for (int i = 1; i <= numPatterns + 5; i++) {
      var p = rawPairs[i % rawPairs.length];
      var cBg = p[0];
      var cFg = p[1];

      Color bgColor = Color.fromRGBO(cBg[0], cBg[1], cBg[2], 1.0);
      Color fgColor = Color.fromRGBO(cFg[0], cFg[1], cFg[2], 1.0);

      int shape = random.nextInt(5);
      int number = uniqueNumbers[(i - 1) % uniqueNumbers.length];
      patterns[i] = PatternData(bgColor, fgColor, shape, number);
    }

    List<PieceData> solvedGrid =
        List.generate(cols * rows, (i) => PieceData(i, 0, 0, 0, 0));

    for (int j = 0; j < rows; j++) {
      for (int i = 0; i < cols - 1; i++) {
        int patternId = random.nextInt(numPatterns) + 1;
        solvedGrid[j * cols + i].baseRight = patternId;
        solvedGrid[j * cols + i + 1].baseLeft = patternId;
      }
    }

    for (int j = 0; j < rows - 1; j++) {
      for (int i = 0; i < cols; i++) {
        int patternId = random.nextInt(numPatterns) + 1;
        solvedGrid[j * cols + i].baseBottom = patternId;
        solvedGrid[(j + 1) * cols + i].baseTop = patternId;
      }
    }

    solvedGrid.shuffle(random);

    for (var piece in solvedGrid) {
      int rotations = random.nextInt(4);
      for (int i = 0; i < rotations; i++) {
        piece.rotate();
      }
    }

    grid = solvedGrid;
  }

  bool isSolved() {
    if (grid.isEmpty) return false;
    for (int j = 0; j < rows; j++) {
      for (int i = 0; i < cols - 1; i++) {
        if (grid[j * cols + i].right != grid[j * cols + i + 1].left) {
          return false;
        }
        if (i == 0 && grid[j * cols + i].left != 0) return false;
        if (i == cols - 2 && grid[j * cols + i + 1].right != 0) return false;
      }
    }

    for (int j = 0; j < rows - 1; j++) {
      for (int i = 0; i < cols; i++) {
        if (grid[j * cols + i].bottom != grid[(j + 1) * cols + i].top) {
          return false;
        }
        if (j == 0 && grid[j * cols + i].top != 0) return false;
        if (j == rows - 2 && grid[(j + 1) * cols + i].bottom != 0) return false;
      }
    }

    return true;
  }

  String exportState() {
    return jsonEncode({
      'cols': cols,
      'rows': rows,
      'moveCount': moveCount,
      'hintCount': hintCount,
      'usedGiveUp': usedGiveUp,
      'grid': grid.map((p) => p.toJson()).toList(),
      'patterns': patterns.map((k, v) => MapEntry(k.toString(), v.toJson())),
    });
  }

  void importState(String jsonStr) {
    var data = jsonDecode(jsonStr);
    if (data['cols'] != cols || data['rows'] != rows) return;
    moveCount = data['moveCount'];
    hintCount = data['hintCount'];
    usedGiveUp = data['usedGiveUp'];

    grid = (data['grid'] as List).map((p) => PieceData.fromJson(p)).toList();

    patterns.clear();
    (data['patterns'] as Map<String, dynamic>).forEach((k, v) {
      patterns[int.parse(k)] = PatternData.fromJson(v);
    });
  }
}
