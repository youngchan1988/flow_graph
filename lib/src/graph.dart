// Copyright (c) 2022, the flow_graph project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flow_graph/src/focus.dart';
import 'package:flow_graph/src/render/edge_render.dart';
import 'package:flutter/material.dart';
import 'package:ulid/ulid.dart';

typedef NodeWidgetBuilder<T> = Widget Function(
    BuildContext context, GraphNode<T> node);

typedef WillConnect<T> = bool Function(GraphNode<T> node);
typedef WillAccept<T> = bool Function(GraphNode<T> node);
typedef OnConnect<T> = void Function(GraphNode<T> prevNode, GraphNode<T> node);
typedef OnAccept<T> = void Function(GraphNode<T> prevNode, GraphNode<T> node);
typedef OnDeleted<T> = void Function(GraphNode<T> node);
typedef OnSelectChanged<T> = void Function(GraphNode<T>?);
typedef PaintCallback = void Function(Canvas);
typedef NodeSecondaryMenuItems = List<PopupMenuItem> Function(GraphNode);
typedef OnEdgeColor<T> = Color Function(GraphNode<T> node1, GraphNode<T> node2);

var kCrossAxisSpace = 48.0;
var kMainAxisSpace = 144.0;

class Graph<T> {
  Graph({
    required this.nodes,
    this.direction = Axis.horizontal,
    this.centerLayout = false,
    this.onEdgeColor,
  })  : assert(nodes.isNotEmpty),
        root = nodes.first {
    nodes.forEach((n1) {
      n1.nextList.forEach((n2) {
        if (n2 is! PreviewGraphNode) {
          edges.add(GraphEdge<T>(
              node1: n1 as GraphNode<T>,
              node2: n2 as GraphNode<T>,
              direction: direction,
              onEdgeColor: onEdgeColor));
        }
      });
    });
  }

  final GraphNode root;
  final Axis direction;
  final bool centerLayout;
  final List<GraphNode> nodes;
  final OnEdgeColor<T>? onEdgeColor;

  List<GraphEdge<T>> edges = [];

  List<Widget> get children {
    var nodeWidgets = nodes.map((e) => e.box.widget).toList();
    var edgeWidgets = edges.map((e) => e.edgetWidget).toList();
    return List.from(edgeWidgets)..addAll(nodeWidgets);
  }

  Size computeSize() => root.box.familySize;

  GraphElement elementAt(int index) {
    var list = List<GraphElement>.from(edges)..addAll(nodes);
    return list[index];
  }

  GraphNode<T>? nodeOf(Offset position) {
    for (var node in nodes) {
      if (node.box.position.contains(position)) {
        return node as GraphNode<T>;
      }
    }
    return null;
  }

  void layout() {
    //reset nodes position
    for (var node in nodes) {
      node.box.position = RelativeRect.fromLTRB(root.box.position.left,
          root.box.position.top, node.box.size.width, node.box.size.height);
      node.box.familyPosition = node.box.position;
    }
    //spread layout node
    _dfsSpreadNodes(root);
  }

