import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_colors.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/core/extensions/date_time_extension.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/utils/filter_utils.dart';
import 'package:flutter_workshop_front/widgets/rounded_filter_bar.dart';

class WsFilterBar extends StatefulWidget {
  final HomeController controller;

  const WsFilterBar({
    super.key,
    required this.controller,
  });

  @override
  State<WsFilterBar> createState() => _WsFilterBarState();
}

class _WsFilterBarState extends State<WsFilterBar> {
  final _textController = TextEditingController();
  final _filterOverlay = OverlayPortalController();
  final _filterKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Row(
            children: [
              Expanded(
                child: RoundedFilterBar(
                  controller: _textController,
                  onEnter: () => filterTable(),
                  onClear: () => filterTable(),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                key: _filterKey,
                label: const Text('Filtrar'),
                icon: const Icon(Icons.filter_alt_outlined),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: WsColors.primary, width: 2),
                ),
                onPressed: () {
                  _filterOverlay.show();
                },
              ),
            ],
          ),
        ),
        OverlayPortal(
            controller: _filterOverlay,
            overlayChildBuilder: (context) {
              final filterBtn =
                  _filterKey.currentContext?.findRenderObject() as RenderBox;
              final filterBtnSize = filterBtn.size;
              final filterBtnPosition = filterBtn.localToGlobal(Offset.zero);
              return Positioned(
                top: filterBtnPosition.dy + filterBtnSize.height + 6,
                left: filterBtnPosition.dx,
                child: TapRegion(
                  behavior: HitTestBehavior.opaque,
                  onTapOutside: (event) {
                    if (widget.controller.isDatePickerOpen) return;

                    _filterOverlay.hide();
                  },
                  child: DeviceFilters(
                    controller: widget.controller,
                    onFilter: () {
                      widget.controller.getTableData(widget.controller.filter);
                      _filterOverlay.hide();
                    },
                    onClear: () {
                      widget.controller.getTableData(
                          widget.controller.filter..clearSelectableFilters());
                      _filterOverlay.hide();
                    },
                  ),
                ),
              );
            })
      ],
    );
  }

  void filterTable() {
    var filter = widget.controller.filter;
    filter.clearTypedFilters();

    var search = FilterUtils(_textController.text);
    if (search.isName) {
      filter.customerName = search.term;
    } else if (search.isCpf) {
      filter.customerCpf = search.term.replaceAll('.', '').replaceAll('-', '');
    } else if (search.isPhoneOrCellPhone) {
      filter.customerPhone = search.term;
    } else if (search.isDeviceId) {
      filter.deviceId = int.parse(search.term);
    }
    widget.controller.getTableData(filter);
  }
}

class DeviceFilters extends StatelessWidget {
  final VoidCallback onFilter;
  final VoidCallback onClear;
  final HomeController controller;

