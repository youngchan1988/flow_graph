import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../graph.dart';

double triangleArrowHeight = 8.0;

class EdgeRender {
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
      required Graph graph,
      Offset offset = Offset.zero}) {
    graph.nodes.forEach((node) {
      var nodeElement = node.element;
      node.nextList.forEach((child) {
        _linePath.reset();
        var childElement = child.element;
        if (graph.direction == Axis.horizontal) {
          var start = Offset(
              nodeElement.position.right -
                  nodeElement.overflowPadding.right +
                  offset.dx,
              (nodeElement.position.top + nodeElement.position.bottom) / 2 +
                  offset.dy);
          var end = Offset(
              childElement.position.left +
                  nodeElement.overflowPadding.left +
                  offset.dx,
              (childElement.position.top + childElement.position.bottom) / 2 +
                  offset.dy);
          _linePath.moveTo(start.dx, start.dy);
          _linePath.cubicTo(
              start.dx + kMainAxisSpace / 2,
              start.dy,
              end.dx - kMainAxisSpace / 2,
              end.dy,
              end.dx - triangleArrowHeight,
              end.dy);
        } else if (graph.direction == Axis.vertical) {
          var start = Offset(
              (nodeElement.position.left + nodeElement.position.right) / 2 +
                  offset.dx,
              nodeElement.position.bottom -
                  nodeElement.overflowPadding.bottom +
                  offset.dy);
          var end = Offset(
              (childElement.position.left + childElement.position.right) / 2 +
                  offset.dx,
              childElement.position.top +
                  nodeElement.overflowPadding.top +
                  offset.dy);
          _linePath.moveTo(start.dx, start.dy);
          _linePath.cubicTo(
              start.dx,
              start.dy + kMainAxisSpace / 2,
              end.dx,
              end.dy - kMainAxisSpace / 2,
              end.dx,
              end.dy - triangleArrowHeight);
        }
        if (child is PreviewGraphNode) {
          _paint.color = Theme.of(context).colorScheme.secondary;
          _trianglePaint.color = Theme.of(context).colorScheme.secondary;
        } else {
          _paint.color = Colors.grey;
          _trianglePaint.color = Colors.grey;
        }
        canvas.drawPath(_linePath, _paint);
        _drawTriArrow(canvas, _linePath, _trianglePaint);
      });
    });
  }
}
