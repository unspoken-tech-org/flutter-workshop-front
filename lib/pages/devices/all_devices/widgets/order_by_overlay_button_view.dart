import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/order_by_view.dart';
import 'package:provider/provider.dart';

class OrderByButtonView extends StatefulWidget {
  const OrderByButtonView({super.key});

  @override
  State<OrderByButtonView> createState() => _OrderByButtonViewState();
}

class _OrderByButtonViewState extends State<OrderByButtonView>
    with SingleTickerProviderStateMixin {
  final layerLink = LayerLink();
  late final AnimationController animationController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;
  final _overlayPortalController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(animationController);
    slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
            .animate(animationController);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void toggleOverlay() {
    if (_overlayPortalController.isShowing) {
      animationController.reverse().then((_) {
        _overlayPortalController.hide();
      });
    } else {
      _overlayPortalController.show();
      animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AllDevicesController, Map<OrderBy, OrderDirection?>>(
      selector: (context, controller) => controller.filter.orderBy,
      builder: (context, values, _) {
        final orderBy = values;
        final selectedOrderBy = orderBy.entries.firstWhereOrNull(
          (e) => e.value != null,
        );

        return OverlayPortal(
          controller: _overlayPortalController,
          overlayChildBuilder: (context) {
            return CompositedTransformFollower(
              link: layerLink,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 10),
              child: Align(
                alignment: Alignment.topRight,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: SizedBox(
                      width: 470,
                      child: TapRegion(
                        onTapOutside: (_) {
                          if (_overlayPortalController.isShowing) {
                            toggleOverlay();
                          }
                        },
                        child: const OrderByView(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: CompositedTransformTarget(
            link: layerLink,
            child: OutlinedButton.icon(
              onPressed: toggleOverlay,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              label: Text(
                selectedOrderBy?.key.displayName ?? 'Ordenar por',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              icon: selectedOrderBy == null
                  ? null
                  : Icon(
                      selectedOrderBy.value == OrderDirection.asc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.black,
                    ),
            ),
          ),
        );
      },
    );
  }
}
