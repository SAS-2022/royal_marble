import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:printing/printing.dart';

import '../core/app_theme.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../core/roles.dart';
import '../services/database.dart';
import '../shared/save_launch_file.dart';
import '../screens/attendance_edit_screen.dart';
import '../widgets/status_widgets.dart';
import 'report_data.dart';
import 'report_export.dart';

enum ReportKind { attendance, sales }

enum _ViewBy { person, day, site }

String _siteKey(AttendanceRow r) => r.siteId.isEmpty ? r.project : r.siteId;

String _rolePlural(AppLocalizations l, AppRole? r) => switch (r) {
      null => l.everyone,
      AppRole.worker => l.rolesMasons,
      AppRole.siteEngineer => l.rolesSiteEngineers,
      AppRole.supervisor => l.rolesSupervisors,
      _ => r.localized(l),
    };

enum _Preset { today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth, custom }

extension on _Preset {
  String label(AppLocalizations l) => switch (this) {
        _Preset.today => l.today,
        _Preset.yesterday => l.yesterday,
        _Preset.thisWeek => l.thisWeek,
        _Preset.lastWeek => l.lastWeek,
        _Preset.thisMonth => l.thisMonth,
        _Preset.lastMonth => l.lastMonth,
        _Preset.custom => l.customRange,
      };

