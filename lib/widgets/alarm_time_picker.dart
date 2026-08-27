import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'cute_widgets.dart' show SoftCard;

class AlarmTimePicker extends StatefulWidget {
  const AlarmTimePicker({
    super.key,
    required this.time,
    required this.onChanged,
    this.readOnly = false,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;
  final bool readOnly;

  @override
  State<AlarmTimePicker> createState() => _AlarmTimePickerState();
}

class _AlarmTimePickerState extends State<AlarmTimePicker> {
  static const _itemHeight = 44.0;
  static const _visibleItems = 5;
  static const _wheelHeight = _itemHeight * _visibleItems;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  late int _hour12;
  late int _minute;
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    _syncFromTime(widget.time);
    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void didUpdateWidget(covariant AlarmTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.time != widget.time) {
      _syncFromTime(widget.time);
      _hourController.jumpToItem(_hour12 - 1);
      _minuteController.jumpToItem(_minute);
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _syncFromTime(TimeOfDay time) {
    _hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    _minute = time.minute;
    _isPm = time.hour >= 12;
  }

  void _emitChange() {
    var hour24 = _hour12 % 12;
    if (_isPm) hour24 += 12;
    widget.onChanged(TimeOfDay(hour: hour24, minute: _minute));
  }

  void _setPeriod(bool isPm) {
    if (widget.readOnly || _isPm == isPm) return;
    HapticFeedback.selectionClick();
    setState(() => _isPm = isPm);
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      accent: AppColors.lime,
      child: Column(
        children: [
          Text(
            'set time',
            style: AppTheme.body(14, weight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 72, child: Center(child: Text('hour', style: AppTheme.body(12)))),
              const SizedBox(width: 22),
              SizedBox(width: 72, child: Center(child: Text('min', style: AppTheme.body(12)))),
              const SizedBox(width: 64),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: _wheelHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      height: _itemHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.lime.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lime.withValues(alpha: 0.35)),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _WheelColumn(
                      controller: _hourController,
                      itemCount: 12,
                      readOnly: widget.readOnly,
                      formatter: (index) => '${index + 1}'.padLeft(2, '0'),
                      onSelected: (index) {
                        HapticFeedback.selectionClick();
                        setState(() => _hour12 = index + 1);
                        _emitChange();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        ':',
                        style: AppTheme.display(36, weight: FontWeight.w600).copyWith(
                          color: AppColors.white,
                          height: 1,
                        ),
                      ),
                    ),
                    _WheelColumn(
                      controller: _minuteController,
                      itemCount: 60,
                      readOnly: widget.readOnly,
                      formatter: (index) => index.toString().padLeft(2, '0'),
                      onSelected: (index) {
                        HapticFeedback.selectionClick();
                        setState(() => _minute = index);
                        _emitChange();
                      },
                    ),
                    const SizedBox(width: 12),
                    _PeriodPicker(
                      isPm: _isPm,
                      readOnly: widget.readOnly,
                      onChanged: _setPeriod,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.controller,
    required this.itemCount,
    required this.formatter,
    required this.onSelected,
    required this.readOnly,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) formatter;
  final ValueChanged<int> onSelected;
  final bool readOnly;

  static const _itemHeight = _AlarmTimePickerState._itemHeight;
  static const _wheelHeight = _AlarmTimePickerState._wheelHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: _wheelHeight,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        physics: readOnly ? const NeverScrollableScrollPhysics() : const FixedExtentScrollPhysics(),
        itemExtent: _itemHeight,
        perspective: 0.003,
        diameterRatio: 1.4,
        onSelectedItemChanged: readOnly ? null : onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            final selected = controller.hasClients && controller.selectedItem == index;
            return Center(
              child: Text(
                formatter(index),
                style: AppTheme.display(
                  selected ? 30 : 20,
                  weight: selected ? FontWeight.w700 : FontWeight.w400,
                ).copyWith(
                  color: selected ? AppColors.lime : AppColors.muted,
                  height: 1,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({
    required this.isPm,
    required this.readOnly,
    required this.onChanged,
  });

  final bool isPm;
  final bool readOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PeriodButton(
          label: 'AM',
          selected: !isPm,
          onTap: readOnly ? null : () => onChanged(false),
        ),
        const SizedBox(height: 8),
        _PeriodButton(
          label: 'PM',
          selected: isPm,
          onTap: readOnly ? null : () => onChanged(true),
        ),
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.lime : AppColors.stroke),
        ),
        child: Text(
          label,
          style: AppTheme.body(14, weight: FontWeight.w600).copyWith(
            color: selected ? AppColors.voidBlack : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
