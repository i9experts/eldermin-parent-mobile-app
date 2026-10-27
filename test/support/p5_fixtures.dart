import 'dart:async';
import 'p4_fixtures.dart';

/// Sentinel data for the P5 screens: every Map key the views read carries a DISTINCT value, so a test can prove each key is
/// still rendered (or used) after the layout changes. Dates are fixed (UTC midnight, formatted as the views do).

// ---- PTM (ptm_screen.dart) ----
const ptmMeetingId = 'MEET-ID-701';
List<dynamic> ptmRows() => [
      {
        '_id': ptmMeetingId,
        'teacherName': 'TeacherSentinelOne',
        'status': 'requested',
        'scheduledDate': '2026-11-05T00:00:00.000Z',
        'startTime': '10:15',
        'endTime': '10:45',
        'discussionPoints': ['PointSentinelA', 'PointSentinelB'],
        'meetingNotes': 'NotesSentinel',
        'actionItems': [
          {'description': 'ActionSentinelDone', 'status': 'done'},
          {'description': 'ActionSentinelOpen', 'status': 'open'},
        ],
      },
      {'_id': 'MEET-ID-702', 'teacherName': 'TeacherSentinelTwo', 'status': 'no_show', 'scheduledDate': '2026-10-01T00:00:00.000Z'},
      {'_id': 'MEET-ID-703', 'teacherName': 'TeacherSentinelThree', 'status': 'completed', 'scheduledDate': '2026-09-20T00:00:00.000Z', 'startTime': '09:00'},
      {'_id': 'MEET-ID-704', 'teacherName': 'TeacherSentinelFour', 'status': 'confirmed', 'scheduledDate': '2026-11-09T00:00:00.000Z'},
    ];

List<dynamic> ptmTeacherRows() => [
      {'teacherId': 'TID-SENT-9', 'teacherName': 'PickTeacherSent', 'subjects': ['SubjSentA', 'SubjSentB']},
      {'teacherId': 'TID-SENT-8', 'teacherName': 'SecondTeacherSent', 'subjects': []},
    ];

// ---- Leaves (leaves_screen.dart) ----
List<dynamic> leaveRows() => [
      {'status': 'approved', 'fromDate': '2026-11-02T00:00:00.000Z', 'toDate': '2026-11-04T00:00:00.000Z', 'reason': 'ReasonSentinelApproved', 'approverName': 'ApproverSentinel', 'approverNote': 'ApproverNoteSentinel'},
      {'status': 'pending', 'fromDate': '2026-11-10T00:00:00.000Z', 'toDate': '2026-11-10T00:00:00.000Z', 'reason': 'ReasonSentinelPending', 'approverName': 'HiddenApprover', 'approverNote': 'HiddenNote'},
      {'status': 'rejected', 'fromDate': '2026-10-05T00:00:00.000Z', 'toDate': '2026-10-06T00:00:00.000Z', 'reason': 'ReasonSentinelRejected', 'approverNote': 'RejectNoteSentinel'},
    ];

// ---- Profile (profile_screen.dart) ----
Map<String, dynamic> profileBody() => {
      'firstName': 'FirstSent',
      'lastName': 'LastSent',
      'currentGrade': 'GradeSent',
      'currentSection': 'SecSent',
      'currentRollNumber': 'RollSent',
      'status': 'active',
      'dateOfBirth': '2015-03-04T00:00:00.000Z',
      'medical': {'bloodGroup': 'BGSent'},
      'guardians': [
        {'name': 'GuardianSentOne', 'relation': 'RelationSent', 'phone': 'PhoneSent', 'isPrimary': true},
        {'name': 'GuardianSentTwo', 'relation': 'RelTwoSent'},
      ],
      'documents': [{}, {}, {}],
      'photoUrl': 'https://example.com/PhotoSent.png',
      'admissionNumber': 'AdmissionSent',
      'gender': 'GenderSent',
      'houseGroup': 'HouseSent',
      'classTeacher': 'ClassTeacherSent',
    };

// ---- Dues (dues_screen.dart) ----
List<dynamic> dueRows() => [
      {'invoiceNumber': 'INV-SENT-1', 'balanceDue': 1500, 'paidAmount': 500, 'lateFine': 75, 'dueDate': '2026-11-10T00:00:00.000Z', 'academicYear': '2026-27'},
      {'invoiceNumber': 'INV-SENT-2', 'balanceDue': '0', 'paidAmount': '2000', 'lateFine': 0, 'dueDate': '2026-09-01T00:00:00.000Z', 'academicYear': '2026-27'},
      {'invoiceNumber': 'INV-SENT-3', 'balanceDue': 250.5, 'paidAmount': 0, 'lateFine': '10', 'dueDate': '2026-12-31T00:00:00.000Z'},
    ];

/// The fake API for the P5 screens (falls back to the P4 answers).
FutureOr<dynamic> Function(String, String) p5Api({Completer<dynamic>? hold, bool empty = false, Map<String, dynamic>? profile}) {
  final base = p4Api(hold: hold, empty: empty);
  return (method, url) {
    if (hold != null || empty) return base(method, url);
    if (method == 'GET') {
      if (url.endsWith('/ptm/teachers')) return ptmTeacherRows();
      if (url.endsWith('/ptm')) return ptmRows();
      if (url.endsWith('/leaves')) return leaveRows();
      if (url.endsWith('/profile')) return profile ?? profileBody();
      if (url.endsWith('/dues')) return dueRows();
    }
    return base(method, url);
  };
}

