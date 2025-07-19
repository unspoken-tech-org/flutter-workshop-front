import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class WsSearchBarWidget extends StatefulWidget {
  final String labelText;
  final void Function(String)? onChanged;
  final void Function()? onClear;

  const WsSearchBarWidget({
    super.key,
    required this.labelText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<WsSearchBarWidget> createState() => _WsSearchBarWidgetState();
}

class _WsSearchBarWidgetState extends State<WsSearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        widget.onChanged?.call(value);
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
                  _searchController.clear();
                  widget.onClear?.call();
                },
              )
            : null,
      ),
    );
  }
}
