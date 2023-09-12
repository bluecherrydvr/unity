// original file: https://github.com/bdlukaa/fluent_ui/blob/f61c8232d87e33e3b97236da9bd16ceb88a18b09/lib/src/controls/utils/hover_button.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef ButtonStateWidgetBuilder = Widget Function(
  BuildContext,
  Set<ButtonStates> state,
);

/// Base widget for any widget that requires input.
class HoverButton extends StatefulWidget {
  /// Creates a hover button.
  const HoverButton({
    super.key,
    required this.builder,
    this.cursor,
    this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.margin,
    this.semanticLabel,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onLongPressEnd,
    this.onLongPressDown,
    this.onLongPressStart,
    this.onLongPressCancel,
    this.onLongPressUp,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onSecondaryTap,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onFocusChange,
    this.autofocus = false,
    this.actionsEnabled = true,
    this.customActions,
    this.shortcuts,
    this.focusEnabled = true,
    this.forceEnabled = false,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.listenTo = const {
      ButtonStates.pressing,
      ButtonStates.hovering,
      ButtonStates.focused,
      ButtonStates.disabled,
    },
  });

  /// {@template fluent_ui.controls.inputs.HoverButton.mouseCursor}
  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// The [mouseCursor] defaults to [MouseCursor.defer], deferring the choice of
  /// cursor to the next region behind it in hit-test order.
  /// {@endtemplate}
  final MouseCursor? cursor;

  final VoidCallback? onLongPress;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;
  final GestureLongPressDownCallback? onLongPressDown;
  final GestureLongPressCancelCallback? onLongPressCancel;
  final VoidCallback? onLongPressUp;

  final VoidCallback? onPressed;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapCancel;

  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;

  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  final ValueChanged<ScaleStartDetails>? onScaleStart;
  final ValueChanged<ScaleUpdateDetails>? onScaleUpdate;
  final ValueChanged<ScaleEndDetails>? onScaleEnd;

  final VoidCallback? onSecondaryTap;

  final ButtonStateWidgetBuilder builder;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The margin created around this button. The margin is added
  /// around the [Semantics] widget, if any.
  final EdgeInsetsGeometry? margin;

  /// {@template fluent_ui.controls.inputs.HoverButton.semanticLabel}
  /// Semantic label for the input.
  ///
  /// Announced in accessibility modes (e.g TalkBack/VoiceOver).
  /// This label does not show in the UI.
  ///
  ///  * [SemanticsProperties.label], which is set to [semanticLabel] in the
  ///    underlying	 [Semantics] widget.
  ///
  /// If null, no [Semantics] widget is added to the tree
  /// {@endtemplate}
  final String? semanticLabel;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  final ValueChanged<bool>? onFocusChange;

  /// Whether actions are enabled
  ///
  /// Default actions:
  ///  * Execute [onPressed] with Enter and Space
  ///
  /// See also:
  ///
  ///  * [customActions], which lets you execute custom actions
  final bool actionsEnabled;

  /// Custom actions that will be executed around the subtree of this widget.
  ///
  /// See also:
  ///
  ///  * [actionsEnabled], which controls if actions are enabled or not
  final Map<Type, Action<Intent>>? customActions;

  /// {@macro flutter.widgets.shortcuts.shortcuts}
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// Whether the focusing is enabled.
  ///
  /// If `false`, actions and shortcurts will not work, regardless of what is
  /// set on [actionsEnabled].
  final bool focusEnabled;

  /// Whether the hover button should be always enabled.
  ///
  /// If `true`, the button will be considered active even if [onPressed] is not
  /// provided
  final bool forceEnabled;

  /// How this gesture detector should behave during hit testing.
  ///
  /// This defaults to [HitTestBehavior.opaque]
  final HitTestBehavior hitTestBehavior;

  /// The gestures that this widget will listen to.
  final Set<ButtonStates> listenTo;

  static bool get hasMouseConnected {
    return RendererBinding.instance.mouseTracker.mouseIsConnected;
  }

  @override
  State<HoverButton> createState() => HoverButtonState();

  static HoverButtonState of(BuildContext context) {
    return context.findAncestorStateOfType<HoverButtonState>()!;
  }
}

class HoverButtonState extends State<HoverButton> {
  late FocusNode node;