  const DeviceFilters(
      {super.key,
      required this.controller,
      required this.onFilter,
      required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 304,
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WsColors.onPrimary,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: WsColors.dark.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: ListView(
              children: [
                StatusFilter(controller: controller),
                const SizedBox(height: 16),
                TypesFilter(controller: controller),
                const SizedBox(height: 16),
                BrandsFilter(controller: controller),
                const SizedBox(height: 16),
                DateRangeFilter(controller: controller),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton(
                onPressed: onClear,
                style: FilledButton.styleFrom(
                  fixedSize: const Size(120, 34),
                  backgroundColor: WsColors.warning,
                ),
                child: const Text('Limpar'),
              ),
              FilledButton(
                onPressed: onFilter,
                style: FilledButton.styleFrom(
                  fixedSize: const Size(120, 34),
                  backgroundColor: WsColors.success,
                ),
                child: const Text('Filtrar'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class DateRangeFilter extends StatefulWidget {
  final HomeController controller;

  const DateRangeFilter({
    super.key,
    required this.controller,
  });

  @override
  State<DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<DateRangeFilter> {
  DateTimeRange? timeRange;

  void showDateRange(BuildContext context) async {
    widget.controller.isDatePickerOpen = true;

    var results = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(400, 400),
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
    );
    widget.controller.isDatePickerOpen = false;

    if (results == null) return;

    setState(() {
      timeRange = DateTimeRange(
        start: results.first ?? DateTime.now(),
        end: results.last ?? DateTime.now(),
      );
    });

    widget.controller.filter.initialEntryDate = timeRange?.start;
    widget.controller.filter.finalEntryDate = timeRange?.end;
  }

  @override
  void initState() {
    var initialEntryDate = widget.controller.filter.initialEntryDate;
    var finalEntryDate = widget.controller.filter.finalEntryDate;

    if (initialEntryDate != null || finalEntryDate != null) {
      timeRange = DateTimeRange(
        start: initialEntryDate ?? DateTime.now(),
        end: finalEntryDate ?? DateTime.now(),
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data de Entrada',
          style: WsTextStyles.h4.copyWith(color: WsColors.dark),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => showDateRange(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 1.5)),
            child: Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 24),
                const SizedBox(width: 8),
                if (timeRange != null) ...[
                  const Text('De '),
                  Text(
                    '${timeRange?.start.formatDate()} ',
                    style: WsTextStyles.body2.copyWith(
                        color: WsColors.dark, fontWeight: FontWeight.bold),
                  ),
                  const Text('até '),
                  Text(
                    '${timeRange?.end.formatDate()}',
                    style: WsTextStyles.body2.copyWith(
                        color: WsColors.dark, fontWeight: FontWeight.bold),
                  )
                ] else
                  Text(
                    'Selecione um intervalo de datas',
                    style: WsTextStyles.body2,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BrandsFilter extends StatefulWidget {
  final HomeController controller;

  const BrandsFilter({
    super.key,
    required this.controller,
  });

  @override
  State<BrandsFilter> createState() => _BrandsFilterState();
}

class _BrandsFilterState extends State<BrandsFilter> {
  final _textController = TextEditingController();

  final int maxBrands = 5;

  List<DeviceBrandModel> brands = [];

  void findBrandsByName() async {
    String name = _textController.text;

    var result = await widget.controller.getAllDeviceBrands(name);
    brands = result;
    setState(() {});
  }

  @override
  void initState() {
    widget.controller.getAllDeviceBrands().then((value) {
      brands = value;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marca de Aparelho',
          style: WsTextStyles.h4.copyWith(color: WsColors.dark),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 270,
          child: RoundedFilterBar(
            height: 38,
            controller: _textController,
            hintText: 'Pesquisar Marca',
            onEnter: findBrandsByName,
            onClear: findBrandsByName,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          runAlignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            ...brands
                .getRange(
                    0, maxBrands > brands.length ? brands.length : maxBrands)
                .map(
                  (e) => GeneralFilterChip(
                    name: e.brand,
                    onTap: () {
                      widget.controller.filter.toggleBrands(e.idBrand);
                      setState(() {});
                    },
                    isSelected: widget.controller.filter.deviceBrands
                        .contains(e.idBrand),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class TypesFilter extends StatefulWidget {
  final HomeController controller;

  const TypesFilter({
    super.key,
    required this.controller,
  });

  @override
  State<TypesFilter> createState() => _TypesFilterState();
}

class _TypesFilterState extends State<TypesFilter> {
  final _textController = TextEditingController();

  final int maxTypes = 5;

  List<DeviceTypeModel> types = [];

  void findDevicesByName() async {
    String name = _textController.text;

    var result = await widget.controller.getAllDeviceTypes(name);
    types = result;
    setState(() {});
  }

  @override
  void initState() {
    widget.controller.getAllDeviceTypes().then((value) {
      types = value;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Aparelho',
          style: WsTextStyles.h4.copyWith(color: WsColors.dark),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 270,
          child: RoundedFilterBar(
            height: 38,
            controller: _textController,
            hintText: 'Pesquisar Tipo',
            onEnter: findDevicesByName,
            onClear: findDevicesByName,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          runAlignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            ...types
                .getRange(0, maxTypes > types.length ? types.length : maxTypes)
                .map(
                  (e) => GeneralFilterChip(
                    name: e.typeName,
                    onTap: () {
                      widget.controller.filter.toggleTypes(e.idType);
                      setState(() {});
                    },
                    isSelected:
                        widget.controller.filter.deviceTypes.contains(e.idType),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class GeneralFilterChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const GeneralFilterChip({
    super.key,
    required this.name,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? WsColors.dark.withAlpha(90) : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: isSelected ? 10 : 0,
      ),
      onPressed: onTap,
      child: Text(
        name,
        style: WsTextStyles.body2.copyWith(color: Colors.white),
      ),
    );
  }
}

class StatusFilter extends StatefulWidget {
  final HomeController controller;

  const StatusFilter({
    super.key,
    required this.controller,
  });

  @override
  State<StatusFilter> createState() => _StatusFilterState();
}

class _StatusFilterState extends State<StatusFilter> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: WsTextStyles.h4.copyWith(color: WsColors.dark),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...StatusEnum.values.map(
              (e) => StatusFilterChip(
                status: e,
                onTap: () {
                  widget.controller.filter.toggleStatus(e.value);
                  setState(() {});
                },
                isSelected: widget.controller.filter.status.contains(e.value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StatusFilterChip extends StatelessWidget {
  final StatusEnum status;
  final bool isSelected;
  final VoidCallback onTap;

  const StatusFilterChip({
    super.key,
    required this.status,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        backgroundColor: status.color,
        side: BorderSide(
          color: isSelected ? Colors.black : Colors.transparent,
          width: 1.5,
        ),
      ),
      onPressed: onTap,
      child: Text(
        status.name,
        style: WsTextStyles.body2.copyWith(color: Colors.white),
      ),
    );
  }
}
