import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/debouncer.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class WsSearchBarWidget extends StatefulWidget {
  final String labelText;
  final void Function(String)? onChanged;
  final void Function()? onClear;
  final int debounceTime;

  const WsSearchBarWidget({
    super.key,
    required this.labelText,
    required this.onChanged,
    required this.onClear,
    this.debounceTime = 300,
  });

  @override
  State<WsSearchBarWidget> createState() => _WsSearchBarWidgetState();
}

class _WsSearchBarWidgetState extends State<WsSearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  late final Debouncer _debouncer =
      Debouncer(milliseconds: widget.debounceTime);

  @override
  void dispose() {
    _debouncer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        _debouncer.run(() {
          widget.onChanged?.call(value);
        });
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: WsTextStyles.body1.copyWith(
          color: Colors.grey.shade400,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.grey.shade400,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: Colors.blue.shade700,
          ),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _debouncer.cancel();
                  _searchController.clear();
                  widget.onClear?.call();
                },
              )
            : null,
      ),
    );
  }
}
