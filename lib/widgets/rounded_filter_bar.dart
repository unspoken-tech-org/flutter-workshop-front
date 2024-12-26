import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_colors.dart';

class RoundedFilterBar extends StatefulWidget {
  final String hintText;
  final TextStyle textStyle;
  final double borderRadius;
  final BoxBorder? border;
  final double? height;
  final Icon trailingIcon;
  final VoidCallback? onClear;
  final VoidCallback? onEnter;
  final VoidCallback? onChange;

  final TextEditingController? controller;

  RoundedFilterBar({
    super.key,
    this.hintText = 'Pesquisar',
    this.textStyle = const TextStyle(color: WsColors.primary),
    this.borderRadius = 26,
    this.height = 46,
    this.trailingIcon = const Icon(Icons.search, color: WsColors.primary),
    this.onClear,
    this.onEnter,
    this.onChange,
    this.controller,
    BoxBorder? border,
  }) : border = border ?? Border.all(color: WsColors.primary, width: 2);

  @override
  State<RoundedFilterBar> createState() => _RoundedFilterBarState();
}

class _RoundedFilterBarState extends State<RoundedFilterBar> {
  late TextEditingController _controller;

  bool showClearButton = false;

  bool get hasText => _controller.text.isNotEmpty;

  void _showButton() {
    setState(() {
      showClearButton = hasText;
    });
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  void initState() {
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_showButton);
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(_showButton);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                hintText: widget.hintText,
                hintStyle: widget.textStyle,
              ),
              style: widget.textStyle,
              onSubmitted: (_) {
                widget.onEnter?.call();
              },
              onChanged: (_) {
                widget.onChange?.call();
              },
            ),
          ),
          if (showClearButton)
            IconButton(
              onPressed: _clear,
              icon: const Icon(Icons.close, color: WsColors.danger),
            )
          else
            widget.trailingIcon
        ],
      ),
    );
  }
}
