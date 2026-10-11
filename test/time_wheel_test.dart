import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/l10n/app_localizations.dart';
import 'package:royal_marble/widgets/time_wheel_picker.dart';

/// Opens the wheel picker at 13:05 on a phone set to 24-hour time or not;
/// [onPicked] gets what the sheet returns.
Future<void> openPicker(WidgetTester tester,
    {required bool h24, required ValueChanged<TimeOfDay?> onPicked}) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: h24),
      child: child!,
    ),
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async => onPicked(await showTimeWheel(context,
            initial: const TimeOfDay(hour: 13, minute: 5), title: 'Check in')),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('24-hour phones: hour and minute wheels, no AM/PM',
      (tester) async {
    TimeOfDay? picked;
    await openPicker(tester, h24: true, onPicked: (t) => picked = t);
    expect(find.text('Check in'), findsOneWidget);
    expect(find.text('13:05'), findsOneWidget);
    expect(find.text('PM'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(picked, const TimeOfDay(hour: 13, minute: 5));
  });

  testWidgets('12-hour phones: switching PM to AM keeps the hour',
      (tester) async {
    TimeOfDay? picked;
    await openPicker(tester, h24: false, onPicked: (t) => picked = t);
    expect(find.text('1:05 PM'), findsOneWidget);

    await tester.drag(find.text('PM').last, const Offset(0, 52));
    await tester.pumpAndSettle();
    expect(find.text('1:05 AM'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(picked, const TimeOfDay(hour: 1, minute: 5));
  });

  testWidgets('Cancel returns nothing', (tester) async {
    TimeOfDay? picked = const TimeOfDay(hour: 0, minute: 0);
    await openPicker(tester, h24: true, onPicked: (t) => picked = t);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });
}
