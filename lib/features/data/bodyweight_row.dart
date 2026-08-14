import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../core/widgets/weight_entry.dart';
import '../../data/services/weight_unit_service.dart';

/// The Body section of the Profile tab: one quiet row between the calendar
/// and recent sessions. Tap it and the edit sheet rises with a keypad.
class BodyweightRow extends StatelessWidget {
  final double? kg;
  final bool savedNow;
  final VoidCallback onOpen;

  const BodyweightRow({
    super.key,
    required this.kg,
    required this.savedNow,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WeightUnit>(
      valueListenable: WeightUnitService.notifier,
      builder: (context, unit, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TypeSectionLabel('Body'),
          TypeContentRow(
            name: 'Bodyweight',
            sub: savedNow
                ? 'Updated just now'
                : 'Used for weighted skill targets',
            subColor: savedNow ? AppColors.green : null,
            right: kg == null
                ? 'Not set'
                : '${WeightUnitService.displayText(kg!)} ${unit.suffix}',
            last: true,
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet bodyweight editor: kg/lbs segmented toggle, the number as
/// the tap target, a decimal keypad. Returns the saved value in canonical
/// kilograms, or null when dismissed.
Future<double?> showBodyweightSheet(
  BuildContext context, {
  required double? kg,
}) {
  return showModalBottomSheet<double>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _BodyweightSheet(kg: kg),
  );
}

class _BodyweightSheet extends StatefulWidget {
  final double? kg;

  const _BodyweightSheet({required this.kg});

  @override
  State<_BodyweightSheet> createState() => _BodyweightSheetState();
}

class _BodyweightSheetState extends State<_BodyweightSheet> {
  static const _minKg = 30.0;
  static const _maxKg = 250.0;

  WeightUnit _unit = WeightUnitService.unit;
  String _edit = '';

  double get _currentKg => widget.kg ?? 75;

  /// What Save would write, in kilograms: the typed number read in the
  /// active unit, clamped to something human.
  double get _effectiveKg {
    if (_edit.isEmpty) return _currentKg.clamp(_minKg, _maxKg);
    final parsed = double.tryParse(_edit);
    if (parsed == null || parsed <= 0) return _currentKg.clamp(_minKg, _maxKg);
    final kg =
        _unit == WeightUnit.lb ? parsed * WeightUnitService.kgPerLb : parsed;
    return kg.clamp(_minKg, _maxKg);
  }

  String get _valueText {
    if (_edit.isNotEmpty) return _edit;
    final display = _unit == WeightUnit.lb
        ? _currentKg / WeightUnitService.kgPerLb
        : _currentKg;
    return display.toStringAsFixed(1);
  }

  /// The sheet's toggle is the app-wide choice, same as the wizard's.
  void _pickUnit(WeightUnit unit) {
    if (unit == _unit) return;
    setState(() {
      _unit = unit;
      _edit = '';
    });
    WeightUnitService.set(unit);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 16 + bottomInset),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        // Scrolls rather than overflows when a short screen can't fit the
        // keypad under the number.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('BODYWEIGHT', style: monoStyle()),
              const SizedBox(height: 20),
              Center(
                  child: WeightUnitToggle(unit: _unit, onChanged: _pickUnit)),
              const SizedBox(height: 18),
              WeightValueDisplay(
                text: _valueText,
                dim: _edit.isEmpty,
                unit: _unit,
                editing: true,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              WeightKeypad(
                onKey: (key) =>
                    setState(() => _edit = weightEntryPress(_edit, key)),
              ),
              const SizedBox(height: 18),
              PillButton(
                label: 'Save',
                onTap: () => Navigator.of(context).pop(_effectiveKg),
              ),
              const SizedBox(height: 4),
              Pressable(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
