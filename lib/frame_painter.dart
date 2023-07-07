import 'dart:math';

import 'package:flutter/material.dart';

class FramePainter extends CustomPainter {
  final Rect? boundingBox;
  final String text;

  const FramePainter({
    this.boundingBox,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    drawTheCircle(canvas, size);
  }

  @override
  bool shouldRepaint(FramePainter oldDelegate) {
    return oldDelegate.boundingBox != boundingBox;
  }

  void drawTheCircle(Canvas canvas, Size size) {
    const spaceLength = 10;
    const arcLength = 10.0;
    final center = size / 2;
    var startArc = 0.0;

    final rect = Rect.fromCenter(
      center: Offset(
        center.width,
        center.height,
      ),
      width: size.width,
      height: size.width,
    );

    var isOverlaps = false;
    if (boundingBox != null) {
      isOverlaps =
          boundingBox!.size.contains(rect.center) ||
          rect.size.contains(boundingBox!.center);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = isOverlaps ? Colors.green : Colors.white;

    for (int i = 0; i < 360 / (arcLength + spaceLength); i++) {
      canvas.drawArc(
        rect,
        inRads(startArc),
        inRads(arcLength),
        false,
        paint,
      );
      //the logic of spaces between the arcs is to start the next arc after jumping the length of space
      startArc += arcLength + spaceLength;
    }

    if (!isOverlaps) {
      drawTheText(canvas, size);
    }
  }

  void drawTheText(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Colors.blue,
      fontSize: 18,
    );

    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    final xCenter = (size.width - textPainter.width) / 2;
    final yCenter = (size.height - textPainter.height) / 2;
    final offset = Offset(xCenter, yCenter);
    textPainter.paint(canvas, offset);
  }

  //drawArc deals with rads, easier for me to use degrees
  //so this takes a degree and change it to rad
  double inRads(double degree) {
    return (degree * pi) / 180;
  }
}
