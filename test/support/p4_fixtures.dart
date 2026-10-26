import 'dart:async';
import 'package:eldermin_parent_app/core/constants/api_constants.dart';
import 'p3_fixtures.dart';

/// Realistic answers for the P4 screens (all dates fixed around [fixedNow], Monday 26 October 2026).
String _d(int day, [int month = 10]) => DateTime(2026, month, day, 12).toIso8601String();

List<dynamic> diaryRows() => [
      {
        '_id': 'd1',
        'diaryDate': _d(26),
        'teacherName': 'Ms Sara Ahmed',
        'periods': [
          {'subject': 'Mathematics', 'title': 'Adding fractions', 'description': 'We revised common denominators.', 'classworkDescription': 'Exercise 4.2, questions 1 to 10.', 'homeworkDescription': 'Finish questions 11 to 15 in the notebook.'},
          {'subject': 'English', 'title': 'Poetry', 'classworkDescription': 'Read "The Daffodils" aloud.'},
        ],
      },
      {
        '_id': 'd2',
        'diaryDate': _d(23),
        'teacherName': 'Mr Bilal Qureshi',
        'periods': [
          {'subject': 'Science', 'title': 'Plants', 'homeworkDescription': 'Draw and label a leaf.'}
        ],
      },
    ];

List<dynamic> courseRows() => [
      {
        'syllabusId': 'sy1',
        'subjectName': 'Mathematics',
        'teacherName': 'Ms Sara Ahmed',
        'term': 'Term 1',
        'completionPct': 40,
        'completedLessons': 2,
        'totalLessons': 5,
        'units': [
          {
            'unitNo': 1,
            'unitName': 'Fractions',
            'topics': [
              {
                'topicNo': 1,
                'topicName': 'Adding fractions',
                'lessons': [
                  {'lessonNo': 1, 'title': 'Common denominators', 'description': 'A short video and worked examples.', 'status': 'completed', 'url': 'https://example.com/l1'},
                  {'lessonNo': 2, 'title': 'Unlike denominators', 'status': 'in_progress'},
                  {'lessonNo': 3, 'title': 'Mixed numbers', 'status': 'not_started'},
                ],
              },
            ],
          },
        ],
      },
      {'syllabusId': 'sy2', 'subjectName': 'Science', 'teacherName': '', 'term': '', 'completionPct': 0, 'completedLessons': 0, 'totalLessons': 3, 'units': []},
    ];

List<dynamic> quizRows() => [
      {'assessmentId': 'a1', 'subject': 'Mathematics', 'assessmentTitle': 'Fractions quiz', 'totalMarks': 20, 'passingMarks': 10, 'attemptsAllowed': 2, 'attemptsUsed': 0},
      {'assessmentId': 'a2', 'subject': 'Science', 'assessmentTitle': 'Plants quiz', 'totalMarks': 10, 'passingMarks': 5, 'attemptsAllowed': 1, 'attemptsUsed': 1, 'latestAttempt': {'status': 'graded', 'obtainedMarks': 8}},
      {'assessmentId': 'a3', 'subject': 'English', 'assessmentTitle': 'Poetry quiz', 'totalMarks': 10, 'passingMarks': 5, 'attemptsAllowed': 1, 'attemptsUsed': 1, 'latestAttempt': {'status': 'submitted'}},
      {'assessmentId': 'a4', 'subject': 'Urdu', 'assessmentTitle': 'Grammar quiz', 'totalMarks': 10, 'passingMarks': 5, 'attemptsAllowed': 1, 'attemptsUsed': 0, 'latestAttempt': {'status': 'in_progress'}},
    ];

Map<String, dynamic> quizStartBody({int questions = 3}) => {
      'attempt': {'_id': 'att1'},
      'questions': [
        for (var i = 1; i <= questions; i++)
          if (i == 2)
            {'_id': 'q$i', 'type': 'true_false', 'questionText': 'A fraction can be bigger than 1.', 'marks': 1}
          else if (i == 3)
            {'_id': 'q$i', 'type': 'short_answer', 'questionText': 'Name the top number of a fraction.', 'marks': 2}
          else
            {
              '_id': 'q$i',
              'type': 'mcq',
              'questionText': 'What is 1/2 + 1/2 ?',
              'options': [
                {'text': '1/4'},
                {'text': '1'},
                {'text': '2'},
              ],
              'marks': 1,
            },
      ],
    };

List<dynamic> learningPlanRows() => [
      {'planDate': _d(24), 'subject': 'Mathematics', 'topic': 'Adding fractions', 'resources': [{'name': 'Worksheet'}, {'name': 'Video'}]},
      {'planDate': _d(21), 'subject': 'Science', 'topic': 'Parts of a plant', 'resources': []},
    ];

List<dynamic> libraryRows() => [
      {'bookTitle': 'The Little Prince', 'status': 'issued', 'dueDate': _d(30), 'issueDate': _d(16)},
      {'bookTitle': 'Stories of the Prophets', 'status': 'overdue', 'dueDate': _d(20), 'issueDate': _d(6)},
      {'bookTitle': 'Atlas of the World', 'status': 'returned', 'returnDate': _d(12), 'issueDate': _d(2)},
    ];

