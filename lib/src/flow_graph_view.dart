// Copyright (c) 2022, the flow_graph project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'focus.dart';
import 'graph.dart';
import 'graph_view.dart';

class FlowGraphView<T> extends StatefulWidget {
  const FlowGraphView(
      {Key? key,
      required this.root,
      this.direction = Axis.horizontal,
      this.centerLayout = false,
      this.enabled = true,
      required this.builder,
      this.onSelectChanged,
      this.onEdgeColor})
      : super(key: key);

  final GraphNode<T> root;
  final Axis direction;
  final bool centerLayout;
  final bool enabled;
  final NodeWidgetBuilder<T> builder;
  final OnSelectChanged<T>? onSelectChanged;

  ///Custom edge color
  final OnEdgeColor<T>? onEdgeColor;

  @override
  _FlowGraphViewState<T> createState() => _FlowGraphViewState<T>();
}

class _FlowGraphViewState<T> extends State<FlowGraphView<T>> {
  final GraphFocusManager _focusManager = GraphFocusManager();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GraphFocus(
        manager: _focusManager,
        child: Builder(
          builder: (context) {
            var graph = Graph(
                nodes: _linearNodes(context, widget.root),
                direction: widget.direction,
                centerLayout: widget.centerLayout,
                onEdgeColor: widget.onEdgeColor);

            return GestureDetector(
              onTap: () {
                GraphFocus.of(context).clearFocus();
                widget.onSelectChanged?.call(null);
              },
              child: GraphView<T>(graph: graph),
            );
          },
        ),
      ),
    );
  }

  //bfs
  List<GraphNode> _linearNodes(BuildContext context, GraphNode<T> root) {
    root.buildBox(
        childWidget: widget.enabled
            ? _NodeWidget(
                child: widget.builder(context, root),
                node: root,
                onFocus: () {
                  widget.onSelectChanged?.call(root);
                },
              )
            : widget.builder(context, root));
    var walked = <GraphNode>[root];
    var visited = <GraphNode>[root];

    while (walked.isNotEmpty) {
      var currentNode = walked.removeAt(0);
      if (currentNode.nextList.isNotEmpty) {
        for (var i = 0; i < currentNode.nextList.length; i++) {
          var node = currentNode.nextList[i];
          if (!visited.contains(node)) {
            node.buildBox(
                childWidget: widget.enabled
                    ? _NodeWidget(
                        child: widget.builder(context, node as GraphNode<T>),
                        node: node,
                        onFocus: () {
                          widget.onSelectChanged?.call(node);
                        },
                      )
                    : widget.builder(context, node as GraphNode<T>));
            walked.add(node);
            visited.add(node);
          }
        }
      }
    }
    return visited;
  }
}

class _NodeWidget extends StatefulWidget {
  const _NodeWidget({
    Key? key,
    required this.child,
    required this.node,
    this.onFocus,
  }) : super(key: key);

  final Widget child;
  final GraphNode node;
  final VoidCallback? onFocus;

  @override
  _NodeWidgetState createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<_NodeWidget> {
  bool _hovered = false;
  bool _currentFocus = false;

  @override
  void initState() {
    _currentFocus = widget.node.focusNode.hasFocus;
    widget.node.focusNode.addListener(() {
      if (_currentFocus != widget.node.focusNode.hasFocus) {
        if (mounted) {
          setState(() {
            _currentFocus = widget.node.focusNode.hasFocus;
          });
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var focusColor = Theme.of(context).colorScheme.secondaryContainer;

    return GestureDetector(
      onTap: () {
        GraphFocus.of(context).requestFocus(widget.node.focusNode);
        widget.onFocus?.call();
      },
      onPanUpdate: (details) {},
      child: MouseRegion(
        onEnter: (event) {
          setState(() {
            _hovered = true;
          });
        },
        onExit: (event) {
          setState(() {
            _hovered = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
                color: (_currentFocus)
                    ? focusColor
                    : _hovered
                        ? focusColor.withAlpha(180)
                        : Colors.transparent,
                width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
