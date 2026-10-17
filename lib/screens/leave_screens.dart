import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/leave.dart';
import '../models/payslip.dart';
import '../models/salary.dart';
import '../models/user_model.dart';
import '../services/leave_service.dart';
import '../services/pay_service.dart';
import '../services/payroll_service.dart';
import '../shared/loading.dart';
import '../widgets/status_widgets.dart';

String _fullName(UserData u) => '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();

String _errorText(AppLocalizations l, LeaveError e) => switch (e) {
      LeaveError.denied => l.leaveDenied,
      LeaveError.upload => l.reportUploadFailed,
      LeaveError.failed => l.couldNotSaveTryAgain,
    };

void _showError(BuildContext context, LeaveError e) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.bad, content: Text(_errorText(context.l10n, e))));

/// "Sun 5 Oct – Tue 7 Oct · 3 days".
String _period(AppLocalizations l, LeaveRequest r, int offDay) {
  final f = DateFormat('EEE d MMM', l.localeName);
  final dates = r.from == r.to ? f.format(r.from) : '${f.format(r.from)} – ${f.format(r.to)}';
  return '$dates · ${l.daysCount(r.days(offDay).length)}';
}

Tone _tone(LeaveStatus s) => switch (s) {
      LeaveStatus.pending => Tone.warn,
      LeaveStatus.approved => Tone.ok,
      LeaveStatus.rejected => Tone.bad,
      LeaveStatus.cancelled => Tone.neutral,
    };

Future<void> _openReport(BuildContext context, LeaveReport report) async {
  try {
    final url = await LeaveService.reportUrl(report);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.bad, content: Text(context.l10n.couldNotLoad)));
  }
}

/// Annual and emergency days left this year, and sick days used.
class LeaveBalances extends StatelessWidget {
  const LeaveBalances({super.key, required this.requests, required this.package});
  final List<LeaveRequest> requests;
  final SalaryPackage package;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final year = DateTime.now().year;
    Widget tile(LeaveType type) {
      final b = leaveBalance(type, year, requests, package);
      return Expanded(
        child: Column(children: [
          Text('${b.left}',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: b.left <= 0 ? AppColors.bad : AppColors.charcoal)),
          Text(type.short(l),
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(l.daysLeftOf(b.allowance),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          if (b.pending > 0)
            Text(l.daysWaiting(b.pending),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.warn)),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.leaveThisYear(year), style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final t in LeaveType.values) tile(t),
      ]),
      const SizedBox(height: 10),
      Text(l.sickPayRuleFor(package.sickFullDays, package.sickHalfDays),
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ]);
  }
}

/// One request in a list: type, dates, status and HR's answer.
class _RequestCard extends StatelessWidget {
  const _RequestCard(this.r, {required this.offDay, this.title, this.extra = const []});
  final LeaveRequest r;
  final int offDay;
  final String? title;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final muted = const TextStyle(fontSize: 12, color: AppColors.muted);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title ?? r.type.localized(l),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            StatusPill(r.status.localized(l), tone: _tone(r.status)),
          ]),
          const SizedBox(height: 4),
          if (title != null)
            Text(r.type.localized(l), style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(_period(l, r, offDay)),
          if (r.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.reason, style: const TextStyle(color: AppColors.ink)),
          ],
          if (r.isApproved && !r.isSick) ...[
            const SizedBox(height: 6),
            StatusPill(r.paid ? l.paidLeave : l.unpaidLeave,
                tone: r.paid ? Tone.ok : Tone.neutral),
          ],
          if (r.byName != null && r.status != LeaveStatus.pending &&
              r.status != LeaveStatus.cancelled) ...[
            const SizedBox(height: 6),
            Text(
                l.decidedBy(r.byName!,
                    r.at == null ? '' : DateFormat('d MMM', l.localeName).format(r.at!)),
                style: muted),
          ],
          if (r.note?.isNotEmpty == true) Text(r.note!, style: muted),
          if (!r.isSick) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(r.travel == null ? Icons.home_outlined : Icons.flight_takeoff,
                  size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(r.travel == null
                    ? l.noTravel
                    : '${l.travelLine(r.travel!.from, r.travel!.to)} · '
                        '${r.travel!.companyTicket ? l.companyTicket : l.ownTicket}'),
              ),
            ]),
          ],
          if (r.reports.isNotEmpty)
            Wrap(spacing: 4, children: [
              for (final (i, report) in r.reports.indexed)
                TextButton.icon(
                  onPressed: () => _openReport(context, report),
                  icon: Icon(report.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined),
                  label: Text(r.reports.length == 1 ? l.viewReport : l.reportN(i + 1)),
                ),
            ]),
          ...extra,
        ]),
      ),
    );
  }
}

