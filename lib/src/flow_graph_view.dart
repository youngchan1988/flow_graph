import 'package:flutter/material.dart';

import 'graph.dart';
import 'render/board_render.dart';

typedef NodeWidgetBuilder = Widget Function(
    BuildContext context, GraphNode node);

class FlowGraphView extends StatelessWidget {
  const FlowGraphView(
      {Key? key,
      required this.root,
      this.direction = Axis.horizontal,
      required this.builder})
      : super(key: key);

  final GraphNode root;
  final Axis direction;
  final NodeWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    var graph = Graph(nodes: _linearNodes(context, root), direction: direction);

    return Padding(
        padding: EdgeInsets.all(16), child: GraphBoard(graph: graph));
  }

  //bfs
  List<GraphNode> _linearNodes(BuildContext context, GraphNode root) {
    root.initialElement(child: builder(context, root));
    var walked = <GraphNode>[root];
    var visited = <GraphNode>[root];

    while (walked.isNotEmpty) {
      var currentNode = walked.removeAt(0);
      if (currentNode.nextList.isNotEmpty) {
        for (var i = 0; i < currentNode.nextList.length; i++) {
          var node = currentNode.nextList[i];
          if (!visited.contains(node)) {
            node.initialElement(child: builder(context, node));
            walked.add(node);
            visited.add(node);
          }
        }
      }
    }
    return visited;
  }
}
