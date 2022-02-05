// Copyright (c) 2022, the flow_graph project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flow_graph/src/graph_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'focus.dart';
import 'graph.dart';
import 'render/preview_connect_render.dart';

class DraggableFlowGraphView<T> extends StatefulWidget {
  const DraggableFlowGraphView({
    Key? key,
    required this.root,
    this.enableDelete = true,
    this.direction = Axis.horizontal,
    this.centerLayout = false,
    this.padding = const EdgeInsets.all(16),
    required this.builder,
    this.willConnect,
    this.willAccept,
    this.onConnect,
    this.onAccept,
    this.onDeleted,
    this.onSelectChanged,
  }) : super(key: key);

  final GraphNode<T> root;
  final Axis direction;
  final bool enableDelete;
  final bool centerLayout;
  final EdgeInsets padding;
  final NodeWidgetBuilder<T> builder;

  ///Will add a connection to next node
  final WillConnect<T>? willConnect;

  ///Will accept prev node connection;
  final WillAccept<T>? willAccept;

  ///Connect to next node
  final OnConnect<T>? onConnect;

  ///Accept prev node connection;
  final OnAccept<T>? onAccept;

  final OnDeleted<T>? onDeleted;

  final OnSelectChanged<T>? onSelectChanged;

  @override
  _DraggableFlowGraphViewState<T> createState() =>
      _DraggableFlowGraphViewState<T>();
}

class _DraggableFlowGraphViewState<T> extends State<DraggableFlowGraphView<T>> {
  late Graph _graph;
  final GlobalKey _graphViewKey = GlobalKey();
  RenderBox? _targetRender;
  final _keyboardFocus = FocusNode();

  RelativeRect? _currentPreviewNodePosition;
  GraphNode<T>? _currentPreviewEdgeNode;
  Offset _previewConnectStart = Offset.zero;
  Offset _previewConnectEnd = Offset.zero;

  final _previewConnectRender = PreviewConnectRender();
  final _controller = GraphViewController();

  final GraphFocusManager _focusManager = GraphFocusManager();

