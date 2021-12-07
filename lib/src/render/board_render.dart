import 'package:flow_graph/src/support/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../graph.dart';
import 'edge_render.dart';

class GraphBoard extends MultiChildRenderObjectWidget {
  GraphBoard({Key? key, required this.graph})
      : super(key: key, children: graph.children);

  final Graph graph;

  @override
  RenderBox createRenderObject(BuildContext context) {
    debugInObject(object: this, message: 'createRenderObject');
    return RenderLayoutBox(graph: graph);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderLayoutBox renderObject) {
    debugInObject(object: this, message: 'updateRenderObject');
    renderObject.graph = graph;
  }
}

class RenderLayoutBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeParentData> {
  RenderLayoutBox({
    required Graph graph,
  }) : _graph = graph;

  late Graph _graph;

  set graph(Graph g) {
    _graph = g;
    markNeedsLayout();
  }

  Graph get graph => _graph;

  final _edgeRender = EdgeRender();

  @override
  void performLayout() {
    debugInObject(object: this, message: 'performLayout');
    if (childCount == 0) {
      return;
    }
    //initial child element size
    var child = firstChild;
    var index = 0;
    while (child != null) {
      final childData = child.parentData as NodeParentData;
      child.layout(constraints, parentUsesSize: true);
      var childSize = child.getDryLayout(constraints);
      var element = graph.nodeAt(index).element;
      element.position =
          RelativeRect.fromLTRB(0, 0, childSize.width, childSize.height);
      element.familyPosition = element.position;
      child = childData.nextSibling;
      index++;
    }

    //compute graph nodes position
    graph.layout();

    //layout child's offset
    child = firstChild;
    index = 0;
    while (child != null) {
      final childData = child.parentData as NodeParentData;
      var element = graph.nodeAt(index).element;
      childData.offset = Offset(element.position.left, element.position.top);

      child = childData.nextSibling;
      index++;
    }
    super.performLayout();
  }

  @override
  void performResize() {
    debugInObject(object: this, message: 'performResize');
    super.performResize();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    var size = graph.computeSize();
    debugInObject(object: this, message: 'computeDryLayout: $size');
    return size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    debugInObject(object: this, message: 'paint offset: $offset');
    var canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    _edgeRender.render(canvas: canvas, graph: graph);

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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Graph>('graph', graph));
  }
}

class NodeParentData extends ContainerBoxParentData<RenderBox> {}
