import 'package:cloud_firestore/cloud_firestore.dart';

/// What a salesperson visited. Each kind lives in its own sub-collection of
/// `users/{uid}`, which the Sales activity report and older app versions read.
enum VisitKind { client, project }

extension VisitKindStore on VisitKind {
  String get collection =>
      this == VisitKind.client ? 'clientVisits' : 'projectVisits';
}

/// Visit purposes as stored. They stay in English (office records, and older
/// app versions show them as they are); the app shows them translated.
const visitPurposes = [
  'Collecting payment',
  'Requesting payment',
  'New order',
  'Order follow up',
  'Quotation follow up',
  'Sample Submission',
  'Handling complaint',
  'Presenting new product',
  'Project discussion',
  'New client',
  're-establishing business',
  'Catching up visit',
  'Others...',
];

/// Notes shorter than this don't say what happened at the visit.
const minVisitNotes = 20;

/// One visit, from `users/{uid}/clientVisits|projectVisits/{id}`:
/// `{uid (client or project id), name, contact, visitPurpose, visitDetails,
/// visitTime, userId, managerComments}`.
class SalesVisit {
  final String id;
  final String userId;
  final VisitKind kind;
  final String? targetId;
  final String targetName;
  final String? contact;
  final String? purpose;
  final String details;
  final String? managerComments;
  final DateTime? time;

  const SalesVisit({
    this.id = '',
    required this.userId,
    required this.kind,
    this.targetId,
    required this.targetName,
    this.contact,
    this.purpose,
    this.details = '',
    this.managerComments,
    this.time,
  });

  bool get hasComment => managerComments?.trim().isNotEmpty == true;

  factory SalesVisit.fromMap(
      VisitKind kind, String id, String ownerId, Map<String, dynamic> d) {
    final t = d['visitTime'];
    return SalesVisit(
      id: id,
      // Visits always sit under their owner; the field is a copy.
      userId: ownerId,
      kind: kind,
      targetId: d['uid'] as String?,
      targetName: '${d['name'] ?? ''}',
      contact: d['contact'] as String?,
      purpose: d['visitPurpose'] as String?,
      details: '${d['visitDetails'] ?? ''}',
      managerComments: d['managerComments'] as String?,
      time: t is Timestamp
          ? t.toDate()
          : t is DateTime
              ? t
              : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': targetId,
        'name': targetName,
        'contact': contact,
        'visitPurpose': purpose,
        'visitDetails': details,
        'visitTime': time,
        'userId': userId,
      };
}
