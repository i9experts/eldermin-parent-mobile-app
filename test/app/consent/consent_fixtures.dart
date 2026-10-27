import 'package:dio/dio.dart';

/// Rows as GET /parent-portal/students/:id/consent returns them (pinned "now" is 26 Oct 2026, 09:30).
List<dynamic> consentApiRows() => [
      {
        '_id': 'pending1',
        'title': 'Museum trip',
        'description': 'Hello<div>We visit the <b>museum</b></div><ul><li>Packed lunch</li></ul><script>alert(1)</script>',
        'category': 'field_trip',
        'dueDate': '2026-10-30T00:00:00.000Z',
        'attachments': ['https://cdn.example/consent-attachments/permission%20slip.png'],
        'createdBy': 'Ms Sara',
        'createdAt': '2026-10-20T07:00:00.000Z',
        'studentIds': ['s1', 'OTHER_CHILD_ID'],
        'response': null,
      },
      {'_id': 'today1', 'title': 'Due today', 'description': 'x', 'dueDate': '2026-10-26T00:00:00.000Z', 'response': null},
      {'_id': 'nodue1', 'title': 'No due date', 'description': 'x', 'response': null},
      {'_id': 'expired1', 'title': 'Old trip', 'description': 'x', 'dueDate': '2026-10-25T00:00:00.000Z', 'response': null},
      {
        '_id': 'done1',
        'title': 'Photo permission',
        'description': 'Use of photos',
        'category': 'photo_video',
        'dueDate': '2026-10-12T00:00:00.000Z',
        'createdBy': 'Ms Sara',
        'response': {
          'decision': 'declined',
          'respondedByName': 'Ahmed Khan',
          'notes': 'We prefer not to',
          'updatedAt': '2026-10-14T08:00:00.000Z',
          'respondedByUserId': 'SECRET_USER_ID',
        },
      },
    ];

/// The saved response document the backend returns for a respond call.
Map<String, dynamic> savedResponse(String decision, {String? notes}) => {
      'decision': decision,
      'respondedByName': 'Ahmed Khan',
      if (notes != null) 'notes': notes,
      'updatedAt': '2026-10-26T04:30:00.000Z',
    };

/// An API that serves [rows], answers a respond POST with [onRespond] (default: the saved response) and counts nothing else.
Future<dynamic> Function(String, String) consentApi({List<dynamic>? rows, dynamic Function(String url)? onRespond}) {
  return (method, url) async {
    if (method == 'POST' && url.endsWith('/respond')) {
      if (onRespond != null) return onRespond(url);
      return savedResponse('granted');
    }
    if (url.endsWith('/consent')) return rows ?? consentApiRows();
    return <dynamic>[]; // anything else the app asks for at start-up
  };
}

DioException respondFails(String url) => DioException(
      requestOptions: RequestOptions(path: url),
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: RequestOptions(path: url), statusCode: 500, data: {'message': 'Server said no'}),
    );