/// The worker's leave: balances, a button to ask for leave, and their
/// requests (pending ones can be cancelled).
class MyLeaveScreen extends StatelessWidget {
  const MyLeaveScreen({super.key, required this.user});
  final UserData user;

  Future<void> _cancel(BuildContext context, LeaveRequest r) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.cancelLeaveTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.cancelRequest)),
        ],
      ),
    );
    if (ok != true) return;
    final error = await LeaveService.cancel(r);
    if (error != null && context.mounted) _showError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.myLeave)),
      body: StreamBuilder<SalaryPackage?>(
        stream: PayrollService.watch(user.uid!),
        builder: (context, pkgSnap) {
          // Without a package (or before payroll rules allow it) the
          // allowances read as 0 and Sunday is the day off.
          final p = pkgSnap.data ?? const SalaryPackage();
          return StreamBuilder<List<LeaveRequest>>(
            stream: LeaveService.watchMine(user.uid!),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text(l.couldNotLoad));
              if (!snap.hasData) return const Center(child: Loading());
              final requests = snap.data!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LeaveBalances(requests: requests, package: p),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                LeaveRequestScreen(user: user, package: p, existing: requests))),
                    icon: const Icon(Icons.add),
                    label: Text(l.requestLeave),
                  ),
                  SectionTitle(l.myRequests),
                  if (requests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l.noLeaveRequests,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted)),
                    ),
                  for (final r in requests)
                    _RequestCard(r, offDay: p.weeklyOffDay, extra: [
                      if (r.isPending)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.bad),
                            onPressed: () => _cancel(context, r),
                            child: Text(l.cancelRequest),
                          ),
                        ),
                    ]),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// The worker asks for annual or emergency leave (saying whether they
