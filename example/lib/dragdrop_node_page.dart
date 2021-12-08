import 'package:flow_graph/flow_graph.dart';
import 'package:flutter/material.dart';

class DragDropNodePage extends StatefulWidget {
  const DragDropNodePage({Key? key}) : super(key: key);

  @override
  _DragDropNodePageState createState() => _DragDropNodePageState();
}

class _DragDropNodePageState extends State<DragDropNodePage> {
  late GraphNode root;

  @override
  void initState() {
    root = GraphNode(data: 'Family', isRoot: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: DragDropFlowGraphView(
        root: root,
        builder: (context, node) {
          return Container(
            color: Colors.white60,
            padding: const EdgeInsets.all(16),
            child: Text(
              node.data.toString(),
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
