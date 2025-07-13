import 'package:flutter/material.dart';

class HoverableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Color? color;
  final BorderSide borderSide;
  final double elevationOnHover;
  final double elevation;

  const HoverableCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.color = Colors.white,
    this.borderSide = const BorderSide(color: Color(0xFFE0E0E0)),
    this.elevationOnHover = 5,
    this.elevation = 0.5,
  });

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: _onHover,
      borderRadius: widget.borderRadius,
      child: Card(
        color: widget.color,
        elevation: _isHovered ? widget.elevationOnHover : widget.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius,
          side: widget.borderSide,
        ),
        child: widget.child,
      ),
    );
  }
}
