class HexPieceData {
  final int id;
  // 0: Top, 1: TopRight, 2: BottomRight, 3: Bottom, 4: BottomLeft, 5: TopLeft
  List<int> baseEdges;
  int turns = 0;

  HexPieceData(this.id, this.baseEdges);

  int getEdge(int dir) {
    int mod = turns % 6;
    if (mod < 0) mod += 6;
    int idx = (dir - mod) % 6;
    if (idx < 0) idx += 6;
    return baseEdges[idx];
  }

  void rotate() {
    turns++;
  }

  void rotateAntiClockwise() {
    turns--;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'baseEdges': baseEdges,
        'turns': turns,
      };

  factory HexPieceData.fromJson(Map<String, dynamic> json) {
    var p = HexPieceData(json['id'], List<int>.from(json['baseEdges']));
    p.turns = json['turns'];
    return p;
  }
}
