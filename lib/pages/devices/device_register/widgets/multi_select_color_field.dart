import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_workshop_front/core/debouncer.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';

class MultiSelectColorField extends StatefulWidget {
  final String? headerLabelText;
  final String? hintText;
  final List<ColorModel> suggestions;
  final int maxSelections;
  final List<ColorModel> selectedColors;
  final Future<ColorModel> Function(String name) onCreateColor;
  final void Function(ColorModel color) onColorAdded;
  final void Function(ColorModel color) onColorRemoved;
  final String? Function(List<ColorModel> selectedColors)? fieldValidator;

  const MultiSelectColorField({
    super.key,
    this.headerLabelText,
    this.hintText,
    required this.suggestions,
    this.maxSelections = 4,
    required this.selectedColors,
    required this.onCreateColor,
    required this.onColorAdded,
    required this.onColorRemoved,
    this.fieldValidator,
  });

  @override
  State<MultiSelectColorField> createState() => _MultiSelectColorFieldState();
}

class _MultiSelectColorFieldState extends State<MultiSelectColorField> {
  static const _kDebounceMs = 300;
  static const _kMaxOverlayHeight = 200.0;
  static const _kOverlayRadius = 12.0;
  static const _kItemPadding = 16.0;
  static const _kItemHeight = 52.0;

  final Debouncer _debouncer = Debouncer(milliseconds: _kDebounceMs);
  final ScrollController _scrollController = ScrollController();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();

  List<ColorModel> _suggestions = [];
  String _currentQuery = '';
  int _highlightedIndex = -1;
  bool _ignoreNextFocusLoss = false;

  bool get _isAtLimit => widget.selectedColors.length >= widget.maxSelections;

  bool get _showCreateOption =>
      _currentQuery.isNotEmpty && !_queryExistsInSuggestions;

  bool get _queryExistsInSuggestions {
    final normalizedQuery = _currentQuery.toLowerCase();
    return widget.suggestions.any((item) {
      return item.color.toLowerCase() == normalizedQuery;
    });
  }