  //dfs
  void _dfsSpreadNodes(GraphNode root) {
    //遍历路径
    var walked = <GraphNode>[root];
    //已遍历的节点
    var visited = <GraphNode>[];
    while (walked.isNotEmpty) {
      var current = walked.last;
      var canVisit = true;
      //初始family尾坐标，在遍历过程中不断更新这个值，最后确定最终的familyPosition
      double familyMainEnd = 0, familyCrossEnd = 0;
      if (direction == Axis.horizontal) {
        familyMainEnd = current.box.familyPosition.right;
        familyCrossEnd = current.box.familyPosition.bottom;
      } else if (direction == Axis.vertical) {
        familyMainEnd = current.box.familyPosition.bottom;
        familyCrossEnd = current.box.familyPosition.right;
      }
      if (current.nextList.isNotEmpty) {
        //初始出度节点的尾坐标，更新这个值纵向展开出度节点
        var currentCrossEnd = .0;
        if (direction == Axis.horizontal) {
          currentCrossEnd = current.box.familyPosition.top;
        } else if (direction == Axis.vertical) {
          currentCrossEnd = current.box.familyPosition.left;
        }
        //遍历出度节点
        for (var node in current.nextList) {
          assert(node.box != null);
          //if node is in currentNode's family
          //判断当前节点是否为该出度节点的"父节点"，
          if (node.prevList.first == current) {
            if (!visited.contains(node)) {
              if (direction == Axis.horizontal) {
                //horizontal spread
                //横向展开节点
                var left = current.box.familyPosition.right + kMainAxisSpace;
                //vertical spread
                //纵向展开节点
                var top = currentCrossEnd;
                var size = node.box.size;
                //更新当前遍历的familyPosition
                node.box.familyPosition = RelativeRect.fromLTRB(
                    left, top, left + size.width, top + size.height);
              } else if (direction == Axis.vertical) {
                //horizontal spread
                var left = currentCrossEnd;
                //vertical spread
                var top = current.box.familyPosition.top + kMainAxisSpace;
                var size = node.box.size;
                node.box.familyPosition = RelativeRect.fromLTRB(
                    left, top, left + size.width, top + size.height);
              }
              walked.add(node);
              canVisit = false;
              break;
            } else {
              //已遍历过的节点，更新familyPosition 的区域
              if (direction == Axis.horizontal) {
                familyCrossEnd =
                    math.max(familyCrossEnd, node.box.familyPosition.bottom);
                familyMainEnd =
                    math.max(familyMainEnd, node.box.familyPosition.right);
                //update vertical size
                currentCrossEnd =
                    node.box.familyPosition.bottom + kCrossAxisSpace;
              } else if (direction == Axis.vertical) {
                familyCrossEnd =
                    math.max(familyCrossEnd, node.box.familyPosition.right);
                familyMainEnd =
                    math.max(familyMainEnd, node.box.familyPosition.bottom);
                //update horizontal size
                currentCrossEnd =
                    node.box.familyPosition.right + kCrossAxisSpace;
              }
            }
          }
        }
      }
      if (canVisit) {
        //update current node position & family position
        //当前节点的出度节点都遍历完成后，根据更新后的familyPosition，重新计算当前节点的自身position
        var nodeSize = current.box.size;
        var familyPosition = current.box.familyPosition;
        if (direction == Axis.horizontal) {
          familyPosition = current.box.familyPosition
              .copyWith(right: familyMainEnd, bottom: familyCrossEnd);
          var top = familyPosition.top;
          if (centerLayout) {
            top = familyPosition.top +
                (familyPosition.bottom - familyPosition.top - nodeSize.height) /
                    2;
          }
          current.box.position = RelativeRect.fromLTRB(familyPosition.left, top,
              familyPosition.left + nodeSize.width, top + nodeSize.height);
        } else if (direction == Axis.vertical) {
          familyPosition = current.box.familyPosition
              .copyWith(right: familyCrossEnd, bottom: familyMainEnd);
          var left = familyPosition.left;
          if (centerLayout) {
            left = familyPosition.left +
                (familyPosition.right - familyPosition.left - nodeSize.width) /
                    2;
          }
          current.box.position = RelativeRect.fromLTRB(left, familyPosition.top,
              left + nodeSize.width, familyPosition.top + nodeSize.height);
        }

        current.box.familyPosition = familyPosition;

        //visit node
        visited.add(current);

        walked.removeLast();
      }
    }
  }
}

abstract class GraphElement {
  GraphElement({GraphFocusNode? focusNode}) : _focusNode = focusNode;

  GraphFocusNode? _focusNode;

  GraphFocusNode get focusNode => _focusNode ??= GraphFocusNode();
}

class GraphNode<T> extends GraphElement {
  GraphNode(
      {this.data,
      this.isRoot = false,
      GraphFocusNode? focusNode,
      List<GraphNode>? prevList,
      List<GraphNode>? nextList})
      : id = Ulid().hashCode,
        _prevList = prevList,
        _nextList = nextList,
        super(focusNode: focusNode);

