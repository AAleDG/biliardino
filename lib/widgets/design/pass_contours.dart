import 'package:flutter/material.dart';

// Approved Pass artwork. Decorative gradient stops belong to this shared master.
// Provenance: design/south-africa-2010/assets/pass/manifest.json.
abstract final class PassContours {
  // One selected composition for both routes. Blue uses Dati's registered width.
  static List<(Path, String, List<Color>, Offset, Offset)> header() {
    final more = headerMore();
    final blue = headerData().firstWhere((item) => item.$2 == 'blue');
    const scale = 466 / 461;
    final matrix = Matrix4.diagonal3Values(scale, 1, 1);
    return [
      for (final item in more.where((item) => item.$2 != 'blue'))
        if (item.$2 == 'red')
          (
            item.$1.shift(const Offset(0, 6)),
            item.$2,
            item.$3,
            item.$4 + const Offset(0, 6),
            item.$5 + const Offset(0, 6),
          )
        else
          item,
      (
        blue.$1.transform(matrix.storage),
        blue.$2,
        blue.$3,
        Offset(blue.$4.dx * scale, blue.$4.dy),
        Offset(blue.$5.dx * scale, blue.$5.dy),
      ),
    ];
  }

  static List<(Path, String, List<Color>, Offset, Offset)> sharedFooter() {
    final source = footerMore();
    (Path, String, List<Color>, Offset, Offset) ribbon(Path path, int index) {
      final item = source[index];
      return (path, item.$2, item.$3, item.$4, item.$5);
    }

    return [
      // Smooth taper replaces the fitted dent; the approved upper edge stays.
      ribbon(
        Path()
          ..moveTo(0, 2.472)
          ..cubicTo(19.417, 18.691, 38.833, 31.651, 58.250, 43.228)
          ..cubicTo(77.667, 54.805, 97.083, 63.801, 116.500, 71.087)
          ..cubicTo(135.917, 78.372, 155.333, 84.959, 174.750, 91.455)
          ..cubicTo(194.167, 97.952, 213.583, 103.872, 233, 111.879)
          ..cubicTo(193, 109, 153, 96, 116.5, 88.631)
          ..cubicTo(77.667, 80.414, 38.833, 71.572, 0, 41.098)
          ..close(),
        0,
      ),
      // Continuous band extends below the viewport and under the black sweep.
      ribbon(
        Path()
          ..moveTo(-2, 52.5)
          ..cubicTo(51, 87, 106, 91, 155, 104.406)
          ..cubicTo(185, 113, 195, 145, 200, 180)
          ..lineTo(166, 180)
          ..cubicTo(114, 127, 59, 109, -2, 86)
          ..close(),
        1,
      ),
      ribbon(
        Path()
          ..moveTo(-2, 101.2)
          ..cubicTo(40, 113, 83, 125, 115, 149)
          ..lineTo(145, 174)
          ..lineTo(-2, 174)
          ..close(),
        2,
      ),
      // Left sweep is shifted away from the ball; its base crosses the clip.
      ribbon(
        Path()
          ..moveTo(141, 163)
          ..cubicTo(192, 130, 248, 89, 306, 72)
          ..cubicTo(257, 95, 221, 127, 194, 165)
          ..close(),
        3,
      ),
      source[4],
      // Dati-inspired right sweep curves closer to the ball and exits below.
      ribbon(
        Path()
          ..moveTo(383, 65)
          ..cubicTo(414, 65, 443, 76, 465, 91)
          ..lineTo(465, 174)
          ..cubicTo(451, 111, 423, 82, 383, 65)
          ..close(),
        5,
      ),
    ];
  }

