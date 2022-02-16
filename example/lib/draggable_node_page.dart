import 'package:flow_graph/flow_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DraggableNodePage extends StatefulWidget {
  const DraggableNodePage({Key? key}) : super(key: key);

  @override
  _DraggableNodePageState createState() => _DraggableNodePageState();
}

class _DraggableNodePageState extends State<DraggableNodePage> {
  late GraphNode<FamilyNode> root;
  Axis _direction = Axis.horizontal;
  bool _centerLayout = false;

  @override
  void initState() {
    root =
        GraphNode<FamilyNode>(data: FamilyNode(name: 'Family'), isRoot: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draggable Flow'),
        actions: [
          Row(
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
              const VerticalDivider(
                width: 32,
              ),
              TextButton(
                  onPressed: () {
                    setState(() {
                      root.removeAllNext();
                    });
                  },
                  child: const Text('重置')),
              const SizedBox(
                width: 32,
              ),
            ],
          )
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 200,
            padding: const EdgeInsets.all(8),
            child: ListView(
              children: [
                Draggable<GraphNodeFactory<FamilyNode>>(
                  data: GraphNodeFactory(
                      dataBuilder: () =>
                          FamilyNode(name: 'Child', singleChild: true)),
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(8),
                    child: _singleOutNode(),
                  ),
                  feedback: Card(
                    color: Theme.of(context).backgroundColor,
                    elevation: 6,
                    child: _singleOutNode(),
                  ),
                ),
                const Divider(
                  height: 16,
                ),
                Draggable<GraphNodeFactory<FamilyNode>>(
                  data: GraphNodeFactory(
                      dataBuilder: () =>
                          FamilyNode(name: 'Child N', singleChild: false)),
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(8),
                    child: _multiOutNode(),
                  ),
                  feedback: Card(
                    color: Theme.of(context).backgroundColor,
                    elevation: 6,
                    child: _multiOutNode(),
                  ),
                ),
                const Divider(
                  height: 16,
                ),
                Draggable<GraphNodeFactory<FamilyNode>>(
                  data: GraphNodeFactory(
                      dataBuilder: () => FamilyNode(
                          name: 'Child X',
                          singleChild: false,
                          multiParent: true)),
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(8),
                    child: _multiParentNode(),
                  ),
                  feedback: Card(
                    color: Theme.of(context).backgroundColor,
                    elevation: 6,
                    child: _multiParentNode(),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(
            width: 32,
          ),
          Expanded(
            child: StatefulBuilder(
              builder: (context, setter) {
                return DraggableFlowGraphView<FamilyNode>(
                  root: root,
                  direction: _direction,
                  centerLayout: _centerLayout,
                  willConnect: (node) {
                    if (node.data?.singleChild == true) {
                      if (node.nextList.length == 1) {
                        return false;
                      } else {
                        return true;
                      }
                    } else if (node.data != null && !node.data!.singleChild) {
                      return true;
                    }
                    return false;
                  },
                  willAccept: (node) {
                    return node.data?.multiParent == true;
                  },
                  builder: (context, node) {
                    return Container(
                      color: Colors.white60,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        (node.data as FamilyNode).name,
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 16),
                      ),
                    );
                  },
                  nodeSecondaryMenuItems: (node) {
                    return [
                      PopupMenuItem(
                        child: Text('Delete'),
                        onTap: () {
                          setter(() {
                            node.deleteSelf();
                          });
                        },
                      )
                    ];
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _singleOutNode() => Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.panorama_wide_angle),
            SizedBox(
              width: 16,
            ),
            Text('1 : 1')
          ],
        ),
      );

  Widget _multiOutNode() => Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.list),
            SizedBox(
              width: 16,
            ),
            Text('1 : n')
          ],
        ),
      );

  Widget _multiParentNode() => Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.menu),
            SizedBox(
              width: 16,
            ),
            Text('n : n')
          ],
        ),
      );
}

class FamilyNode {
  FamilyNode(
      {required this.name, this.singleChild = true, this.multiParent = false});

  String name;
  bool singleChild;
  bool multiParent;
}
