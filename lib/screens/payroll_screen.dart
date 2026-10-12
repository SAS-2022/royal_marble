import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../account_settings/admin_user_view.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../core/roles.dart';
import '../models/pay_calc.dart';
import '../models/user_model.dart';
import '../reports/report_export.dart';
import '../services/pay_service.dart';
import '../shared/loading.dart';
import '../shared/save_launch_file.dart';

/// HR and admins: what everyone has earned this month (or last month) from
/// their hours and approved overtime, with an Excel export.
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key, required this.users, required this.viewer});
  final List<UserData> users;
  final UserData viewer;

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

typedef _Line = ({UserData user, PaySoFar? pay, String currency});

class _PayrollScreenState extends State<PayrollScreen> {
  bool _lastMonth = false;
  late Future<List<_Line>> _lines = _load();

  DateTime get _monthDay {
    final now = DateTime.now();
    return _lastMonth ? DateTime(now.year, now.month - 1) : now;
  }

  Future<List<_Line>> _load() async {
    final now = DateTime.now();
    final range = PayService.month(_monthDay, now);
    final (workers, packages, decisions) = await (
      PayService.loadDays(range),
      PayService.packages(),
      PayService.decisionsIn(range),
    ).wait;
    final lines = <_Line>[
      for (final u in widget.users)
        if (u.isActive == true &&
            primaryRole(u.roles).isTracked &&
            (packages.containsKey(u.uid) || workers.containsKey(u.uid)))
          (
            user: u,
            currency: packages[u.uid]?.currency ?? 'AED',
            pay: packages[u.uid] == null
                ? null
                : paySoFar(packages[u.uid]!, workers[u.uid]?.days ?? const {},
                    decisions[u.uid] ?? const {}, now),
          )
    ]..sort((a, b) => _name(a.user).compareTo(_name(b.user)));
    return lines;
  }

  static String _name(UserData u) => '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();

  Future<void> _export(List<_Line> lines) async {
    final month = DateFormat('MMMM yyyy').format(_monthDay);
    await saveAndLaunchFile(
      payrollXlsx(month: month, lines: [
        for (final l in lines) (name: _name(l.user), currency: l.currency, pay: l.pay)
      ]),
      'payroll_${DateFormat('yyyy-MM').format(_monthDay)}.xlsx',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String h(int minutes) => localizedDuration(l, Duration(minutes: minutes));
    return FutureBuilder<List<_Line>>(
      future: _lines,
      builder: (context, snap) {
        final lines = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(l.payroll),
            actions: [
              IconButton(
                tooltip: l.export,
                onPressed: lines == null ? null : () => _export(lines),
                icon: const Icon(Icons.ios_share),
              ),
            ],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(spacing: 8, children: [
                for (final last in [false, true])
                  ChoiceChip(
                    label: Text(last ? l.lastMonth : l.thisMonth),
                    selected: _lastMonth == last,
                    onSelected: (_) => setState(() {
                      _lastMonth = last;
                      _lines = _load();
                    }),
                  ),
              ]),
            ),
            Expanded(
              child: snap.hasError
                  ? Center(child: Text(l.couldNotLoad))
                  : lines == null
                      ? const Center(child: Loading())
                      : lines.isEmpty
                          ? Center(
                              child: Text(l.noPayrollYet,
                                  style: const TextStyle(color: AppColors.muted)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount: lines.length,
                              itemBuilder: (context, i) {
                                final line = lines[i];
                                final pay = line.pay;
                                return Card(
                                  child: ListTile(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => UserAdminScreen(
                                                user: line.user, viewer: widget.viewer))),
                                    title: Text(_name(line.user)),
                                    subtitle: Text(pay == null
                                        ? l.noPayDetails
                                        : [
                                            '${l.regularTime} ${h(pay.regularMinutes)}',
                                            if (pay.approvedOvertimeMinutes > 0)
                                              '${l.approvedOvertime} ${h(pay.approvedOvertimeMinutes)}',
                                            if (pay.pendingOvertimeMinutes > 0)
                                              '${l.overtimeWaitingHr} ${h(pay.pendingOvertimeMinutes)}',
                                          ].join(' · ')),
                                    trailing: pay == null
                                        ? null
                                        : Text(money(pay.total, line.currency),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700, fontSize: 15)),
                                  ),
                                );
                              },
                            ),
            ),
          ]),
        );
      },
    );
  }
}
