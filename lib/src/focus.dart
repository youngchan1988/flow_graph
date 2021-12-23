import 'package:flutter/cupertino.dart';

class GraphFocusNode with ChangeNotifier {
  GraphFocusNode();

  bool _focus = false;

  bool get hasFocus => _focus;

  void requestFocus() {
    _focus = true;
    notifyListeners();
  }

  void unFocus() {
    _focus = false;
    notifyListeners();
  }
}

class GraphFocusManager {
  final _focusNodes = <GraphFocusNode>[];

  void requestFocus(GraphFocusNode node) {
    for (var n in _focusNodes) {
      if (n != node) {
        n.unFocus();
      }
    }
    if (!_focusNodes.contains(node)) {
      _focusNodes.add(node);
    }
    node.requestFocus();
  }

  void clearFocus() {
    for (var n in _focusNodes) {
      n.unFocus();
    }
  }

  void dispose() {
    _focusNodes.clear();
  }
}

class GraphFocus extends InheritedWidget {
  const GraphFocus({Key? key, required this.manager, required Widget child})
      : super(key: key, child: child);

  final GraphFocusManager manager;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;

  static GraphFocusManager of(BuildContext context) =>
      context.findAncestorWidgetOfExactType<GraphFocus>()!.manager;
}
