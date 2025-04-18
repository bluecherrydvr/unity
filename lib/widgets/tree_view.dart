// ORIGINAL PACKAGE: https://pub.dev/packages/flutter_simple_treeview

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart'
    show TreeNode, TreeController;

export 'package:flutter_simple_treeview/flutter_simple_treeview.dart'
    show TreeNode, TreeController;

Widget buildCheckbox({
  required bool? value,
  required ValueChanged<bool?> onChanged,
  required bool isError,
  required String text,
  required double gapCheckboxText,
  IconData offlineIcon = Icons.videocam_off_outlined,
  String? secondaryText,
  double checkboxScale = 0.8,
  FlexFit textFit = FlexFit.loose,
}) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final loc = AppLocalizations.of(context);
      final checkbox = SizedBox.fromSize(
        size: const Size(24.0, 24.0),
        child:
            isError
                ? Tooltip(
                  message: loc.offline,
                  child: Icon(
                    offlineIcon,
                    size: 16.0,
                    color: theme.colorScheme.error,
                  ),
                )
                : Transform.scale(
                  scale: checkboxScale,
                  child: Checkbox.adaptive(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    splashRadius: 0.0,
                    tristate: true,
                    value: value,
                    isError: isError,
                    onChanged: onChanged,
                    side:
                        isError
                            ? BorderSide(color: theme.colorScheme.error)
                            : null,
                  ),
                ),
      );

      return SizedBox(
        height: isError ? 18.0 : 24.0,
        child: Row(
          children: [
            checkbox,
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    onChanged(value == null ? true : !value);
                  },
                  child: Row(
                    children: [
                      SizedBox(width: gapCheckboxText),
                      Flexible(
                        fit: textFit,
                        child: Text(
                          text,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: isError ? theme.colorScheme.error : null,
                            // decoration: isError ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (secondaryText != null)
                        Text(secondaryText, style: theme.textTheme.labelSmall),
                      const SizedBox(width: 10.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Tree view with collapsible and expandable nodes.
class TreeView extends StatefulWidget {
  /// List of root level tree nodes.
  final List<TreeNode> nodes;

  /// Horizontal indent between levels.
  final double? indent;

  /// Size of the expand/collapse icon.
  final double? iconSize;

  /// Tree controller to manage the tree state.
  final TreeController? treeController;

  TreeView({
    super.key,
    required List<TreeNode> nodes,
    this.indent = 40,
    this.iconSize,
    this.treeController,
  }) : nodes = copyTreeNodes(nodes);

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  TreeController? _controller;

  @override
  void initState() {
    _controller = widget.treeController ?? TreeController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildNodes(
      widget.nodes,
      widget.indent,
      _controller!,
      widget.iconSize,
    );
  }
}

/// Builds set of [nodes] respecting [state], [indent] and [iconSize].
Widget buildNodes(
  Iterable<TreeNode> nodes,
  double? indent,
  TreeController state,
  double? iconSize,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var node in nodes)
        NodeWidget(
          treeNode: node,
          indent: indent,
          state: state,
          iconSize: iconSize,
        ),
    ],
  );
}

/// Copies nodes to unmodifiable list, assigning missing keys and checking for duplicates.
List<TreeNode> copyTreeNodes(List<TreeNode>? nodes) {
  return _copyNodesRecursively(nodes, KeyProvider())!;
}

List<TreeNode>? _copyNodesRecursively(
  List<TreeNode>? nodes,
  KeyProvider keyProvider,
) {
  if (nodes == null) {
    return null;
  }
  return List.unmodifiable(
    nodes.map((node) {
      return TreeNode(
        key: keyProvider.key(node.key),
        content: node.content,
        children: _copyNodesRecursively(node.children, keyProvider),
      );
    }),
  );
}

class _TreeNodeKey extends ValueKey {
  const _TreeNodeKey(super.value);
}

/// Provides unique keys and verifies duplicates.
class KeyProvider {
  int _nextIndex = 0;
  final Set<Key> _keys = <Key>{};

  /// If [originalKey] is null, generates new key, otherwise verifies the key
  /// was not met before.
  Key key(Key? originalKey) {
    if (originalKey == null) {
      return _TreeNodeKey(_nextIndex++);
    }
    // if (_keys.contains(originalKey)) {
    //   throw ArgumentError('There should not be nodes with the same keys. '
    //       'Duplicate value found: $originalKey.');
    // }
    _keys.add(originalKey);
    return originalKey;
  }
}

/// Widget that displays one [TreeNode] and its children.
class NodeWidget extends StatefulWidget {
  final TreeNode treeNode;
  final double? indent;
  final double? iconSize;
  final TreeController state;

  const NodeWidget({
    super.key,
    required this.treeNode,
    this.indent,
    required this.state,
    this.iconSize,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  bool get _isLeaf {
    return widget.treeNode.children == null;
  }

  bool get _isEnabled {
    return widget.treeNode.children?.isNotEmpty ?? false;
  }

  bool get _isExpanded {
    return widget.state.isNodeExpanded(widget.treeNode.key!);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    var icon =
        _isLeaf
            ? null
            : _isExpanded
            ? Icons.expand_more
            : Icons.chevron_right;

    var onIconPressed =
        _isLeaf || !_isEnabled
            ? null
            : () {
              if (mounted) {
                setState(
                  () => widget.state.toggleNodeExpanded(widget.treeNode.key!),
                );
              }
            };

    return IgnorePointer(
      ignoring: _isLeaf ? false : !_isEnabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!_isLeaf && _isEnabled)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 8.0,
                    end: 4.0,
                  ),
                  child: Tooltip(
                    message: _isExpanded ? loc.collapse : loc.expand,
                    child: InkWell(
                      onTap: onIconPressed,
                      borderRadius: BorderRadius.circular(6.0),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(4.5),
                        child: Icon(icon, size: widget.iconSize),
                      ),
                    ),
                  ),
                )
              // If it is not leaf nor enabled, mimic the space of the icon button
              else if (!_isLeaf && !_isEnabled)
                const SizedBox(width: 39.0),
              Expanded(child: widget.treeNode.content),
            ],
          ),
          if (_isExpanded && !_isLeaf)
            Padding(
              padding: EdgeInsetsDirectional.only(start: widget.indent!),
              child: buildNodes(
                widget.treeNode.children!,
                widget.indent,
                widget.state,
                widget.iconSize,
              ),
            ),
        ],
      ),
    );
  }
}
