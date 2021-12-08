import 'package:flow_graph/src/render/board_render.dart';
import 'package:flutter/material.dart';

import 'graph.dart';

class DragDropFlowGraphView extends StatefulWidget {
  const DragDropFlowGraphView({
    Key? key,
    required this.root,
    this.direction = Axis.horizontal,
    required this.builder,
  }) : super(key: key);

  final GraphNode root;
  final Axis direction;
  final NodeWidgetBuilder builder;

  @override
  _DragDropFlowGraphViewState createState() => _DragDropFlowGraphViewState();
}

class _DragDropFlowGraphViewState extends State<DragDropFlowGraphView> {
  late Graph _graph;
  final GlobalKey _dragTargetKey = GlobalKey();

  RelativeRect? _currentPreviewNodePosition;
  GraphNode? _currentPreviewEdgeNode;

  // @override
  // void initState() {
  //   widget.root.initialElement(child: widget.builder(context, widget.root));
  //   _graph = Graph(nodes: [widget.root]);
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    _graph = Graph(nodes: _linearNodes(context, widget.root));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: ListView(
              children: [
                Draggable<GraphNodeFactory>(
                  data: GraphNodeFactory(dataBuilder: () => 'Nobody'),
                  child: ListTile(
                    leading: Icon(Icons.panorama_wide_angle),
                    title: Text('Name'),
                  ),
                  feedback: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.panorama_wide_angle),
                          const SizedBox(
                            width: 16,
                          ),
                          Text('Name')
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              child: DragTarget<GraphNodeFactory>(
                key: _dragTargetKey,
                builder: (context, candidate, reject) {
                  return GraphBoard(graph: _graph);
                },
                onWillAccept: (factory) => factory != null,
                onAccept: (factory) {
                  _acceptNode(factory.createNode());
                },
                onMove: (details) {
                  var target = _dragTargetKey.currentContext!.findRenderObject()
                      as RenderBox;
                  var localOffset = target.globalToLocal(details.offset);
                  _previewConnectEdge(localOffset);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _acceptNode(GraphNode node) {
    node.initialElement(child: widget.builder(context, node));
    if (_currentPreviewEdgeNode != null) {
      _currentPreviewEdgeNode!.addNext(node);
      _removePreviewEdge();
    }
  }

  void _addPreviewEdge(GraphNode node) {
    node.addNext(PreviewGraphNode());
    _graph.layout();
    setState(() {
      _currentPreviewNodePosition = node.element.position;
      _currentPreviewEdgeNode = node;
    });
  }

  void _removePreviewEdge() {
    if (_currentPreviewEdgeNode == null) {
      return;
    }
    for (var n in _currentPreviewEdgeNode!.nextList) {
      if (n is PreviewGraphNode) {
        _currentPreviewEdgeNode!.nextList.remove(n);

        break;
      }
    }
    _graph.layout();
    setState(() {
      _currentPreviewEdgeNode = null;
      _currentPreviewNodePosition = null;
    });
  }

  void _previewConnectEdge(Offset offset) {
    if (_currentPreviewNodePosition == null ||
        !_canConnectToPosition(_currentPreviewNodePosition!, offset)) {
      if (_currentPreviewEdgeNode != null) {
        _removePreviewEdge();
      }
      for (var n in _graph.nodes) {
        if (_canConnectToPosition(n.element.position, offset)) {
          _addPreviewEdge(n);
          break;
        }
      }
    }
  }

  bool _canConnectToPosition(RelativeRect position, Offset offset) {
    if (_graph.direction == Axis.horizontal) {
      return offset.dx >= position.left &&
          offset.dx <= position.right + kMainAxisSpace &&
          offset.dy >= position.top &&
          offset.dy <= position.bottom + kCrossAxisSpace;
    } else if (_graph.direction == Axis.vertical) {
      return offset.dx >= position.left &&
          offset.dx <= position.right + kCrossAxisSpace &&
          offset.dy >= position.top &&
          offset.dy <= position.bottom + kMainAxisSpace;
    }
    return false;
  }

  //bfs
  List<GraphNode> _linearNodes(BuildContext context, GraphNode root) {
    root.initialElement(child: widget.builder(context, root));
    var walked = <GraphNode>[root];
    var visited = <GraphNode>[root];

    while (walked.isNotEmpty) {
      var currentNode = walked.removeAt(0);
      if (currentNode.nextList.isNotEmpty) {
        for (var i = 0; i < currentNode.nextList.length; i++) {
          var node = currentNode.nextList[i];
          if (!visited.contains(node)) {
            if (node is! PreviewGraphNode) {
              node.initialElement(child: widget.builder(context, node));
            }
            walked.add(node);
            visited.add(node);
          }
        }
      }
    }
    return visited;
  }
}
