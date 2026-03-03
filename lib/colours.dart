import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/*
Brightness/luminosity and contrast values follow conventions in:
http://juicystudio.com/article/luminositycontrastratioalgorithm.php
 */

const counter = 20; // try this many times to get an acceptable contrast
const brightnessLimit = 125;
const contrastMultiplier = 25; // * counter of 20 = 500 maximum

/*
Not really required for modern screens, but these are the
standard 'web safe' colour values (00, 33, 66, 99, CC, and FF
in hex) as ints.
 */
List<int> allowedColourValues() {
  return [0, 51, 102, 153, 204, 255];
}

double brightness(int r, int g, int b) {
  return ((r * 299) + (g * 587) + (b * 114)) / 1000;
}

int contrast(int r0, int r1, int g0, int g1, int b0, int b1) {
  return (r0 - r1).abs() + (g0 - g1).abs() + (b0 - b1).abs();
}

bool passBrightness(final List<int> rgb) {
  return brightness(rgb[0], rgb[1], rgb[2]) > brightnessLimit;
}

/*
Value gradually reduced from 500
 */
bool passContrast(r0, r1, g0, g1, b0, b1, limit) {
  //print(contrast(r0, r1, g0, g1, b0, b1));
  return contrast(r0, r1, g0, g1, b0, b1) > limit;
}

/*
Create a random colour's 3 RGB values, ensuring that no more
than 2 parts are the same (i.e. no greys allowed - reserved
for the neutral quadrant colour regardless of depth). Note
that external colours must contrast amongst themselves and
grey, internal patterns only need to contrast with their
owning background
 */
List<int> randomRGB() {
  var out = <int>[];
  const int rgbValueCount = 3;
  final random = math.Random();
  var len = allowedColourValues().length;
  while (out.length < rgbValueCount) {
    var index = random.nextInt(len);
    var tmp = allowedColourValues()[index];
    var existing = out.where((i) => i == tmp).toList().length;
    if (existing == 2) {
      continue;
    }
    out.add(tmp);
  }
  return out;
}

Color randomColour() {
  List<int> rgb = randomRGB();
  return Color.fromRGBO(rgb[0], rgb[1], rgb[2], 1.0);
}

/*
Create background colours that are all 'bright' and unique.
Note that it is increasingly hard to find mutually
contrasting backgrounds as the number of pieces increases,
so we rely on the (very large) combination of background and
pattern colours and pattern shape to provide a unique
appearance within a single puzzle.
 */
Set randomColours(n) {
  var out = <dynamic>{};
  while (out.length < n) {
    var rgb = randomRGB();
    if (!passBrightness(rgb)) {
      continue;
    }
    out.add(rgb);
  }
  return out;
}

/*
For each background colour, find a contrasting pattern colour
and return a list of the combinations. Gradually reduce the
required contrast to ensure that some combination is returned
 */
List pairs(num) {
  var s = randomColours(num);
  var out = [];
  for (var c in s) {
    List<int> rgb = [];
    var i = counter;
    while (true && i > 0) {
      rgb = randomRGB();
      //print("i=$i, c=$c, rgb=$rgb");
      if (!passBrightness(rgb)) {
        continue;
      }
      if (!passContrast(
          c[0], rgb[0], c[1], rgb[1], c[2], rgb[2], i * contrastMultiplier)) {
        i--;
        continue;
      }
      break;
    }
    out.add([c, rgb]);
  }
  return out;
}

Color neutralColour() {
  return const Color.fromRGBO(204, 204, 204, 1.0);
}

Color textColourForBackground(Color bg) {
  // Use a standard luminance threshold to decide between dark grey and white
  return bg.computeLuminance() > 0.45 ? const Color(0xFF333333) : Colors.white;
}