/// travel, where, and who buys the ticket), or reports sick leave with the
/// hospital report (one or more files).
class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen(
      {super.key, required this.user, required this.package, required this.existing});
  final UserData user;
  final SalaryPackage package;
  final List<LeaveRequest> existing;

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  LeaveType _type = LeaveType.annual;
  DateTimeRange? _range;
  final _reason = TextEditingController();
  final List<PickedReport> _reports = [];

  /// Annual/emergency: null until answered.
  bool? _travel;
  bool? _companyTicket;
  final _travelFrom = TextEditingController();
  final _travelTo = TextEditingController();
  bool _saving = false;

  int get _room => maxLeaveReports - _reports.length;

  List<DateTime> get _days =>
      _range == null ? const [] : leaveDaysIn(_range!.start, _range!.end, widget.package.weeklyOffDay);

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      // Sick and emergency leave are often reported afterwards.
      firstDate: DateTime(now.year, now.month - 2, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  Future<void> _takePhoto() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.camera, maxWidth: 2000, imageQuality: 85);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() => _reports.add((name: img.name, contentType: 'image/jpeg', bytes: bytes)));
  }

  Future<void> _pickPhotos() async {
    final imgs = await ImagePicker().pickMultiImage(maxWidth: 2000, imageQuality: 85);
    final added = <PickedReport>[
      for (final img in imgs.take(_room))
        (name: img.name, contentType: 'image/jpeg', bytes: await img.readAsBytes())
    ];
    setState(() => _reports.addAll(added));
  }

  Future<void> _pickPdfs() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    final added = <PickedReport>[
      for (final f in files.take(_room))
        (name: f.name, contentType: 'application/pdf', bytes: await f.readAsBytes())
    ];
    setState(() => _reports.addAll(added));
  }

  /// A yes/no question as two segments; nothing is picked until answered.
  Widget _yesNo(bool? value, ValueChanged<bool> onChanged) {
    final l = context.l10n;
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(value: true, label: Text(l.answerYes)),
        ButtonSegment(value: false, label: Text(l.answerNo)),
      ],
      selected: {if (value != null) value},
      emptySelectionAllowed: true,
      onSelectionChanged: (s) {
        if (s.isNotEmpty) setState(() => onChanged(s.first));
      },
    );
  }

  /// Why the request can't be sent yet, or null.
  String? _problem(AppLocalizations l) {
    if (_range == null) return l.pickLeaveDates;
    final days = _days;
    if (days.isEmpty) return l.leaveOnlyDayOff;
    if (_range!.end.difference(_range!.start).inDays >= maxLeaveDays) {
      return l.leaveTooLong(maxLeaveDays);
    }
    final overlaps = widget.existing.any((r) =>
        (r.isPending || r.isApproved) && r.overlaps(_range!.start, _range!.end));
    if (overlaps) return l.leaveOverlaps;
    if (_type == LeaveType.sick) {
      if (_reports.isEmpty) return l.reportNeeded;
      if (_reports.any((r) => r.bytes.length >= 10 * 1024 * 1024)) return l.reportTooBig;
    } else {
      if (_travel == null) return l.answerTravel;
      if (_travel == true &&
          (_travelFrom.text.trim().isEmpty ||
              _travelTo.text.trim().isEmpty ||
              _companyTicket == null)) {
        return l.answerTravel;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_problem(l) != null) return;
    setState(() => _saving = true);
    final error = await LeaveService.submit(
      LeaveRequest(
        uid: widget.user.uid!,
        name: _fullName(widget.user),
        type: _type,
        from: _range!.start,
        to: _range!.end,
        reason: _reason.text.trim(),
        travel: _type != LeaveType.sick && _travel == true
            ? LeaveTravel(_travelFrom.text.trim(), _travelTo.text.trim(), _companyTicket!)
            : null,
      ),
      _days.length,
      reports: _type == LeaveType.sick ? _reports : const [],
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) return _showError(context, error);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.ok, content: Text(l.leaveSent)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final days = _days.length;
    final problem = _problem(l);
    final balance = leaveBalance(
        _type, (_range?.start ?? DateTime.now()).year, widget.existing, widget.package);
    final f = DateFormat('EEE d MMM yyyy', l.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(l.requestLeave)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<LeaveType>(
            segments: [
              for (final t in LeaveType.values)
                ButtonSegment(value: t, label: Text(t.short(l))),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDates,
            child: InputDecorator(
              decoration: InputDecoration(
                  labelText: l.leaveDates, suffixIcon: const Icon(Icons.date_range)),
              child: Text(_range == null
                  ? l.pickLeaveDates
                  : '${f.format(_range!.start)} – ${f.format(_range!.end)}'),
            ),
          ),
          if (_range != null) ...[
            const SizedBox(height: 6),
            Text(l.leaveDaysNote(days, weekdayName(widget.package.weeklyOffDay, l.localeName)),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
          const SizedBox(height: 6),
          Text(l.daysLeftThisYear(_type.localized(l), balance.left),
              style: TextStyle(
                  fontSize: 13, color: days > balance.left ? AppColors.warn : AppColors.muted)),
          if (days > balance.left)
            Text(l.overBalance, style: const TextStyle(fontSize: 12, color: AppColors.warn)),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.leaveReason),
          ),
          if (_type != LeaveType.sick) ...[
            SectionTitle(l.travel),
            Text(l.travelQuestion),
            const SizedBox(height: 8),
            _yesNo(_travel, (v) => _travel = v),
            if (_travel == true) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _travelFrom,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.travelFrom),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _travelTo,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.travelTo),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Text(l.ticketQuestion),
              const SizedBox(height: 8),
              _yesNo(_companyTicket, (v) => _companyTicket = v),
            ],
          ],
          if (_type == LeaveType.sick) ...[
            SectionTitle(l.hospitalReport),
            Text(l.hospitalReportHint, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            for (final (i, report) in _reports.indexed)
              Card(
                child: ListTile(
                  leading: Icon(report.contentType == 'application/pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined),
                  title: Text(report.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _reports.removeAt(i)),
                  ),
                ),
              ),
            if (_room > 0)
              Wrap(spacing: 8, runSpacing: 8, children: [
                ActionChip(
                    avatar: const Icon(Icons.photo_camera_outlined),
                    label: Text(l.takePhoto),
                    onPressed: _takePhoto),
                ActionChip(
                    avatar: const Icon(Icons.photo_library_outlined),
                    label: Text(l.chooseFromGallery),
                    onPressed: _pickPhotos),
                ActionChip(
                    avatar: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(l.choosePdf),
                    onPressed: _pickPdfs),
              ]),
            const SizedBox(height: 6),
            Text(l.reportFilesLimit(maxLeaveReports),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
          const SizedBox(height: 20),
          if (problem != null && _range != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(problem, style: const TextStyle(color: AppColors.bad)),
            ),
          FilledButton(
            onPressed: _saving || problem != null ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(l.sendRequest),
          ),
        ],
      ),
    );
  }
}

