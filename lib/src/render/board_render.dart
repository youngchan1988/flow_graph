import 'package:flow_graph/src/render/preview_connect_render.dart';
import 'package:flow_graph/src/support/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../graph.dart';
import 'edge_render.dart';

class GraphBoard extends MultiChildRenderObjectWidget {
  GraphBoard(
      {Key? key,
      required this.graph,
      this.previewConnectStart = Offset.zero,
      this.previewConnectEnd = Offset.zero})
      : super(key: key, children: graph.children);

  final Graph graph;
  final Offset previewConnectStart;
  final Offset previewConnectEnd;

  @override
  RenderBox createRenderObject(BuildContext context) {
    debugInObject(object: this, message: 'createRenderObject');
    return _RenderLayoutBox(context: context, graph: graph);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderLayoutBox renderObject) {
    debugInObject(object: this, message: 'updateRenderObject');
    renderObject.graph = graph;
    renderObject.previewConnectStart = previewConnectStart;
    renderObject.previewConnectEnd = previewConnectEnd;
  }
}

class _RenderLayoutBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeParentData> {
  _RenderLayoutBox({
    required this.context,
    required Graph graph,
  }) : _graph = graph;

  final BuildContext context;
  Offset _previewConnectStart = Offset.zero;
  Offset _previewConnectEnd = Offset.zero;
  late Graph _graph;

  set previewConnectStart(Offset position) {
    _previewConnectStart = position;
  }

  set previewConnectEnd(Offset position) {
    _previewConnectEnd = position;
  }

  set graph(Graph g) {
    if (g != _graph) {
      _graph = g;
      markNeedsLayout();
    }
  }

  Graph get graph => _graph;

  final _edgeRender = EdgeRender();

  final _previewConnectRender = PreviewConnectRender();

  @override
  void performLayout() {
    debugInObject(object: this, message: 'performLayout');
    if (childCount == 0) {
      return;
    }
    //initial child element size
    var child = firstChild;
    var index = 0;
    var screenSize = MediaQuery.of(context).size;
    while (child != null) {
      final childData = child.parentData as NodeParentData;

      child.layout(BoxConstraints.loose(screenSize), parentUsesSize: true);
      var childSize = child.size;
      var element = graph.nodeAt(index).element;
      element.position =
          RelativeRect.fromLTRB(0, 0, childSize.width, childSize.height);
      element.familyPosition = element.position;
      child = childData.nextSibling;
      index++;
    }

    //compute graph nodes position
    graph.layout();
    var graphSize = graph.computeSize();
    debugInObject(object: this, message: 'GraphSize: $graphSize');
    var canvasSize = Size(
        graphSize.width > screenSize.width ? graphSize.width : screenSize.width,
        graphSize.height > constraints.maxHeight
            ? graphSize.height
            : constraints.maxHeight);
    // additionalConstraints = BoxConstraints.loose(canvasSize);
    size = canvasSize;

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
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    debugInObject(object: this, message: 'paint');
    var canvas = context.canvas;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _edgeRender.render(context: this.context, canvas: canvas, graph: _graph);
    canvas.restore();
    if (_previewConnectStart.distance > 0 && _previewConnectEnd.distance > 0) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      _previewConnectRender.rend(
          context: this.context,
          canvas: canvas,
          start: _previewConnectStart,
          end: _previewConnectEnd,
          direction: _graph.direction);
      canvas.restore();
    }
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
