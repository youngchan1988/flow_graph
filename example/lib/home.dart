import 'package:example/dragdrop_node_page.dart';
import 'package:flutter/material.dart';

import 'dag_flow_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowGraph'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
          children: [
            Card(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => DagFlowPage()));
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.cable,
                      size: 48,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text('DAG-Flow'),
                  ],
                ),
              ),
            ),
            Card(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => DragDropNodePage()));
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.widgets,
                      size: 48,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text('Draggable-Flow'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
