![](https://tva1.sinaimg.cn/large/008i3skNgy1gz2lx8ljszj30qs0atdfy.jpg)

## Features
- Support draggable node;
- Support delete node & edge;
- Support horizontal & vertical layout;

## Getting started
```yaml
dependencies:
    flow_graph: ^0.0.7
```
## Screen shot
![](https://tva1.sinaimg.cn/large/008i3skNgy1gz2tlptkq9j31050u0ta0.jpg)

![](https://tva1.sinaimg.cn/large/008i3skNgy1gz2tpst6n1g30qo0f0wmy.gif)

## Usage
Flow graph:
```dart
FlowGraphView(
	root: root,
	direction: _direction,
	centerLayout: _centerLayout,
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
)
```

Draggable flow graph:
```dart
DraggableFlowGraphView<FamilyNode>(
	root: root,
	direction: _direction,
	centerLayout: _centerLayout,
	willConnect: (node) => true,
	willAccept: (node) => true,
	builder: (context, node) {
	return Container(
		color: Colors.white60,
		padding: const EdgeInsets.all(16),
		child: Text(
			(node.data as FamilyNode).name,
			style: const TextStyle(color: Colors.black87, fontSize: 16),
			),
		);
	},
)
```

# License

See [LICENSE](LICENSE)