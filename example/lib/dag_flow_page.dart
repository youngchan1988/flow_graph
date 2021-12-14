import 'package:flow_graph/flow_graph.dart';
import 'package:flutter/material.dart';

class DagFlowPage extends StatefulWidget {
  const DagFlowPage({Key? key}) : super(key: key);

  @override
  _DagFlowPageState createState() => _DagFlowPageState();
}

class _DagFlowPageState extends State<DagFlowPage> {
  late GraphNode root;
  Axis _direction = Axis.horizontal;
  bool _centerLayout = false;

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
        title: const Text('Flow'),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<Axis>(
                value: Axis.horizontal,
                groupValue: _direction,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _direction = value;
                    });
                  }
                },
              ),
              const SizedBox(
                width: 8,
              ),
              const Text('横向'),
              const SizedBox(
                width: 16,
              ),
              Radio<Axis>(
                value: Axis.vertical,
                groupValue: _direction,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _direction = value;
                    });
                  }
                },
              ),
              const SizedBox(
                width: 8,
              ),
              const Text('纵向'),
              const VerticalDivider(
                width: 32,
              ),
              Switch(
                  value: _centerLayout,
                  onChanged: (b) {
                    setState(() {
                      _centerLayout = b;
                    });
                  }),
              const SizedBox(
                width: 8,
              ),
              const Text('中间布局'),
              const SizedBox(
                width: 32,
              ),
            ],
          )
        ],
      ),
      body: FlowGraphView(
        root: root,
        direction: _direction,
        centerLayout: _centerLayout,
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
