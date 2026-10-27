import 'dart:async';
import 'package:eldermin_parent_app/core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

/// Realistic answers for the screen tests. Every date is fixed around [fixedNow] (Monday 26 October 2026) so renders and
/// goldens never depend on the wall clock. Unknown endpoints answer [].
final fixedNow = DateTime(2026, 10, 26, 9, 30);
final _now = fixedNow;
String _iso(DateTime d) => DateTime(d.year, d.month, d.day, 12).toIso8601String();
DateTime _inMonth(int day) => DateTime(_now.year, _now.month, day);

List<dynamic> attendanceRows() => [
      for (var d = 1; d <= 20; d++) {'date': _iso(_inMonth(d)), 'status': d % 7 == 0 ? 'absent' : (d % 5 == 0 ? 'late' : 'present')},
    ];

// due dates are fixed days of October 2026 (the screen filters by the selected month); day 1 is overdue, 27/28 are not
String _due(int day) => DateTime(_now.year, _now.month, day).toIso8601String();

List<dynamic> homeworkRows() => [
      {'_id': 'h1', 'subject': 'Mathematics', 'title': 'Fractions worksheet - page 14 to 16', 'description': 'Solve all questions.', 'dueDate': _due(27), 'totalMarks': 20, 'mySubmission': {'_id': 'sub1', 'status': 'pending'}},
      {'_id': 'h2', 'subject': 'Science', 'title': 'Plant diary', 'dueDate': _due(1), 'mySubmission': {'_id': 'sub2', 'status': 'pending'}},
      {'_id': 'h3', 'subject': 'English', 'title': 'Book report', 'dueDate': _due(26), 'totalMarks': 10, 'mySubmission': {'_id': 'sub3', 'status': 'graded', 'grade': 8, 'maxGrade': 10, 'feedback': 'Well structured, watch your spelling.'}},
      {'_id': 'h4', 'subject': 'Urdu', 'title': 'Poem recital', 'dueDate': _due(28), 'mySubmission': {'_id': 'sub4', 'status': 'submitted', 'textResponse': 'Done'}},
      {'_id': 'h5', 'subject': 'Art', 'title': 'Not on the roster yet', 'dueDate': _due(28)},
    ];

Map<String, dynamic> timetableBody() => {
      'gradeLevel': 'Grade 5',
      'sectionName': 'A',
      'periods': [
        for (var day = 0; day < 7; day++) ...[
          {'day': day, 'periodNo': 1, 'subject': 'Mathematics', 'startTime': '08:00', 'endTime': '08:40', 'roomNo': '12', 'type': 'class'},
          {'day': day, 'periodNo': 2, 'subject': 'English Language and Literature', 'startTime': '08:40', 'endTime': '09:20', 'roomNo': '12', 'type': 'class'},
          {'day': day, 'periodNo': 3, 'subject': 'Break', 'startTime': '09:20', 'endTime': '09:40', 'type': 'break'},
          {'day': day, 'periodNo': 4, 'subject': 'Science', 'startTime': '09:40', 'endTime': '10:20', 'type': 'class'},
        ],
      ],
    };

List<dynamic> notificationRows() => [
      {'_id': 'n1', 'type': 'homework', 'title': 'New homework: Fractions worksheet', 'body': 'Due in 2 days. Tap to open Homework.', 'isRead': false},
      {'_id': 'n2', 'type': 'fee_due', 'title': 'Fee reminder', 'body': 'Term 2 fee is due on the 30th.', 'isRead': false},
      {'_id': 'n3', 'type': 'message', 'title': 'Message from Ms Sara', 'body': 'Please see the attached note about the trip.', 'isRead': true},
      {'_id': 'n4', 'type': 'unknown_type', 'title': 'School update', 'body': '', 'isRead': true},
    ];

List<dynamic> threadRows() => [
      {'_id': 't1', 'staffName': 'Ms Sara Ahmed', 'subject': 'Homework help', 'studentName': 'Ayesha Khan', 'lastMessagePreview': 'Ayesha did very well in the quiz today, please encourage her to keep practising at home.', 'lastMessageAt': _iso(_now), 'guardianHasUnread': true},
      {'_id': 't2', 'staffName': 'Mr Bilal Qureshi (Sports)', 'subject': 'Sports day', 'studentName': 'Ayesha Khan', 'lastMessagePreview': 'Thanks!', 'lastMessageAt': _iso(_now), 'guardianHasUnread': false},
      {'_id': 't3', 'staffName': 'School Office', 'lastMessagePreview': '', 'guardianHasUnread': false},
    ];

List<dynamic> threadMessages() => [
      {'senderRole': 'staff', 'body': 'Hello! Ayesha did very well in the quiz today.', 'createdAt': _iso(_now)},
      {'senderRole': 'guardian', 'body': 'Thank you so much, that is lovely to hear.', 'createdAt': _iso(_now)},
    ];

List<dynamic> eventRows() => [
      {'_id': 'e1', 'title': 'Parent-teacher meeting', 'category': 'parents', 'startDate': _iso(_inMonth(10)), 'endDate': _iso(_inMonth(10)), 'venue': 'School hall', 'startTime': '09:00', 'endTime': '12:00', 'description': 'Meet your child\'s teachers.'},
      {'_id': 'e2', 'title': 'Mid-term exams', 'category': 'exam', 'startDate': _iso(_inMonth(15)), 'endDate': _iso(_inMonth(19))},
      {'_id': 'e3', 'title': 'Sports day', 'category': 'sports', 'startDate': _iso(_inMonth(22)), 'endDate': _iso(_inMonth(22)), 'venue': 'Main ground'},
    ];

List<dynamic> resultRows() => [
      {
        'assessmentTitle': 'Mid-term 2026',
        'term': 'Term 1',
        'overallPercentage': 82,
        'overallGrade': 'A',
        'subjects': [
          {'subject': 'Mathematics', 'percentage': 91},
          {'subject': 'English', 'percentage': 74},
          {'subject': 'Science', 'percentage': 55},
        ],
      },
      {'assessmentTitle': 'Unit test 1', 'term': 'Term 1', 'overallPercentage': 76, 'overallGrade': 'B', 'subjects': []},
    ];

/// The fake API for the P3 screens. [hold] keeps everything pending; [fail] makes every call a network error.
FutureOr<dynamic> Function(String, String) p3Api({Completer<dynamic>? hold, bool fail = false, bool empty = false}) {
  return (method, url) {
    if (hold != null) return hold.future;
    if (fail) throw StateError('use networkError');
    if (empty) return <dynamic>[];
    if (url == ApiConstants.myStudents) {
      return [
        {'_id': 's1', 'firstName': 'Ayesha', 'lastName': 'Khan', 'currentGrade': '5', 'currentSection': 'A'}
      ];
    }
    if (url.endsWith('/attendance')) return attendanceRows();
    if (url.endsWith('/homework')) return homeworkRows();
    if (url.endsWith('/timetable')) return timetableBody();
    if (url.endsWith('/results')) return resultRows();
    if (url == ApiConstants.notifications) return notificationRows();
    if (url == ApiConstants.threads) return threadRows();
    if (url.endsWith('/messages')) return threadMessages();
    if (url == ApiConstants.events) return eventRows();
    if (url.endsWith('/dues')) return <dynamic>[];
    return <dynamic>[];
  };
}

@visibleForTesting
const p3Widths = [360.0, 320.0];
