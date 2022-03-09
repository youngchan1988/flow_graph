// Copyright (c) 2022, the flow_graph project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../graph.dart';
import 'edge_render.dart';

class GraphBoard extends MultiChildRenderObjectWidget {
  GraphBoard({
    Key? key,
    required this.graph,
    this.position = Offset.zero,
    this.onPaint,
  }) : super(key: key, children: graph.children);

  final Graph graph;
  final Offset position;
  final PaintCallback? onPaint;

  @override
  RenderBox createRenderObject(BuildContext context) {
    return _RenderBoard(context: context, graph: graph, onPaint: onPaint);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderBoard renderObject) {
    renderObject.graph = graph;
    renderObject.positionOffset = position;
    renderObject.onPaint = onPaint;
  }
}

class _RenderBoard extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeParentData> {
  _RenderBoard({
    required this.context,
    required Graph graph,
    this.onPaint,
  }) : _graph = graph;

  final BuildContext context;
  PaintCallback? onPaint;

  Offset _positionOffset = Offset.zero;
  late Graph _graph;

  set positionOffset(Offset position) {
    if (_positionOffset != position) {
      _positionOffset = position;
      markNeedsLayout();
    }
  }

  set graph(Graph g) {
    if (g != _graph) {
      _graph = g;
      markNeedsLayout();
    }
  }

  Graph get graph => _graph;

  final _edgeRender = EdgeRender();

  @override
  void performLayout() {
    if (childCount == 0) {
      return;
    }
    //initial child element size
    var child = firstChild;
    var index = 0;
    while (child != null) {
      final childData = child.parentData as NodeParentData;
      child.layout(BoxConstraints.loose(constraints.biggest),
          parentUsesSize: true);
      var childSize = child.size;
      var element = graph.elementAt(index);
      if (element is GraphNode) {
        element.box.position =
            RelativeRect.fromLTRB(0, 0, childSize.width, childSize.height);
        element.box.familyPosition = element.box.position;
      }

      child = childData.nextSibling;
      index++;
    }

    //compute graph nodes position
    graph.layout();

    size = constraints.biggest;

    //layout child's offset
    child = firstChild;
    index = 0;
    while (child != null) {
      final childData = child.parentData as NodeParentData;
      var element = graph.elementAt(index);
      if (element is GraphNode) {
        childData.offset = Offset(
            element.box.position.left + _positionOffset.dx,
            element.box.position.top + _positionOffset.dy);
      } else if (element is GraphEdge) {
        childData.offset = element.widgetOffset(child.size) + _positionOffset;
        element.updateEdge();
      }
      //add position offset to child

      child = childData.nextSibling;
      index++;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _edgeRender.render(
        context: this.context,
        canvas: canvas,
        graph: _graph,
        offset: _positionOffset);
    onPaint?.call(canvas);
    canvas.restore();
    defaultPaint(context, offset);
  }

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! NodeParentData) {
      child.parentData = NodeParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Graph>('graph', graph));
  }
}

class NodeParentData extends ContainerBoxParentData<RenderBox> {}