/// One request as HR reviews it.
class _Row {
  final LeaveRequest r;
  final SalaryPackage package;

  /// The worker's other requests (for balances and sick tiers).
  final List<LeaveRequest> all;

  /// A month it touches is approved (payslip locked): no more changes.
  final bool locked;
  const _Row(this.r, this.package, this.all, this.locked);
}

/// Requests HR works with: every pending one, and decided ones from the
/// start of last month (and the whole year, for balances).
Future<List<_Row>> _loadRequests() async {
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1);
  final yearStart = DateTime(now.year);
  final since = lastMonth.isBefore(yearStart) ? lastMonth : yearStart;
  final (workers, pkgs) =
      await (LeaveService.everyoneSince(since), PayService.packages()).wait;
  final rows = <_Row>[];
  final slips = <String, Future<Payslip?>>{};
  Future<Payslip?> slip(String uid, String month) => slips.putIfAbsent('${uid}_$month', () {
        final [m, y] = month.split('-').map(int.parse).toList();
        return PayService.payslipFor(uid, DateTime(y, m));
      });
  for (final MapEntry(key: uid, value: list) in workers.entries) {
    for (final r in list) {
      if (r.status == LeaveStatus.cancelled) continue;
      if (!r.isPending && r.to.isBefore(lastMonth)) continue;
      final locked = (await Future.wait(r.months.map((m) => slip(uid, m))))
          .any((s) => s?.isLocked == true);
      rows.add(_Row(r, pkgs[uid] ?? const SalaryPackage(), list, locked));
    }
  }
  rows.sort((a, b) => b.r.from.compareTo(a.r.from));
  return rows;
}

