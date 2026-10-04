import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/app_theme.dart';
import '../core/error_reporter.dart';
import '../core/locale_controller.dart';
import '../core/roles.dart';
import '../models/sales_visit.dart';
import '../models/user_model.dart';
import '../services/database.dart';
import '../widgets/status_widgets.dart';
import 'clients_screen.dart' show ClientDetailsScreen;
import 'visits_screen.dart' show purposeLabel, visitKindIcon;

/// One visit. The salesperson can correct their own contact, purpose and
/// notes; an admin adds a manager comment, which the salesperson then sees.
class VisitDetailsScreen extends StatefulWidget {
  const VisitDetailsScreen(
      {super.key, required this.visit, required this.currentUser});
  final SalesVisit visit;
  final UserData currentUser;

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  final _form = GlobalKey<FormState>();
  late SalesVisit _v = widget.visit;
  late final bool _owner = _v.userId == widget.currentUser.uid;
  late final bool _admin =
      primaryRole(widget.currentUser.roles) == AppRole.admin;
  bool _editing = false;
  bool _saving = false;

  late final _contact = TextEditingController(text: _v.contact);
  late final _notes = TextEditingController(text: _v.details);
  late final _comment = TextEditingController(text: _v.managerComments);
  late String? _purpose = _v.purpose;

  @override
  void dispose() {
    for (final c in [_contact, _notes, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(Map<String, dynamic> fields) async {
    final l = context.l10n;
    setState(() => _saving = true);
    try {
      await DatabaseService().updateSalesVisit(_v, fields);
      if (!mounted) return;
      setState(() {
        _v = SalesVisit(
          id: _v.id,
          userId: _v.userId,
          kind: _v.kind,
          targetId: _v.targetId,
          targetName: _v.targetName,
          time: _v.time,
          contact: fields['contact'] ?? _v.contact,
          purpose: fields['visitPurpose'] ?? _v.purpose,
          details: fields['visitDetails'] ?? _v.details,
          managerComments: fields['managerComments'] ?? _v.managerComments,
        );
        _editing = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.ok, content: Text(l.visitSaved)));
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.bad, content: Text(l.visitSaveFailed)));
    }
  }

  void _saveOwnEdits() {
    if (!_form.currentState!.validate()) return;
    _save({
      'contact': _contact.text.trim(),
      'visitPurpose': _purpose,
      'visitDetails': _notes.text.trim(),
    });
  }

  Widget _row(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon),
        title: Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        subtitle: Text(value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 15, color: AppColors.ink)),
      );

  Widget _readView() {
    final l = context.l10n;
    return Card(
      child: Column(children: [
        _row(Icons.person_outline, l.metWith, _v.contact ?? ''),
        const Divider(),
        _row(Icons.flag_outlined, l.visitPurpose, purposeLabel(l, _v.purpose)),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.visitNotes,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 4),
            SelectableText(_v.details.isEmpty ? '—' : _v.details,
                style: const TextStyle(fontSize: 15, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _editView() {
    final l = context.l10n;
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
          for (final p in {...visitPurposes, if (_purpose != null) _purpose!})
            ChoiceChip(
              label: Text(purposeLabel(l, p)),
              selected: _purpose == p,
              onSelected: (_) => setState(() => _purpose = p),
            ),
        ]),
        const SizedBox(height: 14),
        TextFormField(
          controller: _notes,
          textCapitalization: TextCapitalization.sentences,
          minLines: 4,
          maxLines: 10,
          decoration: InputDecoration(
              labelText: l.visitNotes, alignLabelWithHint: true),
          validator: (v) {
            final n = (v ?? '').trim().length;
            return n >= minVisitNotes ? null : l.notesTooShort(minVisitNotes, n);
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _saveOwnEdits,
          icon: const Icon(Icons.save),
          label: Text(l.saveChanges),
        ),
      ]),
    );
  }

  Widget _commentCard() {
    final l = context.l10n;
    if (_admin) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _comment,
              minLines: 2,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  hintText: l.managerCommentHint, alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _saving ||
                        _comment.text.trim() == (_v.managerComments ?? '').trim()
                    ? null
                    : () => _save({'managerComments': _comment.text.trim()}),
                icon: const Icon(Icons.send),
                label: Text(l.saveComment),
              ),
            ),
          ]),
        ),
      );
    }
    return Card(
      color: AppColors.warnSoft,
      child: ListTile(
        leading: const Icon(Icons.comment_outlined, color: AppColors.goldDeep),
        title: Text(_v.hasComment ? _v.managerComments! : l.noManagerComment,
            style: TextStyle(color: _v.hasComment ? AppColors.ink : AppColors.muted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = _v.time;
    final client = _v.kind == VisitKind.client && _v.targetId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.visitDetails),
        actions: [
          if (_owner && !_editing)
            IconButton(
              tooltip: l.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
          if (_editing)
            IconButton(
              tooltip: l.cancel,
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _editing = false),
            ),
        ],
      ),
      // Rebuild so the comment button enables as the admin types.
      body: ListenableBuilder(
        listenable: _comment,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: ListTile(
                onTap: client
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ClientDetailsScreen(
                                clientId: _v.targetId!,
                                currentUser: widget.currentUser)))
                    : null,
                leading: CircleAvatar(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                  child: Icon(visitKindIcon(_v.kind), color: AppColors.goldDeep),
                ),
                title: Text(_v.targetName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                subtitle: Text(t == null
                    ? ''
                    : DateFormat('EEEE d MMMM yyyy, HH:mm', l.localeName).format(t)),
                trailing: client ? const Icon(Icons.chevron_right) : null,
              ),
            ),
            SectionTitle(l.visitStepWhat),
            _editing ? _editView() : _readView(),
            SectionTitle(l.managerComment),
            _commentCard(),
          ],
        ),
      ),
    );
  }
}