  late Map<Type, Action<Intent>> _actionMap;
  late Map<Type, Action<Intent>> defaultActions;

  @override
  void initState() {
    super.initState();
    node = widget.focusNode ?? _createFocusNode();
    Future<void> handleActionTap() async {
      if (!enabled || !mounted) return;
      setState(() => _pressing = true);
      widget.onPressed?.call();
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _pressing = false);
    }

    defaultActions = {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (ActivateIntent intent) => handleActionTap(),
      ),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
        onInvoke: (ButtonActivateIntent intent) => handleActionTap(),
      ),
    };

    _actionMap = <Type, Action<Intent>>{
      ...defaultActions,
      if (widget.customActions != null) ...widget.customActions!,
    };
  }

  @override
  void didUpdateWidget(HoverButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      node = widget.focusNode ?? node;
    }

    if (widget.customActions != oldWidget.customActions) {
      _actionMap = <Type, Action<Intent>>{
        ...defaultActions,
        if (widget.customActions != null) ...widget.customActions!,
      };
    }
  }

  FocusNode _createFocusNode() {
    return FocusNode(debugLabel: '${widget.runtimeType}');
  }

  @override
  void dispose() {
    if (widget.focusNode == null) node.dispose();
    super.dispose();
  }

  bool _hovering = false;
  bool _pressing = false;
  bool _shouldShowFocus = false;

  bool get enabled =>
      widget.forceEnabled ||
      widget.onPressed != null ||
      widget.onTapUp != null ||
      widget.onTapDown != null ||
      widget.onTapDown != null ||
      widget.onLongPress != null ||
      widget.onLongPressStart != null ||
      widget.onLongPressEnd != null ||
      widget.onLongPressDown != null ||
      widget.onHorizontalDragStart != null ||
      widget.onHorizontalDragUpdate != null ||
      widget.onHorizontalDragEnd != null ||
      widget.onScaleStart != null ||
      widget.onScaleUpdate != null ||
      widget.onScaleEnd != null ||
      widget.onVerticalDragStart != null ||
      widget.onVerticalDragEnd != null ||
      widget.onVerticalDragUpdate != null ||
      widget.onSecondaryTap != null;

  Set<ButtonStates> get states {
    if (!enabled) return {ButtonStates.disabled};

    return {
      if (_pressing) ButtonStates.pressing,
      if (_hovering) ButtonStates.hovering,
      if (_shouldShowFocus) ButtonStates.focused,
    };
  }

  bool listenTo(ButtonStates state) {
    return widget.listenTo.contains(state);
  }

  /// Used in INteractiveViewer to block the first gesture recognition
  bool hasInteractionStarted = false;

  @override
  Widget build(BuildContext context) {
    Widget w = GestureDetector(
      behavior: widget.hitTestBehavior,
      onTap: enabled ? widget.onPressed : null,
      onTapDown: !listenTo(ButtonStates.pressing)
          ? null
          : (_) {
              if (!enabled) return;
              if (mounted) setState(() => _pressing = true);
              widget.onTapDown?.call();
            },
      onTapUp: !listenTo(ButtonStates.pressing)
          ? null
          : (_) async {
              if (!enabled) return;
              widget.onTapUp?.call();
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) setState(() => _pressing = false);
            },
      onTapCancel: !listenTo(ButtonStates.pressing)
          ? null
          : () {
              if (!enabled) return;
              widget.onTapCancel?.call();
              if (mounted) setState(() => _pressing = false);
            },
      onLongPress: enabled ? widget.onLongPress : null,
      onLongPressStart: widget.onLongPressStart != null
          ? (details) {
              if (!enabled) return;
              widget.onLongPressStart?.call(details);
              if (mounted) setState(() => _pressing = true);
            }
          : null,
      onLongPressEnd: widget.onLongPressEnd != null
          ? (details) {
              if (!enabled) return;
              widget.onLongPressEnd?.call(details);
              if (mounted) setState(() => _pressing = false);
            }
          : null,
      onLongPressDown: widget.onLongPressDown,
      onLongPressCancel: widget.onLongPressCancel,
      onLongPressUp: widget.onLongPressUp,
      onHorizontalDragStart: widget.onHorizontalDragStart,
      onHorizontalDragUpdate: widget.onHorizontalDragUpdate,
      onHorizontalDragEnd: widget.onHorizontalDragEnd,
      onVerticalDragStart: widget.onVerticalDragStart,
      onVerticalDragUpdate: widget.onVerticalDragUpdate,
      onVerticalDragEnd: widget.onVerticalDragEnd,
      onSecondaryTap: widget.onSecondaryTap,
      // onScaleStart: widget.onScaleStart,
      // onScaleUpdate: widget.onScaleUpdate,
      // onScaleEnd: widget.onScaleEnd,
      child: Builder(builder: (context) => widget.builder(context, states)),
    );
    if (widget.focusEnabled) {
      w = FocusableActionDetector(
        mouseCursor: widget.cursor ?? MouseCursor.defer,
        focusNode: node,
        autofocus: widget.autofocus,
        enabled: enabled,
        shortcuts: widget.shortcuts,
        actions: widget.actionsEnabled ? _actionMap : {},
        onFocusChange: widget.onFocusChange,
        onShowFocusHighlight: (v) {
          if (mounted) setState(() => _shouldShowFocus = v);
        },
        onShowHoverHighlight: (v) {
          if (mounted) setState(() => _hovering = v);
        },
        child: w,
      );
    } else {
      w = MouseRegion(
        cursor: widget.cursor ?? MouseCursor.defer,
        onEnter: (e) {
          if (mounted) setState(() => _hovering = true);
        },
        onHover: (e) {
          if (mounted && !_hovering) setState(() => _hovering = true);
        },
        onExit: (e) {
          if (mounted) setState(() => _hovering = false);
        },
        child: w,
      );
    }

    w = InteractiveViewer(
      maxScale: 1.0,
      minScale: 1.0,
      onInteractionStart: widget.onScaleStart,
      onInteractionUpdate: widget.onScaleUpdate,
      onInteractionEnd: widget.onScaleEnd,
      child: w,
    );

    w = MergeSemantics(
      child: Semantics(
        label: widget.semanticLabel,
        button: true,
        enabled: enabled,
        focusable: enabled && node.canRequestFocus,
        focused: node.hasFocus,
        child: w,
      ),
    );
    if (widget.margin != null) w = Padding(padding: widget.margin!, child: w);
    return w;
  }
}

