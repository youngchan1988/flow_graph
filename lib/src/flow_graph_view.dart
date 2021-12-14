import 'package:flutter/material.dart';

import 'graph.dart';
import 'graph_view.dart';

class FlowGraphView extends StatelessWidget {
  const FlowGraphView(
      {Key? key,
      required this.root,
      this.direction = Axis.horizontal,
      this.centerLayout = false,
      required this.builder})
      : super(key: key);

  final GraphNode root;
  final Axis direction;
  final bool centerLayout;
  final NodeWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    var graph = Graph(
        nodes: _linearNodes(context, root),
        direction: direction,
        centerLayout: centerLayout);

    return Padding(
        padding: const EdgeInsets.all(16), child: GraphView(graph: graph));
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
