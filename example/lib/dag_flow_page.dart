import 'package:flow_graph/flow_graph.dart';
import 'package:flutter/material.dart';

class DagFlowPage extends StatefulWidget {
  const DagFlowPage({Key? key}) : super(key: key);

  @override
  _DagFlowPageState createState() => _DagFlowPageState();
}

class _DagFlowPageState extends State<DagFlowPage> {
  late GraphNode root;

  @override
  void initState() {
    root = GraphNode(data: 'Root', isRoot: true);
    var lilith = GraphNode(data: 'Lilith');
    var lilithSunny = GraphNode(data: 'Lilith.sunny');
    lilith.addNext(lilithSunny);
    var lilithAda = GraphNode(data: 'Lilith.ada');
    lilith.addNext(lilithAda);
    lilith.addNext(GraphNode(data: 'Lilith.john'));

    var alice = GraphNode(data: 'Alice');
    alice.addNext(lilithSunny);
    alice.addNext(lilithAda);
    alice.addNext(GraphNode(data: 'Alice.bob'));

    var eva = GraphNode(data: 'Eva');
    eva.addNext(GraphNode(data: 'Eva.atom'));
    var evaWang = GraphNode(data: 'Eva.wang');
    eva.addNext(evaWang);

    alice.addNext(evaWang);

    root.addNext(lilith);
    root.addNext(alice);
    root.addNext(eva);
    root.addNext(GraphNode(data: 'Earth'));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BluePrints'),
      ),
      body: FlowGraphView(
        root: root,
        builder: (context, node) {
          if (node.data == 'Eva') {
            return Container(
              color: Colors.white60,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    node.data.toString(),
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    '这是妞妞',
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  )
                ],
              ),
            );
          }
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