  DateTimeRange? range() {
    final now = dayOnly(DateTime.now());
    // Weeks start on Monday.
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return switch (this) {
      _Preset.today => DateTimeRange(start: now, end: now),
      _Preset.yesterday => DateTimeRange(
          start: now.subtract(const Duration(days: 1)),
          end: now.subtract(const Duration(days: 1))),
      _Preset.thisWeek => DateTimeRange(start: monday, end: now),
      _Preset.lastWeek => DateTimeRange(
          start: monday.subtract(const Duration(days: 7)),
          end: monday.subtract(const Duration(days: 1))),
      _Preset.thisMonth =>
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      _Preset.lastMonth => DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0)),
      _Preset.custom => null,
    };
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen(
      {super.key, this.initial = ReportKind.attendance, this.canCorrect = false});
  final ReportKind initial;

  /// Admins can open a worker's day from the report to fix or approve it.
  final bool canCorrect;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late ReportKind _kind = widget.initial;
  _Preset _preset = _Preset.thisWeek;
  DateTimeRange _range = _Preset.thisWeek.range()!;
  AppRole? _role = AppRole.worker;
  _ViewBy _viewBy = _ViewBy.person;

  /// Site filter ([_siteKey]); null shows every site.
  String? _site;

  bool _loading = false;
  String? _error;
  List<AttendanceRow> _rows = [];
  List<SalesSummary> _sales = [];

  static const _roleChoices = [
    AppRole.worker,
    AppRole.siteEngineer,
    AppRole.supervisor,
    null,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_kind == ReportKind.attendance) {
        _rows = await loadAttendance(_range, _role);
        if (_site != null && !_rows.any((r) => _siteKey(r) == _site)) {
          _site = null;
        }
      } else {
        final salesUsers = await DatabaseService().getSalesUsers().first;
        _sales = await loadSales(salesUsers, _range);
      }
    } catch (e) {
      _error = 'load';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickPreset(_Preset p) async {
    var range = p.range();
    if (p == _Preset.custom) {
      range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2022),
        lastDate: DateTime.now(),
        initialDateRange: _range,
      );
      if (range == null) return;
    }
    setState(() {
      _preset = p;
      _range = range!;
    });
    _load();
  }

  List<AttendanceRow> get _visible =>
      _site == null ? _rows : _rows.where((r) => _siteKey(r) == _site).toList();

  String get _title {
    if (_kind != ReportKind.attendance) return 'Sales activity';
    final site = _site == null
        ? null
        : _rows.firstWhere((r) => _siteKey(r) == _site).project;
    return 'Attendance${_role == null ? '' : ' – ${_role!.label}s'}'
        '${site == null ? '' : ' – $site'}';
  }

  Future<void> _openDay(AttendanceRow r) async {
    if (!widget.canCorrect) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AttendanceEditScreen(day: r.day, uid: r.uid, name: r.name)));
    if (mounted) _load();
  }

  String get _fileStem =>
      '${_kind.name}_${DateFormat('yyyyMMdd').format(_range.start)}-${DateFormat('yyyyMMdd').format(_range.end)}';

  Future<void> _export() async {
    final rows = _visible;
    final empty =
        _kind == ReportKind.attendance ? rows.isEmpty : _sales.isEmpty;
    if (empty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.nothingToExport)));
      return;
    }
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.bad),
            title: const Text('PDF'),
            subtitle: Text(context.l10n.pdfSubtitle),
            onTap: () async {
              Navigator.pop(sheet);
              final bytes = _kind == ReportKind.attendance
                  ? await attendancePdf(title: _title, range: _range, rows: rows)
                  : await salesPdf(range: _range, sales: _sales);
              await Printing.sharePdf(bytes: bytes, filename: '$_fileStem.pdf');
            },
          ),
          if (_kind == ReportKind.attendance)
            ListTile(
              leading: const Icon(Icons.table_chart_outlined, color: AppColors.ok),
              title: const Text('Excel'),
              subtitle: Text(context.l10n.excelSubtitle),
              onTap: () async {
                Navigator.pop(sheet);
                await saveAndLaunchFile(
                    attendanceXlsx(range: _range, rows: rows),
                    '$_fileStem.xlsx');
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM', context.l10n.localeName);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.sectionReports),
        actions: [
          IconButton(
            tooltip: context.l10n.export,
            onPressed: _loading ? null : _export,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: Column(children: [
        // Controls
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SegmentedButton<ReportKind>(
              segments: [
                ButtonSegment(
                    value: ReportKind.attendance,
                    icon: Icon(Icons.schedule),
                    label: Text(context.l10n.attendance)),
                ButtonSegment(
                    value: ReportKind.sales,
                    icon: Icon(Icons.storefront),
                    label: Text(context.l10n.sectionSales)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) {
                setState(() => _kind = s.first);
                _load();
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in _Preset.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p == _Preset.custom && _preset == p
                            ? '${fmt.format(_range.start)} – ${fmt.format(_range.end)}'
                            : p.label(context.l10n)),
                        selected: _preset == p,
                        onSelected: (_) => _pickPreset(p),
                      ),
                    ),
                ],
              ),
            ),
            if (_kind == ReportKind.attendance) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final r in _roleChoices)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_rolePlural(context.l10n, r)),
                          selected: _role == r,
                          onSelected: (_) {
                            setState(() => _role = r);
                            _load();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (!_loading && totalsBySite(_rows).length > 1)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final (key, label) in [
                        (null, context.l10n.allSites),
                        for (final t in totalsBySite(_rows)
                          ..sort((a, b) => a.name.compareTo(b.name)))
                          (t.key, t.name),
                      ])
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            avatar: key == null
                                ? null
                                : const Icon(Icons.apartment, size: 16),
                            label: Text(label),
                            selected: _site == key,
                            onSelected: (_) => setState(() => _site = key),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ]),
        ),
        const Divider(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : _error != null
                  ? Center(child: Text(context.l10n.reportLoadError, style: const TextStyle(color: AppColors.bad)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _kind == ReportKind.attendance
                          ? _attendanceBody()
                          : _salesBody(),
                    ),
        ),
      ]),
    );
  }

  // ───────────── attendance ─────────────

  Widget _attendanceBody() {
    final rows = _visible;
    final people = totalsByPerson(rows);
    final total = people.fold(Duration.zero, (t, p) => t + p.worked);
    final area = people.fold(0.0, (t, p) => t + p.squareMeters);
    final missing = rows.where((r) => r.missingCheckOut).length;
    final review = rows.where((r) => r.needsReview && !r.missingCheckOut).length;

    Widget banner(String text) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.warnSoft, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: AppColors.warn),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(text, style: const TextStyle(color: AppColors.ink))),
            ]),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(children: [
          Expanded(child: _Stat(context.l10n.people, '${people.length}', Icons.groups)),
          const SizedBox(width: 8),
          Expanded(child: _Stat(context.l10n.hours, '${total.inHours}', Icons.timer_outlined)),
          const SizedBox(width: 8),
          Expanded(
              child: _Stat(context.l10n.areaM2, area == 0 ? '–' : area.toStringAsFixed(0),
                  Icons.square_foot)),
        ]),
        if (missing > 0) banner(context.l10n.missingCheckouts(missing)),
        if (review > 0)
          banner(widget.canCorrect
              ? context.l10n.autoCheckoutsToReviewTap(review)
              : context.l10n.autoCheckoutsToReview(review)),
        const SizedBox(height: 12),
        Row(children: [
          Text(context.l10n.viewBy.toUpperCase(),
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted)),
          const Spacer(),
          SegmentedButton<_ViewBy>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: _ViewBy.person, label: Text(context.l10n.person)),
              ButtonSegment(value: _ViewBy.day, label: Text(context.l10n.day)),
              ButtonSegment(value: _ViewBy.site, label: Text(context.l10n.site)),
            ],
            selected: {_viewBy},
            onSelectionChanged: (s) => setState(() => _viewBy = s.first),
          ),
        ]),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(context.l10n.noAttendance,
                  style: TextStyle(color: AppColors.muted)),
            ),
          )
        else
          ...switch (_viewBy) {
            _ViewBy.person => [
                for (final p in people) _PersonCard(p, onTapRow: _openDay)
              ],
            _ViewBy.day => [
                for (final d in daysIn(_range).reversed)
                  if (rows.any((r) => r.day == d))
                    _DayCard(d, rows.where((r) => r.day == d).toList(),
                        onTapRow: _openDay),
              ],
            _ViewBy.site => [
                for (final t in totalsBySite(rows)) _SiteCard(t, onTapRow: _openDay)
              ],
          },
      ],
    );
  }

  // ───────────── sales ─────────────

  Widget _salesBody() {
    if (_sales.isEmpty) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Center(
              child: Text(context.l10n.noSalesTeam,
                  style: TextStyle(color: AppColors.muted))),
        ),
      ]);
    }
    final visits = _sales.fold(0, (t, s) => t + s.totalVisits);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(children: [
          Expanded(child: _Stat(context.l10n.salespeople, '${_sales.length}', Icons.badge_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _Stat(context.l10n.visits, '$visits', Icons.handshake_outlined)),
        ]),
        const SizedBox(height: 12),
        for (final s in _sales)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                title: Text('${s.user.firstName ?? ''} ${s.user.lastName ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    context.l10n.salesSummary(s.workingDays, s.clientVisits.length, s.projectVisits.length)),
                children: [
                  if (s.totalVisits == 0)
                    ListTile(title: Text(context.l10n.noVisits)),
                  for (final v in s.clientVisits)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(v.clientName ?? context.l10n.client),
                      subtitle: Text(v.visitPurpose ?? ''),
                      trailing: Text('${v.visitTime}'),
                    ),
                  for (final v in s.projectVisits)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.apartment_outlined),
                      title: Text(v.projectName ?? context.l10n.project),
                      subtitle: Text(v.visitPurpose ?? ''),
                      trailing: Text('${v.visitTime}'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 20, color: AppColors.goldDeep),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      );
}