/// HR and admins: leave requests to approve or reject.
class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key, required this.viewer});
  final UserData viewer;

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  late Future<List<_Row>> _rows = _loadRequests();

  void _reload() => setState(() {
        _rows = _loadRequests();
      });

  Future<void> _decide(_Row row, LeaveStatus status) async {
    final l = context.l10n;
    final r = row.r;
    final note = TextEditingController(text: r.note);
    var paid = r.isApproved ? r.paid : true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(status == LeaveStatus.approved ? l.approveLeaveTitle : l.rejectLeaveTitle),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (status == LeaveStatus.approved && !r.isSick)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.paidLeave),
                subtitle: Text(paid ? l.paidLeaveHint : l.unpaidLeaveHint),
                value: paid,
                onChanged: (v) => setDialog(() => paid = v),
              ),
            if (status == LeaveStatus.approved && r.isSick)
              Text(l.sickPayRuleFor(row.package.sickFullDays, row.package.sickHalfDays),
                  style: const TextStyle(color: AppColors.muted)),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: l.notesOptional),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(status == LeaveStatus.approved ? l.approve : l.reject)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final error = await LeaveService.decide(r,
        status: status,
        paid: paid,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
        byName: _fullName(widget.viewer));
    if (!mounted) return;
    if (error != null) return _showError(context, error);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tabs = [LeaveStatus.pending, LeaveStatus.approved, LeaveStatus.rejected];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.leaveRequests),
          bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: AppColors.gold,
              tabs: [for (final s in tabs) Tab(text: s.localized(l))]),
        ),
        body: FutureBuilder<List<_Row>>(
          future: _rows,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text(l.couldNotLoad));
            if (!snap.hasData) return const Center(child: Loading());
            return TabBarView(children: [
              for (final s in tabs)
                _RequestList(
                    rows: snap.data!.where((x) => x.r.status == s).toList(), onDecide: _decide),
            ]);
          },
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.rows, required this.onDecide});
  final List<_Row> rows;
  final void Function(_Row, LeaveStatus) onDecide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (rows.isEmpty) {
      return Center(
          child: Text(l.noLeaveRequests, style: const TextStyle(color: AppColors.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        final r = row.r;
        final others = [for (final x in row.all) if (x.id != r.id) x];
        final b = leaveBalance(r.type, r.from.year, others, row.package);
        return _RequestCard(r, offDay: row.package.weeklyOffDay, title: r.name, extra: [
          const SizedBox(height: 4),
          Text(l.daysLeftThisYear(r.type.localized(l), b.left),
              style: TextStyle(
                  fontSize: 12,
                  color: r.days(row.package.weeklyOffDay).length > b.left
                      ? AppColors.warn
                      : AppColors.muted)),
          if (row.locked) ...[
            const SizedBox(height: 8),
            StatusPill(l.payslipApproved, tone: Tone.ok, icon: Icons.lock_outline),
          ] else ...[
            const SizedBox(height: 10),
            // The theme's buttons are full width, so each takes half.
            Row(children: [
              if (r.status != LeaveStatus.rejected)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.bad),
                    onPressed: () => onDecide(row, LeaveStatus.rejected),
                    child: Text(l.reject),
                  ),
                ),
              if (r.isPending) const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.ok),
                  onPressed: () => onDecide(row, LeaveStatus.approved),
                  // Approved annual/emergency can be switched paid ↔ unpaid.
                  child: Text(r.isApproved ? l.change : l.approve),
                ),
              ),
            ]),
          ],
        ]);
      },
    );
  }
}

/// Leave on the worker's page (HR and admins): balances, recent requests,
/// and the button to set their entitlement.
class WorkerLeaveCard extends StatelessWidget {
  const WorkerLeaveCard({super.key, required this.user});
  final UserData user;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<SalaryPackage?>(
      stream: PayrollService.watch(user.uid!),
      builder: (context, pkgSnap) {
        final p = pkgSnap.data ?? const SalaryPackage();
        return StreamBuilder<List<LeaveRequest>>(
          stream: LeaveService.watchMine(user.uid!),
          builder: (context, snap) {
            final requests = snap.data;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: snap.hasError
                    ? Text(l.couldNotLoad, style: const TextStyle(color: AppColors.muted))
                    : requests == null
                        ? const Center(child: CircularProgressIndicator())
                        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            LeaveBalances(requests: requests, package: p),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          LeaveEntitlementScreen(user: user, initial: p))),
                              icon: const Icon(Icons.edit_calendar_outlined),
                              label: Text(l.setLeaveEntitlement),
                            ),
                            for (final r in requests
                                .where((r) => r.status != LeaveStatus.cancelled)
                                .take(3)) ...[
                              const Divider(height: 20),
                              Row(children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.type.localized(l),
                                            style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(_period(l, r, p.weeklyOffDay),
                                            style: const TextStyle(
                                                fontSize: 12, color: AppColors.muted)),
                                      ]),
                                ),
                                StatusPill(r.status.localized(l), tone: _tone(r.status)),
                              ]),
                            ],
                          ]),
              ),
            );
          },
        );
      },
    );
  }
}

