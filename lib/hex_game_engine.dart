import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'hex_models.dart';
import 'models.dart';
import 'colours.dart';

class HexGameEngine {
  int cols;
  int rows;
  List<HexPieceData> grid = [];
  Map<int, PatternData> patterns = {};
  int moveCount = 0;
  int hintCount = 0;
  bool usedGiveUp = false;

  HexGameEngine(this.cols, this.rows);

  void initGame() {
    grid.clear();
    patterns.clear();
    moveCount = 0;
    hintCount = 0;
    usedGiveUp = false;

    patterns[0] = PatternData(neutralColour(), neutralColour(), 0, 0);

    int numPatterns = cols * rows * 3;
    List rawPairs = pairs(numPatterns + 10);
    math.Random random = math.Random();

    List<int> uniqueNumbers = List.generate(180, (index) => index + 10);
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

    List<HexPieceData> solvedGrid =
        List.generate(cols * rows, (i) => HexPieceData(i, [0, 0, 0, 0, 0, 0]));

    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        int idx = row * cols + col;

        if (row < rows - 1) {
          int patternId = random.nextInt(numPatterns) + 1;
          solvedGrid[idx].baseEdges[3] = patternId; // Bottom
          solvedGrid[(row + 1) * cols + col].baseEdges[0] = patternId; // Top
        } else {
          solvedGrid[idx].baseEdges[3] = random.nextInt(numPatterns) + 1;
        }

        if (row == 0) {
          solvedGrid[idx].baseEdges[0] = random.nextInt(numPatterns) + 1;
        }

        int trRow = col % 2 == 1 ? row : row - 1;
        int trCol = col + 1;
        if (trCol < cols && trRow >= 0 && trRow < rows) {
          int patternId = random.nextInt(numPatterns) + 1;
          solvedGrid[idx].baseEdges[1] = patternId; // TopRight
          solvedGrid[trRow * cols + trCol].baseEdges[4] =
              patternId; // BottomLeft
        } else {
          solvedGrid[idx].baseEdges[1] = random.nextInt(numPatterns) + 1;
        }

        int brRow = col % 2 == 1 ? row + 1 : row;
        int brCol = col + 1;
        if (brCol < cols && brRow >= 0 && brRow < rows) {
          int patternId = random.nextInt(numPatterns) + 1;
          solvedGrid[idx].baseEdges[2] = patternId; // BottomRight
          solvedGrid[brRow * cols + brCol].baseEdges[5] = patternId; // TopLeft
        } else {
          solvedGrid[idx].baseEdges[2] = random.nextInt(numPatterns) + 1;
        }

        if (col == 0) {
          solvedGrid[idx].baseEdges[4] = random.nextInt(numPatterns) + 1;
          solvedGrid[idx].baseEdges[5] = random.nextInt(numPatterns) + 1;
        }
      }
    }

    solvedGrid.shuffle(random);

    for (var piece in solvedGrid) {
      int rotations = random.nextInt(6);
      for (int i = 0; i < rotations; i++) {
        piece.rotate();
      }
    }

    grid = solvedGrid;
  }

  bool isSolved() {
    if (grid.isEmpty) return false;

    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        int idx = row * cols + col;
        var piece = grid[idx];

        if (row < rows - 1) {
          var neighbor = grid[(row + 1) * cols + col];
          if (piece.getEdge(3) != neighbor.getEdge(0)) return false;
        }

        int trRow = col % 2 == 1 ? row : row - 1;
        int trCol = col + 1;
        if (trCol < cols && trRow >= 0 && trRow < rows) {
          var neighbor = grid[trRow * cols + trCol];
          if (piece.getEdge(1) != neighbor.getEdge(4)) return false;
        }

        int brRow = col % 2 == 1 ? row + 1 : row;
        int brCol = col + 1;
        if (brCol < cols && brRow >= 0 && brRow < rows) {
          var neighbor = grid[brRow * cols + brCol];
          if (piece.getEdge(2) != neighbor.getEdge(5)) return false;
        }
      }
    }

    return true;
  }
}
