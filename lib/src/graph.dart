import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ulid/ulid.dart';

var kCrossAxisSpace = 48.0;
var kMainAxisSpace = 144.0;

class Graph {
  Graph({
    required this.nodes,
    this.direction = Axis.horizontal,
  })  : assert(nodes.isNotEmpty),
        root = nodes.first;

  final GraphNode root;
  final Axis direction;
  final List<GraphNode> nodes;

  List<Widget> get children => nodes.map((e) => e.element.widget).toList();

  Size computeSize() => root.element.familySize;

  void layout() {
    //reset nodes position
    for (var node in nodes) {
      node.element.position = RelativeRect.fromLTRB(
          root.element.position.left,
          root.element.position.top,
          node.element.size.width,
          node.element.size.height);
      node.element.familyPosition = node.element.position;
    }
    //spread layout node
    _dfsSpreadNodes(root.element);
  }

  GraphNode nodeAt(int index) => nodes[index];

  //dfs
  void _dfsSpreadNodes(GraphNodeElement root) {
    //遍历路径
    var walked = <GraphNodeElement>[root];
    //已遍历的节点
    var visited = <GraphNodeElement>[];
    while (walked.isNotEmpty) {
      var currentElement = walked.last;
      var canVisit = true;
      //初始family尾坐标，在遍历过程中不断更新这个值，最后确定最终的familyPosition
      double familyMainEnd = 0, familyCrossEnd = 0;
      if (direction == Axis.horizontal) {
        familyMainEnd = currentElement.familyPosition.right;
        familyCrossEnd = currentElement.familyPosition.bottom;
      } else if (direction == Axis.vertical) {
        familyMainEnd = currentElement.familyPosition.bottom;
        familyCrossEnd = currentElement.familyPosition.right;
      }
      if (currentElement.node.nextList.isNotEmpty) {
        //初始出度节点的尾坐标，更新这个值纵向展开出度节点
        var currentCrossEnd = .0;
        if (direction == Axis.horizontal) {
          currentCrossEnd = currentElement.familyPosition.top;
        } else if (direction == Axis.vertical) {
          currentCrossEnd = currentElement.familyPosition.left;
        }
        //遍历出度节点
        for (var node in currentElement.node.nextList) {
          //if node is in currentNode's family
          //判断当前节点是否为该出度节点的"父节点"，
          if (node.prevList.first == currentElement.node) {
            var element = node.element;
            if (!visited.contains(element)) {
              if (direction == Axis.horizontal) {
                //horizontal spread
                //横向展开节点
                var left = currentElement.familyPosition.right + kMainAxisSpace;
                //vertical spread
                //纵向展开节点
                var top = currentCrossEnd;
                var size = element.size;
                //更新当前遍历的familyPosition
                element.familyPosition = RelativeRect.fromLTRB(
                    left, top, left + size.width, top + size.height);
              } else if (direction == Axis.vertical) {
                //horizontal spread
                var left = currentCrossEnd;
                //vertical spread
                var top = currentElement.familyPosition.top + kMainAxisSpace;
                var size = element.size;
                element.familyPosition = RelativeRect.fromLTRB(
                    left, top, left + size.width, top + size.height);
              }
              walked.add(element);
              canVisit = false;
              break;
            } else {
              //已遍历过的节点，更新familyPostion 的区域
              if (direction == Axis.horizontal) {
                familyCrossEnd =
                    math.max(familyCrossEnd, element.familyPosition.bottom);
                familyMainEnd =
                    math.max(familyMainEnd, element.familyPosition.right);
                //update vertical size
                currentCrossEnd =
                    element.familyPosition.bottom + kCrossAxisSpace;
              } else if (direction == Axis.vertical) {
                familyCrossEnd =
                    math.max(familyCrossEnd, element.familyPosition.right);
                familyMainEnd =
                    math.max(familyMainEnd, element.familyPosition.bottom);
                //update horizontal size
                currentCrossEnd =
                    element.familyPosition.right + kCrossAxisSpace;
              }
            }
          }
        }
      }
      if (canVisit) {
        //update current node position & family position
        //当前节点的出度节点都遍历完成后，根据更新后的familyPosition，重新计算当前节点的自身position
        var nodeSize = currentElement.size;
        var familyPosition = currentElement.familyPosition;
        if (direction == Axis.horizontal) {
          familyPosition = currentElement.familyPosition
              .copyWith(right: familyMainEnd, bottom: familyCrossEnd);
        } else if (direction == Axis.vertical) {
          familyPosition = currentElement.familyPosition
              .copyWith(right: familyCrossEnd, bottom: familyMainEnd);
        }
        currentElement.position = RelativeRect.fromLTRB(
            familyPosition.left,
            familyPosition.top,
            familyPosition.left + nodeSize.width,
            familyPosition.top + nodeSize.height);
        currentElement.familyPosition = familyPosition;

        //visit node
        visited.add(currentElement);

        walked.removeLast();
      }
    }
  }
}

class GraphNode<T> {
  GraphNode(
      {required this.data,
      this.isRoot = false,
      List<GraphNode>? prevList,
      List<GraphNode>? nextList})
      : id = Ulid().hashCode,
        _prevList = prevList,
        _nextList = nextList;

  final int id;
  T data;

  final bool isRoot;

  late GraphNodeElement _element;

  GraphNodeElement get element => _element;

  List<GraphNode>? _prevList;
  List<GraphNode>? _nextList;

  List<GraphNode> get prevList => _prevList ??= [];
  List<GraphNode> get nextList => _nextList ??= [];

  void addNext(GraphNode node) {
    nextList.add(node);
    node.prevList.add(this);
  }

  GraphNodeElement initialElement({required Widget child}) {
    _element = GraphNodeElement(node: this, widget: child);
    return _element;
  }
}

class GraphNodeElement {
  GraphNodeElement(
      {required this.node,
      required this.widget,
      List<GraphNodeElement>? preList,
      List<GraphNodeElement>? nextList,
      this.position = RelativeRect.fill,
      this.familyPosition = RelativeRect.fill});

  final GraphNode node;

  final Widget widget;

  RelativeRect position;

  RelativeRect familyPosition;

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
}