Map<String, dynamic> tarbiyahBody() => {
      'behaviourRecords': [
        {'points': 5, 'type': 'positive', 'title': 'Helped a classmate', 'description': 'Shared her notes with a new student.'},
        {'points': -2, 'type': 'negative', 'title': 'Late to class', 'description': 'Arrived ten minutes late twice this week.'},
        {'points': 0, 'type': 'neutral', 'title': 'Note', 'description': 'Settling in well.'},
      ],
      'tarbiyahAssessments': [
        {
          'assessmentDate': _d(20),
          'overallPercentage': 86,
          'areasOfStrength': ['Honesty and kindness towards classmates'],
          'traits': [
            {'traitName': 'Honesty', 'percentage': 92},
            {'traitName': 'Respect', 'percentage': 85},
            {'traitName': 'Responsibility', 'percentage': 70},
            {'traitName': 'Teamwork', 'percentage': 90},
          ],
        },
      ],
    };

List<dynamic> homeTaskRows() => [
      {'_id': 'ht1', 'title': 'Say Bismillah before meals', 'description': 'Practise for the whole week.', 'dueDate': _d(30), 'status': 'assigned', 'assignedBy': 'Ms Sara Ahmed'},
      {'_id': 'ht2', 'title': 'Help set the table', 'dueDate': _d(25), 'status': 'completed', 'completedAt': _d(24), 'parentNotes': 'She enjoyed it.', 'reviewRating': 4, 'reviewNotes': 'Lovely, well done!'},
    ];

List<dynamic> datesheetRows() => [
      {
        'title': 'Mid-term examination',
        'type': 'mid_term',
        'term': 'Term 1',
        'status': 'scheduled',
        'startDate': _d(15),
        'endDate': _d(19),
        'subjects': [
          {'subject': 'Mathematics', 'date': _d(15), 'startTime': '09:00', 'duration': 60, 'venue': 'Hall A'},
          {'subject': 'English', 'date': _d(16), 'startTime': '09:00', 'duration': 60},
        ],
      },
    ];

List<dynamic> circularRows() => [
      {'_id': 'c1', 'title': 'Winter uniform from 1 November', 'body': 'Please make sure your child wears the winter uniform from Monday.', 'category': 'circular', 'createdAt': _d(22), 'effectiveDate': _d(30), 'requiresAcknowledgment': true, 'acknowledged': false},
      {'_id': 'c2', 'title': 'Sports day', 'body': 'Sports day is on the 22nd. Parents are welcome.', 'category': 'event', 'createdAt': _d(10), 'requiresAcknowledgment': false},
    ];

List<dynamic> consentRows() => [
      {'_id': 'co1', 'title': 'School trip to the museum', 'description': 'A guided visit on Thursday 5 November. Packed lunch needed.', 'dueDate': _d(30)},
      {'_id': 'co2', 'title': 'Photo permission', 'description': 'Use of photos in the school newsletter.', 'dueDate': _d(12), 'response': {'decision': 'granted'}},
    ];

Map<String, dynamic> medicalBody() => {
      'bloodGroup': 'O+',
      'allergies': ['Peanuts', 'Dust'],
      'medications': ['Inhaler'],
      'conditions': ['Mild asthma'],
      'doctorName': 'Dr Hina Malik',
      'doctorPhone': '0300 1234567',
      'insuranceProvider': 'Jubilee',
      'insurancePolicyNumber': 'JP-4482',
      'specialNeedsDetail': 'Needs a seat near the front.',
    };

List<dynamic> documentRows() => [
      {'name': 'Birth certificate', 'type': 'identity', 'status': 'verified', 'uploadedAt': _d(3), 'fileUrl': 'https://example.com/bc.pdf'},
      {'name': 'Previous school report', 'type': 'academic', 'status': 'pending', 'uploadedAt': _d(5)},
    ];

/// The fake API for the P4 screens (falls back to the P3 answers).
FutureOr<dynamic> Function(String, String) p4Api({Completer<dynamic>? hold, bool empty = false}) {
  final base = p3Api(hold: hold, empty: empty);
  return (method, url) {
    if (hold != null || empty) return base(method, url);
    if (url.endsWith('/class-diary')) return diaryRows();
    if (url.endsWith('/courses')) return courseRows();
    if (url.endsWith('/quizzes/start')) return quizStartBody();
    if (url.endsWith('/quizzes')) return quizRows();
    if (url.endsWith('/learning-resources')) return learningPlanRows();
    if (url.endsWith('/library')) return libraryRows();
    if (url.endsWith('/behaviour')) return tarbiyahBody();
    if (url.endsWith('/home-tasks')) return homeTaskRows();
    if (url.endsWith('/datesheet')) return datesheetRows();
    if (url == ApiConstants.circulars) return circularRows();
    if (url.endsWith('/consent')) return consentRows();
    if (url.endsWith('/medical')) return medicalBody();
    if (url.endsWith('/documents')) return documentRows();
    return base(method, url);
  };
}