  final int id;
  T? data;

  final bool isRoot;

  late GraphNodeBox _box;

  GraphNodeBox get box => _box;

  List<GraphNode>? _prevList;
  List<GraphNode>? _nextList;

  List<GraphNode> get prevList => _prevList ??= [];
  List<GraphNode> get nextList => _nextList ??= [];

  void addNext(GraphNode node) {
    nextList.add(node);
    node.prevList.add(this);
  }

  void deleteNext(GraphNode node) {
    // if (_nextList?.contains(node) == true) {
    //   _nextList!.remove(node);
    //   node._prevList?.remove(this);
    // }
    node.deleteSelf();
  }

  void clearAllNext() {
    if (_nextList?.isNotEmpty == true) {
      for (var nextNode in _nextList!) {
        if (nextNode._prevList?.contains(this) == true) {
          nextNode._prevList!.remove(this);
        }
      }
    }
    _nextList?.clear();
  }

  void deleteSelf() {
    if (_prevList?.isNotEmpty == true) {
      for (var prevNode in _prevList!) {
        if (prevNode._nextList?.contains(this) == true) {
          prevNode._nextList!.remove(this);
        }
      }
    }
    if (_nextList?.isNotEmpty == true) {
      for (var nextNode in _nextList!) {
        if (nextNode._prevList?.contains(this) == true) {
          nextNode._prevList!.remove(this);
        }
      }
    }

    _prevList?.clear();
    _nextList?.clear();
  }

  void buildBox(
      {required Widget childWidget,
      EdgeInsets overflowPadding = EdgeInsets.zero}) {
    _box = GraphNodeBox(widget: childWidget, overflowPadding: overflowPadding);
  }
}

class PreviewGraphNode extends GraphNode {
  PreviewGraphNode({this.color}) : super() {
    _box = GraphNodeBox(
        widget: Container(
      width: 60,
      height: 24,
      color: color ?? Colors.lightBlue,
    ));
  }

  final Color? color;
}

class GraphEdge<T> extends GraphElement with ChangeNotifier {
  GraphEdge(
      {required this.node1,
      required this.node2,
      required Axis direction,
      this.onEdgeColor})
      : _direction = direction {
    _edgeWidget = Edge(
      graphEdge: this,
      onCustomEdgeColor: () {
        return onEdgeColor?.call(node1, node2) ?? Colors.grey;
      },
    );
  }

  Axis _direction;
  Axis get direction => _direction;

  set direction(Axis axis) {
    if (axis != _direction) {
      _direction = axis;
      notifyListeners();
    }
  }

  final GraphNode<T> node1;
  final GraphNode<T> node2;
  late Edge _edgeWidget;
  final OnEdgeColor<T>? onEdgeColor;

  bool selected = false;

  Offset _lineStart = Offset.zero;
  Offset _lineEnd = Offset.zero;

  Offset get lineStart => _lineStart;

  Offset get lineEnd => _lineEnd;

  Edge get edgetWidget => _edgeWidget;

