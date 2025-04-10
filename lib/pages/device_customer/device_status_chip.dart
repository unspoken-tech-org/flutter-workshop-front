import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/inherited_device_customer_controller.dart';

class DeviceStatusChip extends StatefulWidget {
  final StatusEnum status;
  const DeviceStatusChip({super.key, required this.status});

  @override
  State<DeviceStatusChip> createState() => _DeviceStatusChipState();
}

class _DeviceStatusChipState extends State<DeviceStatusChip> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOverlayHovered = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay(
      BuildContext context, DeviceCustomerPageController controller) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 220,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 30),
          child: MouseRegion(
            onEnter: (_) {
              _isOverlayHovered = true;
            },
            onExit: (_) {
              _isOverlayHovered = false;
              _removeOverlay();
            },
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: StatusEnum.values
                      .map((status) => TextButton(
                            onPressed: () {
                              var newDeviceCustomer = controller
                                  .currentDeviceCustomer.value
                                  .copyWith(deviceStatus: status);

                              controller
                                  .updateNewDeviceCustomer(newDeviceCustomer);
                              setState(() {
                                _isOverlayHovered = false;
                              });
                              _removeOverlay();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: status.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  status.name,
                                  style: WsTextStyles.body2
                                      .copyWith(color: status.color),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (!_isOverlayHovered) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showOverlay(context, controller),
        onExit: (_) => Future.delayed(
          const Duration(milliseconds: 100),
          () => _removeOverlay(),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: widget.status.color.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.status.name,
            style: WsTextStyles.body2.copyWith(
                color: widget.status.color, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