  static List<(Path, String, List<Color>, Offset, Offset)> headerData() => [
    (
      Path()
        ..moveTo(348.000, 95.713)
        ..cubicTo(357.333, 91.879, 366.667, 86.366, 376.000, 80.938)
        ..cubicTo(385.333, 75.511, 394.667, 68.402, 404.000, 61.066)
        ..cubicTo(413.333, 53.730, 422.667, 44.993, 432.000, 35.031)
        ..cubicTo(441.333, 25.069, 450.667, 17.467, 460.000, 6.009)
        ..lineTo(460.000, 48.007)
        ..cubicTo(450.667, 54.360, 441.333, 60.351, 432.000, 65.650)
        ..cubicTo(422.667, 70.948, 413.333, 75.468, 404.000, 80.001)
        ..cubicTo(394.667, 84.534, 385.333, 87.991, 376.000, 90.821)
        ..cubicTo(366.667, 93.650, 357.333, 95.746, 348.000, 97.228)
        ..close(),
      'blue',
      [
        const Color(0xFF0364D0),
        const Color(0xFF0062D0),
        const Color(0xFF005ECE),
        const Color(0xFF015CCB),
        const Color(0xFF0359C5),
      ],
      const Offset(361.628, 40.169),
      const Offset(377.589, 88.484),
    ),
  ];
  static List<(Path, String, List<Color>, Offset, Offset)> headerMore() => [
    (
      Path()
        ..moveTo(0.000, 109.142)
        ..cubicTo(10.000, 88.805, 20.000, 77.003, 30.000, 67.079)
        ..cubicTo(40.000, 57.155, 50.000, 51.131, 60.000, 45.326)
        ..cubicTo(70.000, 39.522, 80.000, 35.056, 90.000, 31.303)
        ..cubicTo(100.000, 27.551, 110.000, 25.885, 120.000, 23.121)
        ..lineTo(120.000, 25.139)
        ..cubicTo(110.000, 30.296, 100.000, 37.466, 90.000, 44.983)
        ..cubicTo(80.000, 52.500, 70.000, 61.653, 60.000, 70.936)
        ..cubicTo(50.000, 80.220, 40.000, 90.801, 30.000, 102.779)
        ..cubicTo(20.000, 114.757, 10.000, 126.207, 0.000, 143.528)
        ..close(),
      'yellow',
      [
        const Color(0xFFFDD423),
        const Color(0xFFFED420),
        const Color(0xFFFED007),
        const Color(0xFFFECC03),
        const Color(0xFFFEC905),
      ],
      const Offset(-30.301, 129.734),
      const Offset(10.508, -8.117),
    ),
    (
      Path()
        ..moveTo(0.000, 54.047)
        ..cubicTo(5.667, 48.163, 11.333, 42.829, 17.000, 38.760)
        ..cubicTo(22.667, 34.691, 28.333, 30.070, 34.000, 27.076)
        ..cubicTo(39.667, 24.082, 45.333, 19.840, 51.000, 18.620)
        ..cubicTo(56.667, 17.399, 62.333, 14.097, 68.000, 12.743)
        ..lineTo(68.000, 14.292)
        ..cubicTo(62.333, 17.105, 56.667, 22.751, 51.000, 28.208)
        ..cubicTo(45.333, 33.665, 39.667, 39.872, 34.000, 46.202)
        ..cubicTo(28.333, 52.531, 22.667, 60.664, 17.000, 68.950)
        ..cubicTo(11.333, 77.236, 5.667, 87.497, 0.000, 98.567)
        ..close(),
      'green',
      [
        const Color(0xFF2E883C),
        const Color(0xFF238236),
        const Color(0xFF076F2D),
        const Color(0xFF036028),
        const Color(0xFF065625),
      ],
      const Offset(-36.090, 67.054),
      const Offset(22.418, -13.482),
    ),
    (
      Path()
        ..moveTo(348.000, 101.609)
        ..cubicTo(357.667, 99.848, 367.333, 96.924, 377.000, 93.752)
        ..cubicTo(386.667, 90.579, 396.333, 86.690, 406.000, 82.676)
        ..cubicTo(415.667, 78.662, 425.333, 73.552, 435.000, 68.759)
        ..cubicTo(444.667, 63.965, 454.333, 58.022, 464.000, 52.758)
        ..lineTo(464.000, 87.028)
        ..cubicTo(454.333, 89.672, 444.667, 92.460, 435.000, 94.307)
        ..cubicTo(425.333, 96.155, 415.667, 98.033, 406.000, 99.209)
        ..cubicTo(396.333, 100.385, 386.667, 100.705, 377.000, 101.995)
        ..cubicTo(367.333, 103.284, 357.667, 102.437, 348.000, 103.100)
        ..close(),
      'red',
      [
        const Color(0xFFE5151E),
        const Color(0xFFE4161E),
        const Color(0xFFE51921),
        const Color(0xFFE51C24),
        const Color(0xFFE6262C),
      ],
      const Offset(345.162, 99.275),
      const Offset(358.001, 33.503),
    ),
  ];
  static List<(Path, String, List<Color>, Offset, Offset)> cornerMore() => [
    (
      Path()
        ..moveTo(3.000, 0.000)
        ..cubicTo(12.917, 0.000, 22.833, 1.851, 32.750, 0.307)
        ..cubicTo(42.667, -1.236, 52.583, 2.350, 62.500, 8.966)
        ..cubicTo(72.417, 15.583, 82.333, 18.397, 92.250, 22.720)
        ..cubicTo(102.167, 27.043, 112.083, 30.076, 122.000, 31.861)
        ..lineTo(122.000, 33.900)
        ..cubicTo(112.083, 32.571, 102.167, 31.899, 92.250, 30.103)
        ..cubicTo(82.333, 28.307, 72.417, 26.841, 62.500, 23.858)
        ..cubicTo(52.583, 20.875, 42.667, 18.576, 32.750, 14.303)
        ..cubicTo(22.833, 10.030, 12.917, 5.974, 3.000, 1.799)
        ..close(),
      'yellow',
      [
        const Color(0xFFFCCA06),
        const Color(0xFFFDCB04),
        const Color(0xFFFDCB04),
        const Color(0xFFFCC706),
        const Color(0xFFFEC606),
      ],
      const Offset(5.000, 1.000),
      const Offset(93.449, 67.379),
    ),
    (
      Path()
        ..moveTo(68.000, 1.000)
        ..cubicTo(78.083, 1.000, 88.167, 0.282, 98.250, 0.891)
        ..cubicTo(108.333, 1.500, 118.417, -0.518, 128.500, 3.499)
        ..cubicTo(138.583, 7.517, 148.667, 11.308, 158.750, 17.828)
        ..cubicTo(168.833, 24.349, 178.917, 30.977, 189.000, 43.854)
        ..lineTo(189.000, 57.764)
        ..cubicTo(178.917, 50.168, 168.833, 44.640, 158.750, 40.444)
        ..cubicTo(148.667, 36.249, 138.583, 33.483, 128.500, 29.783)
        ..cubicTo(118.417, 26.084, 108.333, 23.080, 98.250, 18.358)
        ..cubicTo(88.167, 13.636, 78.083, 8.553, 68.000, 2.095)
        ..close(),
      'greenBlue',
      [
        const Color(0xFF067B35),
        const Color(0xFF027932),
        const Color(0xFF02774C),
        const Color(0xFF0168B5),
        const Color(0xFF0266D4),
      ],
      const Offset(71.000, 2.000),
      const Offset(193.713, 27.391),
    ),
    (
      Path()
        ..moveTo(146.000, 0.133)
        ..cubicTo(149.583, -1.353, 153.167, 1.533, 156.750, -0.425)
        ..cubicTo(160.333, -2.382, 163.917, -0.319, 167.500, -0.046)
        ..cubicTo(171.083, 0.228, 174.667, -2.028, 178.250, 0.752)
        ..cubicTo(181.833, 3.531, 185.417, 0.242, 189.000, 11.972)
        ..lineTo(189.000, 28.420)
        ..cubicTo(185.417, 28.804, 181.833, 20.899, 178.250, 19.398)
        ..cubicTo(174.667, 17.897, 171.083, 12.905, 167.500, 11.494)
        ..cubicTo(163.917, 10.082, 160.333, 7.190, 156.750, 5.793)
        ..cubicTo(153.167, 4.396, 149.583, 2.798, 146.000, 1.203)
        ..close(),
      'blue',
      [
        const Color(0xFF0D5CD4),
        const Color(0xFF0664D1),
        const Color(0xFF0263CF),
        const Color(0xFF0165D4),
        const Color(0xFF0568D5),
      ],
      const Offset(150.000, 1.000),
      const Offset(162.098, -13.847),
    ),
  ];
  static List<(Path, String, List<Color>, Offset, Offset)> footerMore() => [
    (
      Path(),
      'yellow',
      [
        const Color(0xFFFDCD02),
        const Color(0xFFFECD02),
        const Color(0xFFFECE02),
        const Color(0xFFFDCC05),
        const Color(0xFFFDAF06),
      ],
      const Offset(-16.788, 25.334),
      const Offset(42.615, -45.910),
    ),
    (
      Path(),
      'green',
      [
        const Color(0xFF027931),
        const Color(0xFF027931),
        const Color(0xFF027831),
        const Color(0xFF027730),
        const Color(0xFF027630),
      ],
      const Offset(-11.645, 78.068),
      const Offset(18.155, 23.704),
    ),
    (
      Path(),
      'red',
      [
        const Color(0xFFE71E23),
        const Color(0xFFE81F24),
        const Color(0xFFE82227),
        const Color(0xFFE72328),
        const Color(0xFFE6252B),
      ],
      const Offset(-12.779, 107.995),
      const Offset(84.443, 72.748),
    ),
    (
      Path(),
      'black',
      [
        const Color(0xFF11161C),
        const Color(0xFF0D1218),
        const Color(0xFF0A0E14),
        const Color(0xFF0C1016),
        const Color(0xFF0A0E13),
      ],
      const Offset(178.468, 145.910),
      const Offset(181.176, 70.079),
    ),
    (
      Path()
        ..moveTo(377.000, 57.800)
        ..cubicTo(384.083, 54.386, 391.167, 51.930, 398.250, 48.132)
        ..cubicTo(405.333, 44.334, 412.417, 41.290, 419.500, 36.847)
        ..cubicTo(426.583, 32.403, 433.667, 27.953, 440.750, 23.212)
        ..cubicTo(447.833, 18.471, 454.917, 12.651, 462.000, 7.088)
        ..lineTo(462.000, 71.838)
        ..cubicTo(454.917, 68.038, 447.833, 65.534, 440.750, 62.943)
        ..cubicTo(433.667, 60.353, 426.583, 58.113, 419.500, 57.853)
        ..cubicTo(412.417, 57.592, 405.333, 57.453, 398.250, 57.684)
        ..cubicTo(391.167, 57.915, 384.083, 58.479, 377.000, 59.190)
        ..close(),
      'blue',
      [
        const Color(0xFF075DC7),
        const Color(0xFF0062CF),
        const Color(0xFF006AD9),
        const Color(0xFF006EE0),
        const Color(0xFF016ADA),
      ],
      const Offset(363.281, 50.219),
      const Offset(391.443, -19.213),
    ),
    (
      Path(),
      'black',
      [
        const Color(0xFF0D0E13),
        const Color(0xFF0E1118),
        const Color(0xFF0E1218),
        const Color(0xFF11151A),
        const Color(0xFF151A21),
      ],
      const Offset(404.000, 67.000),
      const Offset(466.945, 128.960),
    ),
  ];
}
