// Copyright (c) 2022, the flow_graph project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flow_graph/src/focus.dart';
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
      var nodeBox = node.box;
      node.nextList.forEach((child) {
        if (child is PreviewGraphNode) {
          _linePath.reset();
          var childBox = child.box;
          if (graph.direction == Axis.horizontal) {
            var start = Offset(
                nodeBox.position.right -
                    nodeBox.overflowPadding.right +
                    offset.dx,
                (nodeBox.position.top + nodeBox.position.bottom) / 2 +
                    offset.dy);
            var end = Offset(
                childBox.position.left + offset.dx,
                (childBox.position.top + childBox.position.bottom) / 2 +
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
                (nodeBox.position.left + nodeBox.position.right) / 2 +
                    offset.dx,
                nodeBox.position.bottom -
                    nodeBox.overflowPadding.bottom +
                    offset.dy);
            var end = Offset(
                (childBox.position.left + childBox.position.right) / 2 +
                    offset.dx,
                childBox.position.top +
                    nodeBox.overflowPadding.top +
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
          _paint.color = Theme.of(context).colorScheme.secondary;
          _trianglePaint.color = Theme.of(context).colorScheme.secondary;
          canvas.drawPath(_linePath, _paint);
          _drawTriArrow(canvas, _linePath, _trianglePaint);
        }
      });
    });
  }
}

class Edge extends StatefulWidget {
  const Edge(
      {Key? key, required this.graphEdge, this.painter, this.enabled = true})
      : super(key: key);

  final CustomPainter? painter;
  final bool enabled;
  final GraphEdge graphEdge;

  @override
  _EdgeState createState() => _EdgeState();
}

class _EdgeState extends State<Edge> {
  _EdgePainter? _painter;

  void _onGraphEdgeChanged() {
    _painter?.start = widget.graphEdge.lineStart;
    _painter?.end = widget.graphEdge.lineEnd;
    if (mounted) {
      _needBuild();
    }
  }

  Future _needBuild() async {
    await Future.delayed(Duration(milliseconds: 300));
    setState(() {});
  }

  @override
  void initState() {
    widget.graphEdge.addListener(_onGraphEdgeChanged);

    widget.graphEdge.focusNode.addListener(() {
      if (!widget.graphEdge.focusNode.hasFocus && mounted) {
        widget.graphEdge.selected = false;
        _painter?.reset();
      }
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant Edge oldWidget) {
    if (widget.graphEdge != oldWidget.graphEdge) {
      _painter?.direction = widget.graphEdge.direction;
      widget.graphEdge.addListener(_onGraphEdgeChanged);
      widget.graphEdge.focusNode.addListener(() {
        if (widget.graphEdge.focusNode.hasFocus) {
        } else {
          widget.graphEdge.selected = false;
          _painter?.reset();
        }
      });
    }
    // _onGraphEdgeChanged();

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.graphEdge.removeListener(_onGraphEdgeChanged);
    widget.graphEdge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _painter ??= _EdgePainter(
        color: Colors.grey,
        selectedColor: Theme.of(context).colorScheme.secondaryVariant,
        width: 2,
        direction: widget.graphEdge.direction);
    return GestureDetector(
      onTap: () {
        GraphFocus.of(context).requestFocus(widget.graphEdge.focusNode);
        widget.graphEdge.selected = true;
        _painter?.onSelect();
      },
      child: CustomPaint(
        painter: _painter,
        size: _painter!.size,
      ),
    );
  }
}

class _EdgePainter extends CustomPainter with ChangeNotifier {
  _EdgePainter(
      {this.color = Colors.grey,
      this.selectedColor = Colors.greenAccent,
      double width = 2,
      this.direction = Axis.horizontal,
      this.start = Offset.zero,
      this.end = Offset.zero}) {
    this.width = width;
    _setPainterColor(color);
  }
  final Color selectedColor;
  final Color color;

  final _linePath = Path();
  final _paint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final _trianglePaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.fill;

  Offset start;
  Offset end;
  Axis direction = Axis.horizontal;
  bool _selected = false;
  bool get selected => _selected;

  bool _hovered = false;
  bool get hovered => _hovered;

  double _width = 2;
  double get width => _width;
  set width(double w) {
    _width = w;
    _paint.strokeWidth = w;
  }

  void _setPainterColor(Color c) {
    _paint.color = c;
    _trianglePaint.color = c;
    notifyListeners();
  }

  Size get size => direction == Axis.horizontal
      ? Size(end.dx - start.dx, (end.dy - start.dy).abs() + triangleArrowHeight)
      : Size(
          (end.dx - start.dx).abs() + triangleArrowHeight, end.dy - start.dy);

  Offset _rotateVector(Offset vector, double angle) => Offset(
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

  @override
  void paint(Canvas canvas, Size size) {
    _linePath.reset();
    _linePath.moveTo(start.dx, start.dy);
    if (direction == Axis.horizontal) {
      _linePath.cubicTo(
          start.dx + (end.dx - start.dx) / 2,
          start.dy,
          start.dx + (end.dx - start.dx) / 2,
          end.dy,
          end.dx - triangleArrowHeight,
          end.dy);
    } else {
      _linePath.cubicTo(
          start.dx,
          start.dy + (end.dy - start.dy) / 2,
          end.dx,
          start.dy + (end.dy - start.dy) / 2,
          end.dx,
          end.dy - triangleArrowHeight);
    }

    canvas.drawPath(_linePath, _paint);

    _drawTriArrow(canvas, _linePath, _trianglePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    var oldPainter = oldDelegate as _EdgePainter;
    return start != oldPainter.start ||
        end != oldPainter.end ||
        color != oldPainter.color ||
        direction != oldPainter.direction;
  }

  void reset() {
    _selected = false;
    _hovered = false;
    _setPainterColor(color);
  }

  void onSelect() {
    if (!_selected) {
      _selected = true;
      _setPainterColor(selectedColor);
    }
  }

  void onHoverEnter() {
    if (!_selected && !_hovered) {
      _setPainterColor(selectedColor.withAlpha(180));
      _hovered = true;
    }
  }

  void onHoverLeave() {
    if (_hovered && !_selected) {
      _setPainterColor(color);
      _hovered = false;
    }
  }

  @override
  bool? hitTest(Offset position) {
    var c = false;

    if (start.dy == end.dy) {
      c = position.dx >= 0 &&
          position.dx <= size.width &&
          position.dy >= triangleArrowHeight / 2 - width / 2 &&
          position.dy <= triangleArrowHeight / 2 + width / 2;
    } else if (start.dx == end.dx) {
      c = position.dy >= 0 &&
          position.dy <= size.height &&
          position.dx >= triangleArrowHeight / 2 - width / 2 &&
          position.dx <= triangleArrowHeight / 2 + width / 2;
    } else {
      c = _linePath.contains(position) ||
          _linePath.contains(Offset(position.dx, position.dy - 1)) ||
          _linePath.contains(Offset(position.dx, position.dy + 1)) ||
          _linePath.contains(Offset(position.dx - 1, position.dy)) ||
          _linePath.contains(Offset(position.dx + 1, position.dy));
    }
    if (c) {
      onHoverEnter();
    } else {
      onHoverLeave();
    }
    return c;
  }
}
