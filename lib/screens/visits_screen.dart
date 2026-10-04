import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/app_theme.dart';
import '../core/locale_controller.dart';
import '../core/roles.dart';
import '../l10n/app_localizations.dart';
import '../models/sales_visit.dart';
import '../models/user_model.dart';
import '../services/database.dart';
import '../shared/loading.dart';
import '../widgets/status_widgets.dart';
import 'visit_details_screen.dart';
import 'visit_form_screen.dart';

/// A stored purpose in the reader's language; unknown ones show as stored.
String purposeLabel(AppLocalizations l, String? stored) => switch (stored) {
      'Collecting payment' => l.purposeCollectPayment,
      'Requesting payment' => l.purposeRequestPayment,
      'New order' => l.purposeNewOrder,
      'Order follow up' => l.purposeOrderFollowUp,
      'Quotation follow up' => l.purposeQuotationFollowUp,
      'Sample Submission' => l.purposeSamples,
      'Handling complaint' => l.purposeComplaint,
      'Presenting new product' => l.purposeNewProduct,
      'Project discussion' => l.purposeProjectDiscussion,
      'New client' => l.purposeNewClient,
      're-establishing business' => l.purposeReestablish,
      'Catching up visit' => l.purposeCatchUp,
      'Others...' => l.purposeOther,
      _ => stored ?? '',
    };

IconData visitKindIcon(VisitKind k) =>
    k == VisitKind.client ? Icons.storefront_outlined : Icons.apartment;

/// Both kinds of one salesperson's visits between [from] and [to], newest
/// first. Streams are only re-opened when the person or range changes.
class VisitsBuilder extends StatefulWidget {
  const VisitsBuilder(
      {super.key,
      required this.userId,
      required this.from,
      required this.to,
      required this.builder});
  final String userId;
  final DateTime from;
  final DateTime to;
  final Widget Function(BuildContext context, List<SalesVisit>? visits) builder;

  @override
  State<VisitsBuilder> createState() => _VisitsBuilderState();
}

class _VisitsBuilderState extends State<VisitsBuilder> {
  late Stream<List<SalesVisit>> _clients;
  late Stream<List<SalesVisit>> _projects;

  void _open() {
    final db = DatabaseService();
    _clients = db.streamVisits(widget.userId, VisitKind.client,
        from: widget.from, to: widget.to);
    _projects = db.streamVisits(widget.userId, VisitKind.project,
        from: widget.from, to: widget.to);
  }

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(VisitsBuilder old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId ||
        old.from != widget.from ||
        old.to != widget.to) {
      _open();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: _clients,
        builder: (context, c) => StreamBuilder(
          stream: _projects,
          builder: (context, p) {
            if (c.hasError || p.hasError) return widget.builder(context, const []);
            if (!c.hasData || !p.hasData) return widget.builder(context, null);
            final all = [...c.data!, ...p.data!]..sort(
                (a, b) => (b.time ?? DateTime(0)).compareTo(a.time ?? DateTime(0)));
            return widget.builder(context, all);
          },
        ),
      );
}

/// One visit in a list: what was visited, why, when, and the start of the
/// notes. [showDate] adds the day (for lists not grouped by day).
class VisitTile extends StatelessWidget {
  const VisitTile(
      {super.key, required this.visit, required this.viewer, this.showDate = false});
  final SalesVisit visit;
  final UserData viewer;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = visit.time;
    final when = t == null
        ? ''
        : DateFormat(showDate ? 'd MMM, HH:mm' : 'HH:mm', l.localeName).format(t);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      VisitDetailsScreen(visit: visit, currentUser: viewer))),
          leading: CircleAvatar(
            backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            child: Icon(visitKindIcon(visit.kind), color: AppColors.goldDeep),
          ),
          title: Text(visit.targetName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text([purposeLabel(l, visit.purpose), when]
                .where((s) => s.isNotEmpty)
                .join(' · ')),
            if (visit.details.isNotEmpty)
              Text(visit.details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted)),
          ]),
          trailing: visit.hasComment
              ? Tooltip(
                  message: l.managerComment,
                  child: const Icon(Icons.comment_outlined, color: AppColors.goldDeep))
              : null,
        ),
      ),
    );
  }
}

enum _Period { week, thisMonth, lastMonth, custom }