  @override
  void dispose() {
    _focusManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _keyboardFocus.requestFocus();
    return Padding(
      padding: widget.padding,
      child: KeyboardListener(
        focusNode: _keyboardFocus,
        onKeyEvent: (keyEvent) {
          if (keyEvent is KeyDownEvent) {
            if (widget.enableDelete &&
                    keyEvent.logicalKey == LogicalKeyboardKey.backspace ||
                keyEvent.logicalKey == LogicalKeyboardKey.delete) {
              for (var n in _graph.nodes) {
                if (n.focusNode.hasFocus && !n.isRoot) {
                  setState(() {
                    n.deleteSelf();
                  });
                  widget.onDeleted?.call(n as GraphNode<T>);
                  break;
                }
              }
              for (var e in _graph.edges) {
                if (e.selected) {
                  setState(() {
                    e.deleteSelf();
                  });
                }
              }
            }
            _focusManager.clearFocus();
          }
        },
        child: GraphFocus(
          manager: _focusManager,
          child: Builder(
            builder: (context) {
              _graph = Graph(
                  nodes: _linearNodes(context, widget.root),
                  direction: widget.direction,
                  centerLayout: widget.centerLayout);
              return GestureDetector(
                onTap: () {
                  GraphFocus.of(context).clearFocus();
                  widget.onSelectChanged?.call(null);
                },
                child: DragTarget<GraphNodeFactory<T>>(
                  builder: (context, candidate, reject) {
                    return GraphView(
                      key: _graphViewKey,
                      controller: _controller,
                      graph: _graph,
                      onPaint: (canvas) {
                        if (_previewConnectStart.distance > 0 &&
                            _previewConnectEnd.distance > 0) {
                          _previewConnectRender.render(
                              context: context,
                              canvas: canvas,
                              start: Offset(_previewConnectStart.dx,
                                  _previewConnectStart.dy),
                              end: Offset(
                                  _previewConnectEnd.dx, _previewConnectEnd.dy),
                              direction: _graph.direction);
                        }
                      },
                    );
                  },
                  onWillAccept: (factory) => factory != null,
                  onAccept: (factory) {
                    _acceptNode(context, factory.createNode());
                  },
                  onLeave: (factory) {
                    _removePreviewEdge();
                  },
                  onMove: (details) {
                    var target = _graphViewKey.currentContext!
                        .findRenderObject() as RenderBox;
                    var localOffset = target.globalToLocal(details.offset);
                    _previewConnectEdge(context, localOffset);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _acceptNode(BuildContext context, GraphNode<T> node) {
    if (_currentPreviewEdgeNode != null) {
      _currentPreviewEdgeNode!.addNext(node);
      widget.onConnect?.call(_currentPreviewEdgeNode!, node);
      _removePreviewEdge();
    }
  }

  void _addPreviewEdge(BuildContext context, GraphNode<T> node) {
    node.addNext(
        PreviewGraphNode(color: Theme.of(context).colorScheme.secondary));
    setState(() {
      _currentPreviewNodePosition = node.box.position;
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
    setState(() {
      _currentPreviewEdgeNode = null;
      _currentPreviewNodePosition = null;
    });
  }

  void _previewConnectEdge(BuildContext context, Offset offset) {
    if (_currentPreviewNodePosition == null ||
        !_canConnectToPosition(_currentPreviewNodePosition!, offset)) {
      if (_currentPreviewEdgeNode != null) {
        _removePreviewEdge();
      }
      for (var n in _graph.nodes) {
        if (n is! PreviewGraphNode &&
            _canConnectToPosition(n.box.position, offset) &&
            (widget.willConnect == null ||
                widget.willConnect!(n as GraphNode<T>))) {
          _addPreviewEdge(context, n as GraphNode<T>);
          break;
        }
      }
    }
  }

  bool _canConnectToPosition(RelativeRect nodePosition, Offset point) {
    if (_graph.direction == Axis.horizontal) {
      return nodePosition
          .offset(_controller.position)
          .spreadSize(Size(kMainAxisSpace, kCrossAxisSpace))
          .contains(point);
    } else if (_graph.direction == Axis.vertical) {
      return nodePosition
          .offset(_controller.position)
          .spreadSize(Size(kCrossAxisSpace, kMainAxisSpace))
          .contains(point);
    }
    return false;
  }

  //bfs
  List<GraphNode> _linearNodes(BuildContext context, GraphNode<T> root) {
    _initialNodeElement(context, root);
    var walked = <GraphNode>[root];
    var visited = <GraphNode>[root];

    while (walked.isNotEmpty) {
      var currentNode = walked.removeAt(0);
      if (currentNode.nextList.isNotEmpty) {
        for (var i = 0; i < currentNode.nextList.length; i++) {
          var node = currentNode.nextList[i];
          if (!visited.contains(node)) {
            if (node is! PreviewGraphNode) {
              _initialNodeElement(context, node as GraphNode<T>);
            }
            walked.add(node);
            visited.add(node);
          }
        }
      }
    }
    return visited;
  }

  void _initialNodeElement(BuildContext context, GraphNode<T> node) {
    node.buildBox(
      overflowPadding: const EdgeInsets.all(14),
      childWidget: _NodeWidget(
        node: node,
        graphDirection: widget.direction,
        enableDelete: widget.enableDelete,
        child: widget.builder(context, node),
        onDelete: () {
          setState(() {
            node.deleteSelf();
          });
          widget.onDeleted?.call(node);
        },
        onFocus: () {
          widget.onSelectChanged?.call(node);
        },
        onPreviewConnectStart: (position) {
          _targetRender ??=
              _graphViewKey.currentContext!.findRenderObject() as RenderBox;
          _previewConnectStart = _targetRender!.globalToLocal(position);
        },
        onPreviewConnectMove: (position) {
          _targetRender ??=
              _graphViewKey.currentContext!.findRenderObject() as RenderBox;
          setState(() {
            _previewConnectEnd = _targetRender!.globalToLocal(position);
          });
        },
        onPreviewConnectStop: (position) {
          _targetRender ??=
              _graphViewKey.currentContext!.findRenderObject() as RenderBox;
          var localPosition = _targetRender!.globalToLocal(position);
          //concern board offset
          var targetNode =
              _graph.nodeOf<T>(localPosition - _controller.position);
          if (targetNode != null &&
              widget.willAccept?.call(targetNode) == true &&
              widget.willConnect?.call(node) == true) {
            //connect to node
            node.addNext(targetNode);
            widget.onAccept?.call(node, targetNode);
          }
          setState(() {
            _previewConnectStart = Offset.zero;
            _previewConnectEnd = Offset.zero;
          });
        },
      ),
    );
  }
}

class _NodeWidget extends StatefulWidget {
  const _NodeWidget({
    Key? key,
    required this.child,
    this.enableDelete = true,
    required this.node,
    required this.graphDirection,
    this.onDelete,
    this.onFocus,
    this.onPreviewConnectStart,
    this.onPreviewConnectMove,
    this.onPreviewConnectStop,
  }) : super(key: key);

  final Widget child;
  final bool enableDelete;
  final GraphNode node;
  final Axis graphDirection;
  final VoidCallback? onDelete;
  final VoidCallback? onFocus;
  final void Function(Offset)? onPreviewConnectStart;
  final void Function(Offset)? onPreviewConnectMove;
  final void Function(Offset)? onPreviewConnectStop;

  @override
  _NodeWidgetState createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<_NodeWidget> {
  bool _hovered = false;
  bool _currentFocus = false;
  bool _previewConnecting = false;

  @override
  void initState() {
    _currentFocus = widget.node.focusNode.hasFocus;
    widget.node.focusNode.addListener(() {
      if (_currentFocus != widget.node.focusNode.hasFocus) {
        if (mounted) {
          setState(() {
            _currentFocus = widget.node.focusNode.hasFocus;
          });
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var focusColor = Theme.of(context).colorScheme.secondaryVariant;
    var renderBox = context.findRenderObject() as RenderBox?;
    var boxSize = Size.zero;
    if (renderBox != null) {
      boxSize = renderBox.size;
    }
    return GestureDetector(
      onTap: () {
        GraphFocus.of(context).requestFocus(widget.node.focusNode);
        widget.onFocus?.call();
      },
      onPanUpdate: (details) {},
      onSecondaryTapUp: (details) {
        if (widget.enableDelete && !widget.node.isRoot) {
          showMenu(
              context: context,
              elevation: 6,
              position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                details.globalPosition.dx,
                details.globalPosition.dy,
              ),
              items: [
                PopupMenuItem(
                  child: const Text('删除'),
                  value: 'delete',
                  onTap: () {
                    widget.onDelete?.call();
                  },
                )
              ]);
        }
      },
      child: MouseRegion(
        onEnter: (event) {
          setState(() {
            _hovered = true;
          });
        },
        onExit: (event) {
          setState(() {
            _hovered = false;
          });
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                    color: (_currentFocus || _previewConnecting)
                        ? focusColor
                        : _hovered
                            ? focusColor.withAlpha(180)
                            : Colors.transparent,
                    width: 2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: widget.child,
            ),
            if (_hovered || _currentFocus || _previewConnecting)
              widget.graphDirection == Axis.horizontal
                  ? Positioned(
                      top: (boxSize.height - 20) / 2,
                      right: 0,
                      child: Listener(
                        onPointerDown: (event) {
                          var center = Offset(
                              event.position.dx - event.localPosition.dx + 10,
                              event.position.dy - event.localPosition.dy + 10);
                          widget.onPreviewConnectStart?.call(center);
                          _previewConnecting = true;
                        },
                        onPointerMove: (event) {
                          widget.onPreviewConnectMove?.call(event.position);
                        },
                        onPointerUp: (event) {
                          widget.onPreviewConnectStop?.call(event.position);
                          _previewConnecting = false;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.secondaryVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                          ),
                        ),
                      ),
                    )
                  : Positioned(
                      left: (boxSize.width - 20) / 2,
                      bottom: 0,
                      child: Listener(
                        onPointerDown: (event) {
                          var center = Offset(
                              event.position.dx - event.localPosition.dx + 10,
                              event.position.dy - event.localPosition.dy + 10);
                          widget.onPreviewConnectStart?.call(center);
                          _previewConnecting = true;
                        },
                        onPointerMove: (event) {
                          widget.onPreviewConnectMove?.call(event.position);
                        },
                        onPointerUp: (event) {
                          widget.onPreviewConnectStop?.call(event.position);
                          _previewConnecting = false;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.secondaryVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            size: 12,
                          ),
                        ),
                      ),
                    )
          ],
        ),
      ),
    );
  }
}
