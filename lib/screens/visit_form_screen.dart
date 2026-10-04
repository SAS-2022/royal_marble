import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/app_theme.dart';
import '../core/error_reporter.dart';
import '../core/format.dart';
import '../core/locale_controller.dart';
import '../core/roles.dart';
import '../models/business_model.dart';
import '../models/sales_visit.dart';
import '../models/user_model.dart';
import '../services/database.dart';
import 'client_form_screen.dart';
import 'visits_screen.dart' show purposeLabel, visitKindIcon;

/// Something a visit can be about: a client or a project.
class _Target {
  final VisitKind kind;
  final String id;
  final String name;
  final String? subtitle;
  final String? contact;
  const _Target(this.kind, this.id, this.name, this.subtitle, this.contact);

  _Target.client(ClientData c)
      : this(VisitKind.client, c.uid!, c.name,
            prettyAddress(c.clientAddress?['addressName']), c.contactPerson);
  _Target.project(ProjectData p)
      : this(VisitKind.project, p.uid!, p.projectName ?? '',
            prettyAddress(p.projectAddress?['addressName']), p.contactPerson);
}

/// Records a sales visit in two steps on one page: (1) the client or project
/// visited, (2) contact, purpose and notes. The time defaults to now and can
/// be set back up to a week, for visits written up later.
class VisitFormScreen extends StatefulWidget {
  const VisitFormScreen({super.key, required this.currentUser, this.initialClient});
  final UserData currentUser;
  final ClientData? initialClient;