/// HR and admins: how much leave a worker is entitled to each year, with a
/// button that fills in what the UAE law gives (annual from the start date;
/// sick 15 days full pay, 30 half, 45 unpaid).
class LeaveEntitlementScreen extends StatefulWidget {
  const LeaveEntitlementScreen({super.key, required this.user, required this.initial});
  final UserData user;
  final SalaryPackage initial;

  @override
  State<LeaveEntitlementScreen> createState() => _LeaveEntitlementScreenState();
}

class _LeaveEntitlementScreenState extends State<LeaveEntitlementScreen> {
  final _form = GlobalKey<FormState>();
  late DateTime? _joinDate = widget.initial.joinDate;
  late int _offDay = widget.initial.weeklyOffDay;
  late final _annual = _ctrl(widget.initial.annualLeaveDays);
  late final _emergency = _ctrl(widget.initial.emergencyLeaveDays);
  late final _sickFull = _ctrl(widget.initial.sickFullDays);
  late final _sickHalf = _ctrl(widget.initial.sickHalfDays);
  late final _sickUnpaid = _ctrl(widget.initial.sickUnpaidDays);
  bool _saving = false;

  static TextEditingController _ctrl(int v) => TextEditingController(text: '$v');
  static int _n(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _useLaw() {
    final l = context.l10n;
    final annual = lawAnnualLeaveDays(_joinDate, DateTime.now());
    setState(() {
      if (annual != null) _annual.text = '$annual';
      _sickFull.text = '${SalaryPackage.lawSickFull}';
      _sickHalf.text = '${SalaryPackage.lawSickHalf}';
      _sickUnpaid.text = '${SalaryPackage.lawSickUnpaid}';
    });
    if (annual == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.setStartDateForLaw)));
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await PayrollService.save(
        widget.user.uid!,
        widget.initial.withLeave(
          annualLeaveDays: _n(_annual),
          emergencyLeaveDays: _n(_emergency),
          weeklyOffDay: _offDay,
          sickFullDays: _n(_sickFull),
          sickHalfDays: _n(_sickHalf),
          sickUnpaidDays: _n(_sickUnpaid),
          joinDate: _joinDate,
        ));
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(backgroundColor: AppColors.bad, content: Text(error)));
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.ok, content: Text(l.leaveEntitlementSaved)));
  }

  Widget _days(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label, suffixText: context.l10n.daysAYear),
          onChanged: (_) => setState(() {}),
          validator: (v) =>
              (int.tryParse((v ?? '').trim()) ?? 0) > 366 ? context.l10n.enterValidDays : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final law = lawAnnualLeaveDays(_joinDate, DateTime.now());
    final date = DateFormat('d MMM yyyy', l.localeName);
    final muted = const TextStyle(fontSize: 12, color: AppColors.muted);
    return Scaffold(
      appBar: AppBar(title: Text(l.leaveEntitlementFor(_fullName(widget.user)))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _joinDate ?? DateTime.now(),
                  firstDate: DateTime(1980),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _joinDate = d);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                    labelText: l.startDate, suffixIcon: const Icon(Icons.event)),
                child: Text(_joinDate == null ? l.notSet : date.format(_joinDate!)),
              ),
            ),
            const SizedBox(height: 6),
            Text(law == null ? l.setStartDateForLaw : l.lawAnnualToday(law), style: muted),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _useLaw,
              icon: const Icon(Icons.gavel_outlined),
              label: Text(l.useUaeLaw),
            ),
            SectionTitle(l.vacation),
            _days(_annual, l.leaveAnnual),
            _days(_emergency, l.leaveEmergency),
            Text(l.annualLawNote, style: muted),
            SectionTitle(l.leaveSick),
            _days(_sickFull, l.sickFullPayDays),
            _days(_sickHalf, l.sickHalfPayDays),
            _days(_sickUnpaid, l.sickUnpaidDays),
            Text(l.sickLawNote, style: muted),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _offDay,
              decoration:
                  InputDecoration(labelText: l.weeklyDayOff, helperText: l.weeklyDayOffHint),
              items: [
                for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                  DropdownMenuItem(value: d, child: Text(weekdayName(d, l.localeName))),
              ],
              onChanged: (d) => setState(() => _offDay = d ?? _offDay),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
