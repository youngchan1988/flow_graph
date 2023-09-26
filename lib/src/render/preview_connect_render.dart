// Copyright (c) 2022, the flow_graph project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../graph.dart';

const _kNodeEdgeSpacing = 12;

double triangleArrowHeight = 8.0;

class PreviewConnectRender {
  final _linePath = Path();
  final _paint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final _trianglePaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.fill;

  static Offset _rotateVector(Offset vector, double angle) => Offset(
        math.cos(angle) * vector.dx - math.sin(angle) * vector.dy,
        math.sin(angle) * vector.dx + math.cos(angle) * vector.dy,
      );

  void _drawTriArrow(Canvas canvas, Path path, Paint paint) {
    double triHeight = triangleArrowHeight;
    var lastPathMetric = path.computeMetrics().last;
    var t = lastPathMetric.getTangentForOffset(lastPathMetric.length);
    //按当前的向量角度位移,
    var offset =
        Offset(triHeight * math.cos(-t!.angle), triHeight * math.sin(-t.angle));
    //计算三角形指向的顶点
    var tan = Tangent(t.position + offset, t.vector);

    var triPath = Path()..moveTo(tan.position.dx, tan.position.dy - 0.5);
    var angle = math.pi - 0.463; //(math.atan2(1,2)的值)
    var triHypotenuse = (triHeight / math.cos(0.463)); //边长
    //旋转放大
    var tipVector = _rotateVector(tan.vector, angle) * triHypotenuse;
    var p1 = tan.position + tipVector; //底边顶点
    tipVector = _rotateVector(tan.vector, -angle) * triHypotenuse;
    var p2 = tan.position + tipVector; //底边顶点
    triPath.lineTo(p1.dx, p1.dy);
    triPath.lineTo(p2.dx, p2.dy);
    triPath.close();
    canvas.drawPath(triPath, paint);
  }

  void render(
      {required BuildContext context,
      required Canvas canvas,
      required Offset start,
      required Offset end,
      required Axis direction}) {
    _linePath.reset();
    var paintColor = Theme.of(context).colorScheme.secondaryContainer;
    _paint.color = paintColor;
    _trianglePaint.color = paintColor;
    if (direction == Axis.horizontal) {
      _linePath.moveTo(start.dx, start.dy);
      _linePath.cubicTo(
          start.dx + kMainAxisSpace / 2,
          start.dy,
          end.dx - kMainAxisSpace / 2,
          end.dy,
          end.dx - triangleArrowHeight,
          end.dy);
    } else if (direction == Axis.vertical) {
      _linePath.moveTo(start.dx, start.dy);
      _linePath.cubicTo(start.dx, start.dy + kMainAxisSpace / 2, end.dx,
          end.dy - kMainAxisSpace / 2, end.dx, end.dy - triangleArrowHeight);
    }
    canvas.drawPath(_linePath, _paint);
    _drawTriArrow(canvas, _linePath, _trianglePaint);
  }
}
