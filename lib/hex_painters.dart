import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'models.dart';
import 'colours.dart';

class HexPiecePainter extends CustomPainter {
  final DisplayMode mode;
  final bool isFlat;
  final int pieceTurns;
  final List<PatternData> edgeData;

  HexPiecePainter({
    required this.mode,
    required this.isFlat,
    required this.pieceTurns,
    required this.edgeData,
  });

  void _drawTriangle(Canvas canvas, Path path, PatternData data,
      Offset centroid, Size size, double angle) {
    Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = data.bgColor;
    canvas.drawPath(path, paint);

    if (data.bgColor == Colors.transparent || mode == DisplayMode.colours)
      return;

    Paint fgPaint = Paint()
      ..color = data.fgColor
      ..style = PaintingStyle.fill;

    double r = math.min(size.width, size.height) *
        (mode == DisplayMode.patterns ? 0.20 : 0.12) *
        0.65; // hex-specific scaling

    canvas.save();
    canvas.translate(centroid.dx, centroid.dy);
    canvas.rotate(angle);

    if (mode == DisplayMode.patterns) {
      if (data.shape == 0)
        canvas.drawCircle(Offset.zero, r, fgPaint);
      else if (data.shape == 1)
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: r * 1.6, height: r * 1.6),
            fgPaint);
      else if (data.shape == 2) {
        Path diamond = Path()
          ..moveTo(0, -r)
          ..lineTo(r, 0)
          ..lineTo(0, r)
          ..lineTo(-r, 0)
          ..close();
        canvas.drawPath(diamond, fgPaint);
      }
      // other shapes can be omitted for hex if not needed, as user said patterns might drop, but lets keep it basic
    }

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    double cx = size.width / 2;
    double cy = size.height / 2;
    double hw = size.width / 2;
    double hh = size.height / 2;
    List<Offset> corners = [
      Offset(cx - hw / 2, cy - hh), // TL
      Offset(cx + hw / 2, cy - hh), // TR
      Offset(cx + hw, cy), // R
      Offset(cx + hw / 2, cy + hh), // BR
      Offset(cx - hw / 2, cy + hh), // BL
      Offset(cx - hw, cy), // L
    ];

    List<List<int>> edgeCorners = [
      [0, 1], // Top
      [1, 2], // TopRight
      [2, 3], // BottomRight
      [3, 4], // Bottom
      [4, 5], // BottomLeft
      [5, 0], // TopLeft
    ];

    List<double> angles = [
      -math.pi / 2, // Top
      -math.pi / 6, // TopRight
      math.pi / 6, // BottomRight
      math.pi / 2, // Bottom
      5 * math.pi / 6, // BottomLeft
      -5 * math.pi / 6, // TopLeft
    ];

    Path hexPath = Path();
    hexPath.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < 6; i++) {
      hexPath.lineTo(corners[i].dx, corners[i].dy);
    }
    hexPath.close();

    if (mode == DisplayMode.patterns) {
      canvas.clipPath(hexPath);
    }

    for (int i = 0; i < 6; i++) {
      Path p = Path();
      p.moveTo(cx, cy);
      p.lineTo(corners[edgeCorners[i][0]].dx, corners[edgeCorners[i][0]].dy);
      p.lineTo(corners[edgeCorners[i][1]].dx, corners[edgeCorners[i][1]].dy);
      p.close();

      Offset centroid = (mode == DisplayMode.patterns)
          ? Offset(
              (corners[edgeCorners[i][0]].dx + corners[edgeCorners[i][1]].dx) /
                  2,
              (corners[edgeCorners[i][0]].dy + corners[edgeCorners[i][1]].dy) /
                  2,
            )
          : Offset(
              (cx +
                      corners[edgeCorners[i][0]].dx +
                      corners[edgeCorners[i][1]].dx) /
                  3,
              (cy +
                      corners[edgeCorners[i][0]].dy +
                      corners[edgeCorners[i][1]].dy) /
                  3,
            );

      _drawTriangle(
          canvas, p, edgeData[i], centroid, size, angles[i] + math.pi / 2);
    }

    Paint linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(hexPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant HexPiecePainter oldDelegate) {
    return true; // Simplify for now
  }
}

class HexOverlayPainter extends CustomPainter {
  final DisplayMode mode;
  final bool isFlat;
  final List<PatternData> edgeData;

  HexOverlayPainter({
    required this.mode,
    required this.isFlat,
    required this.edgeData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mode != DisplayMode.numbers) return;

    double cx = size.width / 2;
    double cy = size.height / 2;
    double hw = size.width / 2;
    double hh = size.height / 2;

    List<Offset> corners = [
      Offset(cx - hw / 2, cy - hh), // TL
      Offset(cx + hw / 2, cy - hh), // TR
      Offset(cx + hw, cy), // R
      Offset(cx + hw / 2, cy + hh), // BR
      Offset(cx - hw / 2, cy + hh), // BL
      Offset(cx - hw, cy), // L
    ];

    List<List<int>> edgeCorners = [
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
      [4, 5],
      [5, 0],
    ];

    double r =
        math.min(size.width, size.height) * 0.12 * 0.65; // hex-specific scaling

    for (int i = 0; i < 6; i++) {
      var data = edgeData[i];
      if (data.bgColor == Colors.transparent) continue;

      Offset p1 = corners[edgeCorners[i][0]];
      Offset p2 = corners[edgeCorners[i][1]];
      Offset centroid = Offset(
        (cx + p1.dx + p2.dx) / 3,
        (cy + p1.dy + p2.dy) / 3,
      );

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
          Offset(centroid.dx - tp.width / 2, centroid.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant HexOverlayPainter oldDelegate) {
    return true;
  }
}