/// A salesperson's visits over a period, grouped by day. Admins choose whose
/// visits to see; everyone else sees their own.
class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key, required this.currentUser});
  final UserData currentUser;

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  late final bool _admin = primaryRole(widget.currentUser.roles) == AppRole.admin;
  late String _userId = widget.currentUser.uid!;
  late final _salesUsers = DatabaseService().getSalesUsers();
  bool _pickedPerson = false;
  _Period _period = _Period.week;
  DateTimeRange? _custom;
  VisitKind? _kind;

  bool get _own => _userId == widget.currentUser.uid;

  ({DateTime from, DateTime to}) get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return switch (_period) {
      _Period.week => (from: today.subtract(const Duration(days: 6)), to: tomorrow),
      _Period.thisMonth => (from: DateTime(now.year, now.month), to: tomorrow),
      _Period.lastMonth => (
          from: DateTime(now.year, now.month - 1),
          to: DateTime(now.year, now.month)
        ),
      _Period.custom => (
          from: _custom!.start,
          to: _custom!.end.add(const Duration(days: 1))
        ),
    };
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: now,
      initialDateRange: _custom,
    );
    if (r != null) {
      setState(() {
        _custom = r;
        _period = _Period.custom;
      });
    }
  }

  String _periodLabel(_Period p) {
    final l = context.l10n;
    return switch (p) {
      _Period.week => l.last7Days,
      _Period.thisMonth => l.thisMonth,
      _Period.lastMonth => l.lastMonth,
      _Period.custom => _custom == null
          ? l.customRange
          : '${DateFormat('d MMM', l.localeName).format(_custom!.start)} – '
              '${DateFormat('d MMM', l.localeName).format(_custom!.end)}',
    };
  }

  Widget _personPicker(List<UserData> sales) {
    final l = context.l10n;
    final people = [
      widget.currentUser,
      ...sales.where((u) => u.uid != widget.currentUser.uid),
    ];
    return DropdownButtonFormField<String>(
      initialValue: _userId,
      isExpanded: true,
      decoration: InputDecoration(
          labelText: l.salesperson,
          prefixIcon: const Icon(Icons.badge_outlined),
          isDense: true),
      items: [
        for (final u in people)
          DropdownMenuItem(
            value: u.uid,
            child: Text(u.uid == widget.currentUser.uid
                ? l.meLabel
                : '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim()),
          ),
      ],
      onChanged: (v) => setState(() {
        _userId = v!;
        _pickedPerson = true;
      }),
    );
  }

  Widget _filters() {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 6, children: [
        for (final p in _Period.values)
          ChoiceChip(
            label: Text(_periodLabel(p)),
            selected: _period == p,
            onSelected: (_) => p == _Period.custom
                ? _pickCustom()
                : setState(() => _period = p),
          ),
      ]),
      const SizedBox(height: 10),
      SegmentedButton<VisitKind?>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: null, label: Text(l.everything)),
          ButtonSegment(
              value: VisitKind.client,
              icon: Icon(visitKindIcon(VisitKind.client), size: 18),
              label: Text(l.clients)),
          ButtonSegment(
              value: VisitKind.project,
              icon: Icon(visitKindIcon(VisitKind.project), size: 18),
              label: Text(l.projectsLabel)),
        ],
        selected: {_kind},
        onSelectionChanged: (v) => setState(() => _kind = v.first),
      ),
    ]);
  }

  Widget _list(List<SalesVisit>? all) {
    final l = context.l10n;
    final header = <Widget>[
      if (_admin)
        StreamBuilder<List<UserData>>(
          stream: _salesUsers,
          builder: (context, s) {
            final sales = s.data ?? const <UserData>[];
            // Admins mostly look at the sales team: start on the first one.
            if (!_pickedPerson && sales.isNotEmpty && _own &&
                !sales.any((u) => u.uid == widget.currentUser.uid)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_pickedPerson) {
                  setState(() {
                    _userId = sales.first.uid!;
                    _pickedPerson = true;
                  });
                }
              });
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _personPicker(sales),
            );
          },
        ),
      _filters(),
    ];
    if (all == null) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        ...header,
        const Padding(padding: EdgeInsets.only(top: 60), child: Loading()),
      ]);
    }
    final shown = all.where((v) => _kind == null || v.kind == _kind).toList();
    final clients = shown.where((v) => v.kind == VisitKind.client).length;
    final days = <DateTime, List<SalesVisit>>{};
    for (final v in shown) {
      final t = v.time ?? DateTime(0);
      days.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(v);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        ...header,
        const SizedBox(height: 12),
        Text(l.visitsSummary(shown.length, clients, shown.length - clients),
            style: const TextStyle(color: AppColors.muted)),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
              child: Text(l.noVisitsInPeriod,
                  style: const TextStyle(color: AppColors.muted)),
            ),
          ),
        for (final e in days.entries) ...[
          SectionTitle(DateFormat('EEEE d MMMM', l.localeName).format(e.key),
              trailing: Text('${e.value.length}',
                  style: const TextStyle(color: AppColors.muted))),
          for (final v in e.value) VisitTile(visit: v, viewer: widget.currentUser),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = _range;
    return Scaffold(
      appBar: AppBar(title: Text(_own ? l.myVisits : l.visits)),
      floatingActionButton: _own
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          VisitFormScreen(currentUser: widget.currentUser))),
              icon: const Icon(Icons.add),
              label: Text(l.newVisit),
            )
          : null,
      body: VisitsBuilder(
        userId: _userId,
        from: r.from,
        to: r.to,
        builder: (context, visits) => _list(visits),
      ),
    );
  }
}