enum ButtonStates { disabled, hovering, pressing, focused, none }

// typedef ButtonState<T> = T Function(Set<ButtonStates>);

/// Signature for the function that returns a value of type `T` based on a given
/// set of states.
typedef ButtonStateResolver<T> = T Function(Set<ButtonStates> states);

abstract class ButtonState<T> {
  T resolve(Set<ButtonStates> states);

  static ButtonState<T> all<T>(T value) => _AllButtonState(value);

  static ButtonState<T> resolveWith<T>(ButtonStateResolver<T> callback) {
    return _ButtonState(callback);
  }

  static ButtonState<T?>? lerp<T>(
    ButtonState<T?>? a,
    ButtonState<T?>? b,
    double t,
    T? Function(T?, T?, double) lerpFunction,
  ) {
    if (a == null && b == null) return null;
    return _LerpProperties<T>(a, b, t, lerpFunction);
  }
}

class _ButtonState<T> extends ButtonState<T> {
  _ButtonState(this._resolve);

  final ButtonStateResolver<T> _resolve;

  @override
  T resolve(Set<ButtonStates> states) => _resolve(states);
}

class _AllButtonState<T> extends ButtonState<T> {
  _AllButtonState(this._value);

  final T _value;

  @override
  T resolve(states) => _value;
}

class _LerpProperties<T> implements ButtonState<T?> {
  const _LerpProperties(this.a, this.b, this.t, this.lerpFunction);

  final ButtonState<T?>? a;
  final ButtonState<T?>? b;
  final double t;
  final T? Function(T?, T?, double) lerpFunction;

  @override
  T? resolve(Set<ButtonStates> states) {
    final resolvedA = a?.resolve(states);
    final resolvedB = b?.resolve(states);
    return lerpFunction(resolvedA, resolvedB, t);
  }
}

extension ButtonStatesExtension on Set<ButtonStates> {
  bool get isFocused => contains(ButtonStates.focused);
  bool get isDisabled => contains(ButtonStates.disabled);
  bool get isPressing => contains(ButtonStates.pressing);
  bool get isHovering => contains(ButtonStates.hovering);
  bool get isNone => isEmpty;
}
