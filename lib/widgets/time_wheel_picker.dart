import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/locale_controller.dart';

/// Picks a time with scroll wheels (hours, minutes and AM/PM on 12-hour
/// phones) in a bottom sheet, instead of Android's clock dial. The chosen
/// time is shown large above the wheels. Returns null when dismissed.
Future<TimeOfDay?> showTimeWheel(BuildContext context,
    {required TimeOfDay initial, String? title}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _TimeWheelSheet(initial: initial, title: title),
  );
}

class _TimeWheelSheet extends StatefulWidget {
  const _TimeWheelSheet({required this.initial, this.title});
  final TimeOfDay initial;
  final String? title;

  @override
  State<_TimeWheelSheet> createState() => _TimeWheelSheetState();
}

class _TimeWheelSheetState extends State<_TimeWheelSheet> {
  static const _itemExtent = 52.0;
  late int _hour = widget.initial.hour;
  late int _minute = widget.initial.minute;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ml = MaterialLocalizations.of(context);
    final h24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final time = TimeOfDay(hour: _hour, minute: _minute);
    final digits = Theme.of(context)
        .textTheme
        .headlineSmall
        ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.charcoal);

    Widget wheel({
      required int count,
      required int selected,
      required String Function(int) label,
      required ValueChanged<int> onChanged,
      bool looping = true,
    }) =>
        Expanded(
          child: CupertinoPicker(
            scrollController:
                FixedExtentScrollController(initialItem: selected),
            itemExtent: _itemExtent,
            looping: looping,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: onChanged,
            children: [
              for (var i = 0; i < count; i++)
                Center(child: Text(label(i), style: digits)),
            ],
          ),
        );

    final hour12 = _hour % 12 == 0 ? 12 : _hour % 12;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.title != null)
            Text(widget.title!,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(ml.formatTimeOfDay(time, alwaysUse24HourFormat: h24),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.charcoal)),
          const SizedBox(height: 12),
          SizedBox(
            height: _itemExtent * 4.5,
            // Times read hours-then-minutes in every language.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  height: _itemExtent,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Row(children: [
                  if (h24)
                    wheel(
                      count: 24,
                      selected: _hour,
                      label: (i) => i.toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _hour = i),
                    )
                  else
                    wheel(
                      count: 12,
                      selected: hour12 - 1,
                      label: (i) => '${i + 1}',
                      onChanged: (i) => setState(() =>
                          _hour = (i + 1) % 12 + (_hour >= 12 ? 12 : 0)),
                    ),
                  Text(':', style: digits),
                  wheel(
                    count: 60,
                    selected: _minute,
                    label: (i) => i.toString().padLeft(2, '0'),
                    onChanged: (i) => setState(() => _minute = i),
                  ),
                  if (!h24)
                    wheel(
                      count: 2,
                      selected: _hour >= 12 ? 1 : 0,
                      looping: false,
                      label: (i) => i == 0
                          ? ml.anteMeridiemAbbreviation
                          : ml.postMeridiemAbbreviation,
                      onChanged: (i) => setState(
                          () => _hour = _hour % 12 + (i == 1 ? 12 : 0)),
                    ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                  onPressed: () => Navigator.pop(context, time),
                  child: Text(l.done)),
            ),
          ]),
        ]),
      ),
    );
  }
}
