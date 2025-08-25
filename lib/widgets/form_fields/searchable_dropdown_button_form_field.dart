import 'dart:async';

import 'package:flutter/material.dart';

class SearchableDropdownButtonFormField extends StatefulWidget {
  final String? headerLabel;
  final String? fieldLabel;
  final String? hintText;
  final bool isLoading;
  final List<String> items;
  final String? value;
  final void Function(String? value)? onTextChanged;
  final void Function(String? value)? onItemSelected;
  final VoidCallback? onClear;
  final bool enabled;
  final double offset;
  final bool showAllItems;

  const SearchableDropdownButtonFormField({
    super.key,
    this.headerLabel,
    this.fieldLabel,
    this.hintText,
    this.isLoading = false,
    required this.items,
    this.value,
    this.onTextChanged,
    this.onItemSelected,
    this.onClear,
    this.enabled = true,
    this.offset = 0,
    this.showAllItems = false,
  });

  @override
  State<SearchableDropdownButtonFormField> createState() =>
      _SearchableDropdownButtonFormFieldState();
}

class _SearchableDropdownButtonFormFieldState
    extends State<SearchableDropdownButtonFormField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  Timer? _onExitOverlayTimer;
  List<String> _filteredItems = [];
  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _controller.text = widget.value!;
    }

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant SearchableDropdownButtonFormField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items != oldWidget.items) {
      _filterItems(_controller.text);
    }

    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _hideOverlay();
    _onExitOverlayTimer?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _hideOverlay();
    }
  }

  void _onTextChanged() {
    widget.onTextChanged?.call(_controller.text);
    if (_controller.text.isEmpty) {
      if (_overlayEntry != null) _hideOverlay();
    } else {
      _filterItems(_controller.text);
      if (_overlayEntry == null) _showOverlay();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _showOverlay() {
    _onExitOverlayTimer?.cancel();

    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _hideOverlay() {
    _onExitOverlayTimer?.cancel();
    _onExitOverlayTimer = Timer(const Duration(milliseconds: 100), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _filterItems(String query) {
    if (!mounted) return;

    if (query.isEmpty || widget.showAllItems) {
      _filteredItems = widget.items;
    } else {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _onItemSelected(String item) {
    _controller.text = '';
    widget.onItemSelected?.call(item);
    _focusNode.unfocus();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height - widget.offset),
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: widget.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _filteredItems.isNotEmpty
                        ? ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return ListTile(
                                title: Text(
                                  item,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () => _onItemSelected(item),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.headerLabel != null) ...[
          Text(
            widget.headerLabel!,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            onTapOutside: (_) => _focusNode.unfocus(),
            decoration: InputDecoration(
              labelText: widget.fieldLabel,
              hintText: widget.hintText,
              hintStyle:
                  const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
