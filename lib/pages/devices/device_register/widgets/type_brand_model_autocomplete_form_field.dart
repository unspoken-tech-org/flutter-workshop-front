import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_workshop_front/core/debouncer.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';

typedef SearchFn<T> = Future<List<T>> Function(String query);
typedef CreateFn<T> = Future<T> Function(String name);

class TypeBrandModelAutocompleteFormField<T extends ITypeBrandModelColor>
    extends StatefulWidget {
  final TextEditingController? _externalController;
  final String? headerLabelText;
  final String? hintText;
  final bool enabled;
  final SearchFn<T> searchFn;
  final CreateFn<T> createFn;
  final String Function(T item) getName;
  final int Function(T item) getId;
  final void Function(T item) onAccept;
  final VoidCallback? onClear;
  final String? Function(String? value)? fieldValidator;
  final void Function(String? name)? onSave;
  final String createLabel;
  final String createSuccessMessage;

  const TypeBrandModelAutocompleteFormField({
    super.key,
    TextEditingController? controller,
    this.headerLabelText,
    this.hintText,
    this.enabled = true,
    required this.searchFn,
    required this.createFn,
    required this.getName,
    required this.getId,
    required this.onAccept,
    this.onClear,
    this.fieldValidator,
    this.onSave,
    this.createLabel = 'Criar novo',
    this.createSuccessMessage = 'Item criado com sucesso',
  }) : _externalController = controller;

  @override
  State<TypeBrandModelAutocompleteFormField<T>> createState() =>
      _TypeBrandModelAutocompleteFormFieldState<T>();
}

class _TypeBrandModelAutocompleteFormFieldState<T extends ITypeBrandModelColor>
    extends State<TypeBrandModelAutocompleteFormField<T>> {
  static const _kDebounceMs = 300;
  static const _kMaxOverlayHeight = 200.0;
  static const _kOverlayRadius = 12.0;
  static const _kItemPadding = 16.0;
  static const _kItemHeight = 52.0;
  static const _kSelectedBorderColor = Color(0xFF6EE7B7);

  final Debouncer _debouncer = Debouncer(milliseconds: _kDebounceMs);
  final ScrollController _scrollController = ScrollController();
  final OverlayPortalController _overlayController = OverlayPortalController();
  late final TextEditingController _controller;
  late final bool _ownsController;
  List<T> _suggestions = [];
  String _currentQuery = '';
  bool _isSelected = false;
  int _highlightedIndex = -1;
  bool _ignoreNextFocusLoss = false;
  final FocusNode _focusNode = FocusNode();

  bool get _showCreateOption =>
      _currentQuery.isNotEmpty && !_queryExistsInSuggestions;

  int get _totalItems => _suggestions.length + (_showCreateOption ? 1 : 0);

  bool get _queryExistsInSuggestions {
    final normalizedQuery = _currentQuery.toLowerCase();
    return _suggestions.any((item) {
      return widget.getName(item).toLowerCase() == normalizedQuery;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = widget._externalController ?? TextEditingController();
    _ownsController = widget._externalController == null;
    _focusNode.addListener(_onFocusChange);
    _focusNode.onKeyEvent = (node, event) => _handleKeyEvent(event);
  }

  @override
  void didUpdateWidget(TypeBrandModelAutocompleteFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      setState(() {
        _isSelected = false;
        _highlightedIndex = -1;
      });
      _controller.clear();
    }
    if (widget._externalController != oldWidget._externalController) {
      if (_ownsController) _controller.dispose();
      _controller = widget._externalController ?? TextEditingController();
      _ownsController = widget._externalController == null;
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (_ownsController) _controller.dispose();
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

  void _selectItem(T item) {
    final name = widget.getName(item).capitalizeAllWords;
    _ignoreNextFocusLoss = true;
    setState(() {
      _isSelected = true;
      _highlightedIndex = -1;
    });
    _controller.text = name;
    widget.onAccept(item);
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
      if (_currentQuery.isNotEmpty) {
        _createItem(_currentQuery);
      }
      return;
    }

    if (_highlightedIndex >= _suggestions.length) {
      if (_showCreateOption) {
        _createItem(_currentQuery);
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
      try {
        final results = await widget.searchFn(query);
        if (mounted) {
          setState(() => _suggestions = results);
          _updateOverlay();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _suggestions = []);
          _removeOverlay();
        }
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

  void _clearSelection() {
    setState(() {
      _isSelected = false;
      _controller.clear();
    });
    widget.onClear?.call();
  }

  Future<void> _createItem(String name) async {
    try {
      final created = await widget.createFn(name);
      if (mounted) {
        _selectItem(created);
        SnackBarUtil().showSuccess(widget.createSuccessMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar: $e')));
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

  Widget _buildOption(T option, int index) {
    final name = widget.getName(option).capitalizeAllWords;
    final isHighlighted = index == _highlightedIndex;

    return InkWell(
      onTap: () => _selectItem(option),
      child: Container(
        color: isHighlighted ? Colors.grey.shade100 : null,
        padding: const EdgeInsets.all(_kItemPadding),
        child: Text(name),
      ),
    );
  }

  Widget _buildCreateOption() {
    final isHighlighted = _highlightedIndex == _suggestions.length;

    return InkWell(
      onTap: () {
        if (_currentQuery.isEmpty) return;
        setState(() => _highlightedIndex = -1);
        _createItem(_currentQuery);
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
                '${widget.createLabel}: "${_currentQuery.capitalizeAllWords}"',
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
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      overlayChildBuilder: (BuildContext context, OverlayChildLayoutInfo info) {
        return _buildDropdownContent(context, info);
      },
      child: CustomTextField(
        headerLabel: widget.headerLabelText,
        hintText: _isSelected ? null : widget.hintText,
        controller: _controller,
        focusNode: _focusNode,
        readOnly: _isSelected,
        enabled: widget.enabled,
        suffixIcon: _isSelected
            ? IconButton(
                onPressed: _clearSelection,
                icon: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
              )
            : null,
        selectedBorderColor: _isSelected ? _kSelectedBorderColor : null,
        onChanged: (text) {
          if (text.isEmpty) widget.onClear?.call();
          _search(text);
        },
        onFieldSubmitted: (_) => _selectHighlighted(),
        onSave: widget.onSave,
        validator: widget.fieldValidator,
      ),
    );
  }
}