  Offset widgetOffset(Size originSize) {
    var node1Box = node1.box;
    var node2Box = node2.box;
    if (direction == Axis.horizontal) {
      if ((node2Box.position.top + node2Box.size.height / 2) <
          (node1Box.position.top + node1Box.size.height / 2)) {
        _lineStart = Offset(
            0,
            node1Box.position.top -
                node2Box.position.top -
                node2Box.size.height / 2 +
                node1Box.size.height / 2 +
                triangleArrowHeight / 2);
        _lineEnd = Offset(
            node2Box.position.left -
                node1Box.position.right +
                node2Box.overflowPadding.left +
                node1Box.overflowPadding.right,
            triangleArrowHeight / 2);
        return Offset(
            node1Box.position.right - node1Box.overflowPadding.right,
            node2Box.position.top +
                node2Box.size.height / 2 -
                triangleArrowHeight / 2);
      } else {
        _lineStart = Offset(0, triangleArrowHeight / 2);
        _lineEnd = Offset(
            node2Box.position.left -
                node1Box.position.right +
                node2Box.overflowPadding.left +
                node1Box.overflowPadding.right,
            node2Box.position.top -
                node1Box.position.top -
                node1Box.size.height / 2 +
                node2Box.size.height / 2 +
                triangleArrowHeight / 2);
        return Offset(
            node1Box.position.right - node1Box.overflowPadding.right,
            node1Box.position.top +
                node1Box.size.height / 2 -
                triangleArrowHeight / 2);
      }
    } else {
      if ((node2Box.position.left + node2Box.size.width / 2) <
          (node1Box.position.left + node1Box.size.width / 2)) {
        _lineStart = Offset(
            node1Box.position.left -
                node2Box.position.left -
                node2Box.size.width / 2 +
                node1Box.size.width / 2 +
                triangleArrowHeight / 2,
            0);
        _lineEnd = Offset(
            triangleArrowHeight / 2,
            node2Box.position.top -
                node1Box.position.bottom +
                node2Box.overflowPadding.top +
                node2Box.overflowPadding.bottom);
        return Offset(
            node2Box.position.left +
                node2Box.size.width / 2 -
                triangleArrowHeight / 2,
            node1Box.position.bottom - node1Box.overflowPadding.bottom);
      } else {
        _lineStart = Offset(triangleArrowHeight / 2, 0);
        _lineEnd = Offset(
            node2Box.position.left -
                node1Box.position.left -
                node1Box.size.width / 2 +
                node2Box.size.width / 2 +
                triangleArrowHeight / 2,
            node2Box.position.top -
                node1Box.position.bottom +
                node2Box.overflowPadding.top +
                node1Box.overflowPadding.bottom);
        return Offset(
            node1Box.position.left +
                node1Box.size.width / 2 -
                triangleArrowHeight / 2,
            node1Box.position.bottom - node1Box.overflowPadding.bottom);
      }
    }
  }

  void updateEdge() {
    notifyListeners();
  }

  void deleteSelf() {
    node1.deleteNext(node2);
  }
}

class GraphNodeFactory<T> {
  GraphNodeFactory({required this.dataBuilder});

  final T Function() dataBuilder;

  GraphNode<T> createNode() => GraphNode<T>(
        data: dataBuilder(),
      );
}

class GraphNodeBox with ChangeNotifier {
  GraphNodeBox({
    required this.widget,
    this.overflowPadding = EdgeInsets.zero,
  });

  final Widget widget;

  final EdgeInsets overflowPadding;

  RelativeRect _position = RelativeRect.fill;

  RelativeRect get position => _position;

  set position(RelativeRect rect) {
    _position = rect;
    notifyListeners();
  }

  RelativeRect _familyPosition = RelativeRect.fill;

  RelativeRect get familyPosition => _familyPosition;
  set familyPosition(RelativeRect rect) {
    _familyPosition = rect;
    notifyListeners();
  }

  Offset get centerPoint => Offset(
      position.left + (position.right - position.left) / 2,
      position.top + (position.bottom - position.top) / 2);

  Size get size =>
      Size(position.right - position.left, position.bottom - position.top);

  Size get familySize => Size(familyPosition.right - familyPosition.left,
      familyPosition.bottom - familyPosition.top);
}

extension RelativeRectEx on RelativeRect {
  RelativeRect copyWith(
          {double? left, double? top, double? right, double? bottom}) =>
      RelativeRect.fromLTRB(left ?? this.left, top ?? this.top,
          right ?? this.right, bottom ?? this.bottom);

  bool contains(Offset point) =>
      point.dx >= left &&
      point.dx <= right &&
      point.dy >= top &&
      point.dy <= bottom;

  RelativeRect offset(Offset offset) => RelativeRect.fromLTRB(
      left + offset.dx, top + offset.dy, right + offset.dx, bottom + offset.dy);

  RelativeRect spreadSize(Size size) => RelativeRect.fromLTRB(
      left, top, right + size.width, bottom + size.height);
}