  int get _totalItems => _suggestions.length + (_showCreateOption ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _focusNode.onKeyEvent = (node, event) => _handleKeyEvent(event);
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && !_ignoreNextFocusLoss) {
      _removeOverlay();
      setState(() => _highlightedIndex = -1);
    }
    _ignoreNextFocusLoss = false;
  }

  void _scrollToHighlighted() {
    if (!_scrollController.hasClients) return;

    final targetOffset = _highlightedIndex * _kItemHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;

    if (targetOffset + _kItemHeight > currentOffset + viewportHeight) {
      _scrollController.animateTo(
        targetOffset + _kItemHeight - viewportHeight,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    } else if (targetOffset < currentOffset) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_totalItems == 0) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1) % _totalItems;
        });
        _updateOverlay();
        _scrollToHighlighted();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _highlightedIndex = _highlightedIndex <= 0
              ? _totalItems - 1
              : _highlightedIndex - 1;
        });
        _updateOverlay();
        _scrollToHighlighted();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter:
        _selectHighlighted();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.escape:
        _removeOverlay();
        setState(() => _highlightedIndex = -1);
        return KeyEventResult.handled;

      default:
        return KeyEventResult.ignored;
    }
  }

  void _selectItem(ColorModel item) {
    if (_isAtLimit) return;

    final alreadyExists = widget.selectedColors.any(
      (c) => c.color.toLowerCase() == item.color.toLowerCase(),
    );
    if (alreadyExists) {
      _controller.clear();
      _removeOverlay();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cor já adicionada'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _ignoreNextFocusLoss = true;
    setState(() => _highlightedIndex = -1);
    _controller.clear();
    widget.onColorAdded(item);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _selectHighlighted() {
    _removeOverlay();

    if (_highlightedIndex < 0) {
      if (_suggestions.isNotEmpty) {
        _selectItem(_suggestions.first);
        return;
      }
      if (_currentQuery.isNotEmpty && _showCreateOption) {
        _createColor(_currentQuery);
      }
      return;
    }

    if (_highlightedIndex >= _suggestions.length) {
      if (_showCreateOption) {
        _createColor(_currentQuery);
      }
      return;
    }

    _selectItem(_suggestions[_highlightedIndex]);
  }

  void _search(String query) {
    _currentQuery = query;
    _highlightedIndex = -1;
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      _removeOverlay();
      return;
    }

    _debouncer.run(() async {
      final normalizedQuery = query.toLowerCase();
      final filtered = widget.suggestions.where((item) {
        return item.color.toLowerCase().contains(normalizedQuery);
      }).toList();

      if (mounted) {
        setState(() => _suggestions = filtered);
        _updateOverlay();
      }
    });
  }

  void _updateOverlay() {
    if (!_overlayController.isShowing) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      _overlayController.show();
    } else {
      setState(() {});
    }
  }

  void _removeOverlay() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  Future<void> _createColor(String name) async {
    if (_isAtLimit) return;

    final alreadyExists = widget.selectedColors.any(
      (c) => c.color.toLowerCase() == name.toLowerCase(),
    );
    if (alreadyExists) {
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cor já adicionada'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final created = await widget.onCreateColor(name);
      if (mounted) {
        _selectItem(created);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar cor: $e')));
      }
    }
  }

  Widget _buildDropdownContent(
    BuildContext context,
    OverlayChildLayoutInfo layoutInfo,
  ) {
    if (layoutInfo.childPaintTransform.determinant() == 0.0) {
      return const SizedBox.shrink();
    }

    final fieldSize = layoutInfo.childSize;
    final invertTransform = layoutInfo.childPaintTransform.clone()..invert();

    final mediaQueryPadding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    final overlayRect = mediaQueryPadding.deflateRect(
      viewInsets.deflateRect(Offset.zero & layoutInfo.overlaySize),
    );

    final overlayRectInField = MatrixUtils.transformRect(
      invertTransform,
      overlayRect,
    );

    final spaceBelow = overlayRectInField.bottom - fieldSize.height;
    final contentHeight = _totalItems * _kItemHeight;
    final optionsViewMaxHeight = math.min(
      math.min(spaceBelow, _kMaxOverlayHeight),
      contentHeight,
    );

    final optionsViewSize = Size(
      fieldSize.width,
      math.max(optionsViewMaxHeight, 0.0),
    );

    final originY = fieldSize.height;

    final transform = layoutInfo.childPaintTransform.clone()
      ..translateByDouble(0.0, originY, 0, 1);

    return Transform(
      transform: transform,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints.tight(optionsViewSize),
          child: TextFieldTapRegion(
            child: Material(
              elevation: 4.0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kOverlayRadius),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kOverlayRadius),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: _totalItems,
                  itemBuilder: (BuildContext context, int index) {
                    if (_showCreateOption && index == _suggestions.length) {
                      return _buildCreateOption();
                    }
                    return _buildOption(_suggestions[index], index);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(ColorModel option, int index) {
    final name = option.color.capitalizeAllWords;
    final isHighlighted = index == _highlightedIndex;
    final isAlreadySelected = widget.selectedColors.any(
      (c) => c.color.toLowerCase() == option.color.toLowerCase(),
    );

    return InkWell(
      onTap: isAlreadySelected ? null : () => _selectItem(option),
      child: Container(
        color: isHighlighted ? Colors.grey.shade100 : null,
        padding: const EdgeInsets.all(_kItemPadding),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isAlreadySelected ? Colors.grey.shade400 : null,
                ),
              ),
            ),
            if (isAlreadySelected)
              Icon(Icons.check, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption() {
    final isHighlighted = _highlightedIndex == _suggestions.length;

    return InkWell(
      onTap: () {
        if (_currentQuery.isEmpty) return;
        setState(() => _highlightedIndex = -1);
        _createColor(_currentQuery);
      },
      child: Container(
        color: isHighlighted ? Colors.grey.shade100 : null,
        padding: const EdgeInsets.all(_kItemPadding),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.blue.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Criar cor: "${_currentQuery.capitalizeAllWords}"',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<ColorModel>>(
      key: _fieldKey,
      initialValue: widget.selectedColors,
      validator: (_) => widget.fieldValidator?.call(widget.selectedColors),
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OverlayPortal.overlayChildLayoutBuilder(
              controller: _overlayController,
              overlayChildBuilder:
                  (BuildContext context, OverlayChildLayoutInfo info) {
                    return _buildDropdownContent(context, info);
                  },
              child: CustomTextField(
                headerLabel: widget.headerLabelText,
                hintText: _isAtLimit
                    ? 'Máximo de ${widget.maxSelections} cores atingido'
                    : widget.hintText,
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_isAtLimit,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _controller.clear();
                          _removeOverlay();
                          setState(() => _suggestions = []);
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      )
                    : null,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáàâãéèêíïóôõúüçÁÀÂÃÉÈÊÍÏÓÔÕÚÜÇ ]'),
                  ),
                ],
                onChanged: (text) {
                  _search(text);
                  setState(() {});
                },
                onFieldSubmitted: (_) => _selectHighlighted(),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            if (widget.selectedColors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.selectedColors
                    .map(
                      (color) => Chip(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        label: Text(
                          color.color.capitalizeFirst,
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 14,
                          ),
                        ),
                        onDeleted: () {
                          widget.onColorRemoved(color);
                          setState(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}
