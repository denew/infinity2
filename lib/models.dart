import 'package:flutter/material.dart';

class PuzzleMove {
  final String type;
  final int idx1;
  final int idx2;
  final int rotations;

  PuzzleMove.swap(this.idx1, this.idx2)
      : type = 'swap',
        rotations = 0;
  PuzzleMove.rotate(this.idx1, this.rotations)
      : type = 'rotate',
        idx2 = 0;
}

class PieceData {
  final int id;
  int baseTop, baseRight, baseBottom, baseLeft;
  int turns = 0;

  PieceData(
      this.id, this.baseTop, this.baseRight, this.baseBottom, this.baseLeft);

  int get top {
    int mod = turns % 4;
    if (mod < 0) mod += 4;
    if (mod == 0) return baseTop;
    if (mod == 1) return baseLeft;
    if (mod == 2) return baseBottom;
    return baseRight;
  }

  int get right {
    int mod = turns % 4;
    if (mod < 0) mod += 4;
    if (mod == 0) return baseRight;
    if (mod == 1) return baseTop;
    if (mod == 2) return baseLeft;
    return baseBottom;
  }

  int get bottom {
    int mod = turns % 4;
    if (mod < 0) mod += 4;
    if (mod == 0) return baseBottom;
    if (mod == 1) return baseRight;
    if (mod == 2) return baseTop;
    return baseLeft;
  }

  int get left {
    int mod = turns % 4;
    if (mod < 0) mod += 4;
    if (mod == 0) return baseLeft;
    if (mod == 1) return baseBottom;
    if (mod == 2) return baseRight;
    return baseTop;
  }

  void rotate() {
    turns++;
  }

  void rotateAntiClockwise() {
    turns--;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'baseTop': baseTop,
        'baseRight': baseRight,
        'baseBottom': baseBottom,
        'baseLeft': baseLeft,
        'turns': turns,
      };

  factory PieceData.fromJson(Map<String, dynamic> json) {
    var p = PieceData(json['id'], json['baseTop'], json['baseRight'],
        json['baseBottom'], json['baseLeft']);
    p.turns = json['turns'];
    return p;
  }
}

class PatternData {
  final Color bgColor;
  final Color fgColor;
  final int shape;
  final int number;

  PatternData(this.bgColor, this.fgColor, this.shape, this.number);

  Map<String, dynamic> toJson() => {
        'bgColor': bgColor.value,
        'fgColor': fgColor.value,
        'shape': shape,
        'number': number,
      };

  factory PatternData.fromJson(Map<String, dynamic> json) {
    return PatternData(
      Color(json['bgColor']),
      Color(json['fgColor']),
      json['shape'],
      json['number'],
    );
  }
}

enum DisplayMode { colours, patterns, numbers }