String _hm(DateTime? d) => d == null ? '—' : DateFormat('HH:mm').format(d);

class _EntryRow extends StatelessWidget {
  const _EntryRow(this.r, {required this.leading, this.onTap});
  final AttendanceRow r;
  final String leading;
  final ValueChanged<AttendanceRow>? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 5,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(leading, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                [
                  r.project,
                  if (r.workType != null) r.workType!,
                  if (r.squareMeters != null)
                    '${r.squareMeters!.toStringAsFixed(1)} m²',
                  if (r.away.inMinutes > 0)
                    l.awayFor(localizedDuration(l, r.away)),
                ].join(' · '),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              if (r.autoReason != null || r.corrected)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(spacing: 6, children: [
                    if (r.autoReason != null)
                      StatusPill(
                          r.autoReason == 'left_site'
                              ? l.autoLeftSiteShort
                              : l.autoEndOfDayShort,
                          tone: r.reviewed ? Tone.neutral : Tone.warn,
                          icon: Icons.timer_off),
                    if (r.corrected)
                      StatusPill(l.editedByAdmin, icon: Icons.edit_note),
                  ]),
                ),
            ]),
          ),
          Expanded(
            flex: 3,
            // Times read left to right even in Arabic and Urdu.
            child: Text(
                '${_hm(r.arrived)} → ${r.stillOnSite ? l.nowLabel : _hm(r.left)}',
                textAlign: Directionality.of(context) == TextDirection.rtl
                    ? TextAlign.left
                    : TextAlign.right,
                textDirection: TextDirection.ltr),
          ),
          SizedBox(
            width: 70,
            child: r.worked != null
                ? Text(localizedDuration(l, r.worked!),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700))
                : Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: StatusPill(r.stillOnSite ? l.onSite : l.noOut,
                        tone: r.stillOnSite ? Tone.ok : Tone.warn),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard(this.p, {this.onTapRow});
  final AttendanceTotals p;
  final ValueChanged<AttendanceRow>? onTapRow;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            shape: const Border(),
            leading: CircleAvatar(
              backgroundColor: AppColors.gold.withValues(alpha: 0.2),
              child: Text(
                  p.name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.goldDeep)),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
                '${context.l10n.daysCount(p.days)} · ${localizedDuration(context.l10n, p.worked)}'
                '${p.squareMeters > 0 ? ' · ${p.squareMeters.toStringAsFixed(1)} m²' : ''}'),
            trailing: p.missingCheckOuts > 0
                ? StatusPill(context.l10n.noOutCount(p.missingCheckOuts),
                    tone: Tone.warn)
                : null,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              for (final r in p.rows)
                _EntryRow(r,
                    onTap: onTapRow,
                    leading: DateFormat('EEE d MMM', context.l10n.localeName)
                        .format(r.day)),
            ],
          ),
        ),
      );
}