  @override
  State<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends State<VisitFormScreen> {
  final _form = GlobalKey<FormState>();
  final _db = DatabaseService();
  late final bool _admin = primaryRole(widget.currentUser.roles) == AppRole.admin;
  late final _clients =
      _db.streamClients(ownerId: _admin ? null : widget.currentUser.uid);
  late final _projects = _db.getAllProjects();

  late VisitKind _kind = VisitKind.client;
  late _Target? _target =
      widget.initialClient == null ? null : _Target.client(widget.initialClient!);
  late final _contact = TextEditingController(text: _target?.contact);
  final _notes = TextEditingController();
  String? _purpose;
  DateTime _time = DateTime.now();
  bool _timeEdited = false;
  bool _tried = false;
  bool _saving = false;

  @override
  void dispose() {
    _contact.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setTarget(_Target? t) {
    setState(() {
      // Fill the contact unless the salesperson already typed another one.
      if (_contact.text.trim().isEmpty || _contact.text == _target?.contact) {
        _contact.text = t?.contact ?? '';
      }
      _target = t;
    });
  }

  Future<void> _choose(List<_Target> options) async {
    final picked = await showModalBottomSheet<_Target>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TargetPicker(
        kind: _kind,
        options: options,
        onAddClient: _kind == VisitKind.client ? _addClient : null,
      ),
    );
    if (picked != null) _setTarget(picked);
  }

  Future<_Target?> _addClient() async {
    final c = await Navigator.push<ClientData>(
        context,
        MaterialPageRoute(
            builder: (_) => ClientFormScreen(ownerId: widget.currentUser.uid!)));
    return c == null ? null : _Target.client(c);
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _time,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now,
    );
    if (day == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_time));
    if (t == null) return;
    var picked = DateTime(day.year, day.month, day.day, t.hour, t.minute);
    if (picked.isAfter(now)) picked = now;
    setState(() {
      _time = picked;
      _timeEdited = true;
    });
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _tried = true);
    final valid = _form.currentState!.validate();
    if (!valid || _target == null || _purpose == null) return;
    setState(() => _saving = true);
    try {
      await _db.addSalesVisit(SalesVisit(
        userId: widget.currentUser.uid!,
        kind: _target!.kind,
        targetId: _target!.id,
        targetName: _target!.name,
        contact: _contact.text.trim(),
        purpose: _purpose,
        details: _notes.text.trim(),
        time: _timeEdited ? _time : DateTime.now(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.ok, content: Text(l.visitSaved)));
      Navigator.pop(context, true);
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.bad, content: Text(l.visitSaveFailed)));
    }
  }

  Widget _stepTitle(int n, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
        child: Row(children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.charcoal,
            child: Text('$n',
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _targetStep(List<ClientData>? clients, List<ProjectData>? projects) {
    final l = context.l10n;
    final options = _kind == VisitKind.client
        ? [
            for (final c in clients ?? const <ClientData>[])
              if (c.error == null) _Target.client(c)
          ]
        : [
            for (final p in projects ?? const <ProjectData>[])
              if (p.error == null && p.projectStatus != 'closed') _Target.project(p)
          ];
    options.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final missing = _tried && _target == null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedButton<VisitKind>(
        segments: [
          ButtonSegment(
              value: VisitKind.client,
              icon: Icon(visitKindIcon(VisitKind.client), size: 18),
              label: Text(l.clientWord)),
          ButtonSegment(
              value: VisitKind.project,
              icon: Icon(visitKindIcon(VisitKind.project), size: 18),
              label: Text(l.projectWord)),
        ],
        selected: {_kind},
        onSelectionChanged: (v) {
          if (v.first == _kind) return;
          _kind = v.first;
          _setTarget(null);
        },
      ),
      const SizedBox(height: 10),
      Card(
        shape: missing
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.bad))
            : null,
        child: ListTile(
          onTap: () => _choose(options),
          leading: CircleAvatar(
            backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            child: Icon(visitKindIcon(_kind), color: AppColors.goldDeep),
          ),
          title: Text(
              _target?.name ??
                  (_kind == VisitKind.client ? l.chooseClient : l.chooseProject),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _target == null ? AppColors.muted : null)),
          subtitle: missing
              ? Text(l.required, style: const TextStyle(color: AppColors.bad))
              : (_target?.subtitle?.isNotEmpty == true
                  ? Text(_target!.subtitle!,
                      maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null),
          trailing: const Icon(Icons.unfold_more),
        ),
      ),
    ]);
  }

  Widget _detailsStep() {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(
        controller: _contact,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
            labelText: l.metWith, prefixIcon: const Icon(Icons.person_outline)),
        validator: (v) => v == null || v.trim().isEmpty ? l.required : null,
      ),
      const SizedBox(height: 14),
      Text(l.visitPurpose, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 6, children: [
        for (final p in visitPurposes)
          ChoiceChip(
            label: Text(purposeLabel(l, p)),
            selected: _purpose == p,
            onSelected: (_) => setState(() => _purpose = p),
          ),
      ]),
      if (_tried && _purpose == null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(l.choosePurpose,
              style: const TextStyle(color: AppColors.bad, fontSize: 12)),
        ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _notes,
        textCapitalization: TextCapitalization.sentences,
        minLines: 4,
        maxLines: 10,
        decoration: InputDecoration(
          labelText: l.visitNotes,
          hintText: l.visitNotesHint,
          alignLabelWithHint: true,
        ),
        validator: (v) {
          final n = (v ?? '').trim().length;
          return n >= minVisitNotes ? null : l.notesTooShort(minVisitNotes, n);
        },
      ),
      const SizedBox(height: 10),
      Card(
        child: ListTile(
          leading: const Icon(Icons.schedule),
          title: Text(l.visitTime),
          subtitle: Text(_timeEdited
              ? DateFormat('EEEE d MMM, HH:mm', l.localeName).format(_time)
              : l.rightNow),
          trailing: TextButton(onPressed: _pickTime, child: Text(l.change)),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.newVisit)),
      body: StreamBuilder<List<ClientData>>(
        stream: _clients,
        builder: (context, c) => StreamBuilder<List<ProjectData>>(
          stream: _projects,
          builder: (context, p) => Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                _stepTitle(1, l.visitStepWho),
                _targetStep(c.data, p.data),
                _stepTitle(2, l.visitStepWhat),
                _detailsStep(),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.check),
                  label: Text(l.saveVisit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Searchable list of clients or projects, with "Add client" at the top.
class _TargetPicker extends StatefulWidget {
  const _TargetPicker({required this.kind, required this.options, this.onAddClient});
  final VisitKind kind;
  final List<_Target> options;
  final Future<_Target?> Function()? onAddClient;

  @override
  State<_TargetPicker> createState() => _TargetPickerState();
}

class _TargetPickerState extends State<_TargetPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final q = _q.toLowerCase();
    final shown = widget.options
        .where((t) =>
            q.isEmpty ||
            t.name.toLowerCase().contains(q) ||
            (t.subtitle ?? '').toLowerCase().contains(q) ||
            (t.contact ?? '').toLowerCase().contains(q))
        .toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: widget.options.length > 8,
            decoration: InputDecoration(
              hintText: widget.kind == VisitKind.client
                  ? l.searchClients
                  : l.searchSites,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        if (widget.onAddClient != null)
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: AppColors.charcoal,
                child: Icon(Icons.person_add_alt, color: Colors.white)),
            title: Text(l.addClient,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () async {
              final t = await widget.onAddClient!();
              if (t != null && context.mounted) Navigator.pop(context, t);
            },
          ),
        const Divider(),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(
                      widget.kind == VisitKind.client
                          ? l.noClientsFound
                          : l.noSitesFound,
                      style: const TextStyle(color: AppColors.muted)))
              : ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final t = shown[i];
                    return ListTile(
                      leading: Icon(visitKindIcon(t.kind), color: AppColors.goldDeep),
                      title: Text(t.name),
                      subtitle: t.subtitle?.isNotEmpty == true
                          ? Text(t.subtitle!,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      onTap: () => Navigator.pop(context, t),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

