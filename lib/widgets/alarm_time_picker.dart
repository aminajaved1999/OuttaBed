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
  late int _hour12;
  late int _minute;
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    _syncFromTime(widget.time);
  }

  @override
  void didUpdateWidget(covariant AlarmTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.time != widget.time) {
      setState(() => _syncFromTime(widget.time));
    }
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

  void _bumpHour(int delta) {
    if (widget.readOnly) return;
    HapticFeedback.selectionClick();
    setState(() {
      _hour12 = (_hour12 + delta - 1) % 12 + 1;
    });
    _emitChange();
  }

  void _bumpMinute(int delta) {
    if (widget.readOnly) return;
    HapticFeedback.selectionClick();
    setState(() {
      _minute = (_minute + delta + 60) % 60;
    });
    _emitChange();
  }

  void _setPeriod(bool isPm) {
    if (widget.readOnly || _isPm == isPm) return;
    HapticFeedback.selectionClick();
    setState(() => _isPm = isPm);
    _emitChange();
  }

  String get _displayTime {
    final h = _hour12.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    final p = _isPm ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      accent: AppColors.lime,
      child: Column(
        children: [
          Text('set time', style: AppTheme.body(14, weight: FontWeight.w500)),
          const SizedBox(height: 16),
          Text(
            _displayTime,
            style: AppTheme.display(44, weight: FontWeight.w700).copyWith(
              color: AppColors.lime,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StepperColumn(
                  label: 'hour',
                  value: _hour12.toString().padLeft(2, '0'),
                  readOnly: widget.readOnly,
                  onDecrement: () => _bumpHour(-1),
                  onIncrement: () => _bumpHour(1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: AppTheme.display(32, weight: FontWeight.w600).copyWith(color: AppColors.white),
                ),
              ),
              Expanded(
                child: _StepperColumn(
                  label: 'min',
                  value: _minute.toString().padLeft(2, '0'),
                  readOnly: widget.readOnly,
                  onDecrement: () => _bumpMinute(-1),
                  onIncrement: () => _bumpMinute(1),
                ),
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
    );
  }
}

class _StepperColumn extends StatelessWidget {
  const _StepperColumn({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.readOnly,
  });

  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTheme.body(12, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        _StepperButton(icon: Icons.remove_rounded, onTap: readOnly ? null : onDecrement),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTheme.display(32, weight: FontWeight.w700).copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 6),
        _StepperButton(icon: Icons.add_rounded, onTap: readOnly ? null : onIncrement),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Icon(icon, color: onTap == null ? AppColors.muted : AppColors.lime, size: 26),
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
      children: [
        const SizedBox(height: 20),
        _PeriodButton(label: 'AM', selected: !isPm, onTap: readOnly ? null : () => onChanged(false)),
        const SizedBox(height: 8),
        _PeriodButton(label: 'PM', selected: isPm, onTap: readOnly ? null : () => onChanged(true)),
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
