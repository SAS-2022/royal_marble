import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/error_reporter.dart';
import '../core/locale_controller.dart';
import '../models/user_model.dart';
import '../services/database.dart';
import 'status_widgets.dart';

/// A mason works with at most this many helpers.
const maxHelpers = 2;

/// A mason's helpers (people without the app who work alongside them).
/// Managers can assign, add, edit and delete helpers; the mason sees theirs.
class HelpersCard extends StatelessWidget {
  const HelpersCard({super.key, required this.mason, required this.canManage});
  final UserData mason;
  final bool canManage;

  List<String> get _assigned =>
      [for (final h in mason.assingedHelpers ?? const []) '$h'];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<Helpers>>(
      stream: DatabaseService().streamAllHelpers(),
      builder: (context, snap) {
        final all = snap.data ?? const <Helpers>[];
        final mine = [for (final h in all) if (_assigned.contains(h.uid)) h];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionTitle(l.helpersCount(mine.length),
              trailing: canManage
                  ? TextButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) =>
                            _ManageHelpersSheet(mason: mason, assigned: _assigned),
                      ),
                      icon: const Icon(Icons.group_add_outlined, size: 18),
                      label: Text(l.manage),
                    )
                  : null),
          Card(
            child: mine.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(snap.hasData ? l.noHelpers : '…',
                        style: const TextStyle(color: AppColors.muted)),
                  )
                : Column(children: [
                    for (final (i, h) in mine.indexed) ...[
                      if (i > 0) const Divider(indent: 16, endIndent: 16),
                      _HelperTile(h),
                    ],
                  ]),
          ),
        ]);
      },
    );
  }
}

class _HelperTile extends StatelessWidget {
  const _HelperTile(this.h, {this.trailing});
  final Helpers h;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final phone = h.mobileNumber?.trim() ?? '';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.gold.withValues(alpha: 0.2),
        child: const Icon(Icons.handyman_outlined, color: AppColors.goldDeep),
      ),
      title: Text('${h.firstName ?? ''} ${h.lastName ?? ''}'.trim()),
      subtitle: phone.isEmpty
          ? null
          : Text(phone, textDirection: TextDirection.ltr),
      trailing: trailing ??
          (phone.isEmpty
              ? null
              : IconButton(
                  tooltip: context.l10n.callAction,
                  icon: const Icon(Icons.call, color: AppColors.ok),
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                )),
    );
  }
}

class _ManageHelpersSheet extends StatefulWidget {
  const _ManageHelpersSheet({required this.mason, required this.assigned});
  final UserData mason;
  final List<String> assigned;

  @override
  State<_ManageHelpersSheet> createState() => _ManageHelpersSheetState();
}

class _ManageHelpersSheetState extends State<_ManageHelpersSheet> {
  late final Set<String> _selected = widget.assigned.toSet();
  final _db = DatabaseService();
  String _query = '';
  bool _saving = false;

  void _toggle(String id, bool on) {
    if (on && _selected.length >= maxHelpers) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.helpersMax(maxHelpers))));
      return;
    }
    setState(() => on ? _selected.add(id) : _selected.remove(id));
  }

  Future<void> _edit([Helpers? h]) async {
    final saved = await showDialog<bool>(
        context: context, builder: (_) => _HelperDialog(helper: h));
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _delete(Helpers h) async {
    final l = context.l10n;
    final name = '${h.firstName ?? ''} ${h.lastName ?? ''}'.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteHelperTitle(name)),
        content: Text(l.deleteHelperBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.bad),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _db.deleteHelperEverywhere(h.uid!);
    if (mounted) setState(() => _selected.remove(h.uid));
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _saving = true);
    final result = await _db.updateUserWithHelpers(
        uid: widget.mason.uid, helpers: _selected.toList());
    if (!mounted) return;
    Navigator.pop(context);
    final ok = result == 'Completed';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: ok ? AppColors.ok : AppColors.bad,
        content: Text(ok ? l.helpersSaved : l.helpersSaveFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = '${widget.mason.firstName ?? ''} ${widget.mason.lastName ?? ''}'.trim();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(children: [
            Expanded(
              child: Text(l.helpersOf(name),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Text('${_selected.length}/$maxHelpers',
                style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                    hintText: l.searchPeople,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: l.addHelper,
              onPressed: () => _edit(),
              icon: const Icon(Icons.person_add_alt),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<Helpers>>(
            stream: _db.streamAllHelpers(),
            builder: (context, snap) {
              final list = [
                for (final h in snap.data ?? const <Helpers>[])
                  if ('${h.firstName} ${h.lastName} ${h.mobileNumber}'
                      .toLowerCase()
                      .contains(_query))
                    h
              ]..sort((a, b) {
                  final sa = _selected.contains(a.uid) ? 0 : 1;
                  final sb = _selected.contains(b.uid) ? 0 : 1;
                  return sa != sb ? sa - sb : '${a.firstName}'.compareTo('${b.firstName}');
                });
              if (snap.hasData && list.isEmpty) {
                return Center(
                    child: Text(l.noHelpersYet,
                        style: const TextStyle(color: AppColors.muted)));
              }
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final h = list[i];
                  final selected = _selected.contains(h.uid);
                  return Row(children: [
                    Checkbox(
                        value: selected, onChanged: (v) => _toggle(h.uid!, v!)),
                    Expanded(
                      child: InkWell(
                        onTap: () => _toggle(h.uid!, !selected),
                        child: _HelperTile(h, trailing: const SizedBox.shrink()),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) => v == 'edit' ? _edit(h) : _delete(h),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l.edit)),
                        PopupMenuItem(value: 'delete', child: Text(l.delete)),
                      ],
                    ),
                  ]);
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(l.saveHelpers),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Add or edit one helper's name and mobile number.
class _HelperDialog extends StatefulWidget {
  const _HelperDialog({this.helper});
  final Helpers? helper;

  @override
  State<_HelperDialog> createState() => _HelperDialogState();
}

class _HelperDialogState extends State<_HelperDialog> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.helper?.firstName);
  late final _last = TextEditingController(text: widget.helper?.lastName);
  late final _phone = TextEditingController(text: widget.helper?.mobileNumber);
  bool _saving = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final db = DatabaseService();
    try {
      widget.helper == null
          ? await db.addNewHelper(
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              mobileNumber: _phone.text.trim())
          : await db.updateHelper(
              uid: widget.helper!.uid,
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              mobileNumber: _phone.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.helper == null ? l.addHelper : l.editHelper),
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _first,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.firstName),
            validator: (v) => (v ?? '').trim().isEmpty ? l.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _last,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.lastName),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
                labelText: l.mobileNumber, hintText: '05X XXX XXXX'),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
            onPressed: _saving ? null : _save, child: Text(l.save)),
      ],
    );
  }
}