class _DayCard extends StatelessWidget {
  const _DayCard(this.day, this.rows, {this.onTapRow});
  final DateTime day;
  final List<AttendanceRow> rows;
  final ValueChanged<AttendanceRow>? onTapRow;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Text(DateFormat('EEEE d MMMM', context.l10n.localeName).format(day),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(context.l10n.peopleCount(rows.map((r) => r.uid).toSet().length),
                    style: const TextStyle(color: AppColors.muted)),
              ]),
              const Divider(height: 16),
              for (final r in rows) _EntryRow(r, leading: r.name, onTap: onTapRow),
            ]),
          ),
        ),
      );
}

/// Hours at one site: people, days and total, expanding to each stay.
class _SiteCard extends StatelessWidget {
  const _SiteCard(this.t, {this.onTapRow});
  final AttendanceTotals t;
  final ValueChanged<AttendanceRow>? onTapRow;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          leading: CircleAvatar(
            backgroundColor: AppColors.gold.withValues(alpha: 0.2),
            child: const Icon(Icons.apartment, color: AppColors.goldDeep),
          ),
          title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text([
            l.peopleCount(t.people),
            l.daysCount(t.days),
            localizedDuration(l, t.worked),
            if (t.squareMeters > 0) '${t.squareMeters.toStringAsFixed(1)} m²',
          ].join(' · ')),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            for (final r in t.rows)
              _EntryRow(r,
                  onTap: onTapRow,
                  leading:
                      '${DateFormat('EEE d MMM', l.localeName).format(r.day)} · ${r.name}'),
          ],
        ),
      ),
    );
  }
}
