import 'api_client.dart';

/// Every method here maps 1:1 to a real, already-built backend endpoint
/// under /parent-portal - nothing here is a placeholder or mock. See
/// eldermin-backend/src/parent-portal for the server-side implementation.
class ParentApiService {
  final ApiClient _api;
  ParentApiService(this._api);

  // ── Auth ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final data = await _api.post('/parent-portal/auth/request-otp', data: {'phone': phone});
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final data = await _api.post('/parent-portal/auth/verify-otp', data: {'phone': phone, 'code': code});
    return Map<String, dynamic>.from(data);
  }

  // ── My Students ─────────────────────────────────────────────
  Future<List<dynamic>> getMyStudents() async => await _api.get('/parent-portal/my-students') as List<dynamic>;

  // ── Per-student ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudentProfile(String studentId) async =>
      Map<String, dynamic>.from(await _api.get('/parent-portal/students/$studentId/profile'));

  Future<Map<String, dynamic>> getMedical(String studentId) async =>
      Map<String, dynamic>.from(await _api.get('/parent-portal/students/$studentId/medical'));

  Future<List<dynamic>> getAcademicDocuments(String studentId) async =>
      await _api.get('/parent-portal/students/$studentId/documents') as List<dynamic>;

  Future<List<dynamic>> getAttendance(String studentId, {String? from, String? to}) async =>
      await _api.get('/parent-portal/students/$studentId/attendance', query: {if (from != null) 'from': from, if (to != null) 'to': to}) as List<dynamic>;

  Future<List<dynamic>> getHomework(String studentId) async =>
      await _api.get('/parent-portal/students/$studentId/homework') as List<dynamic>;

  Future<List<dynamic>> getLearningResources(String studentId) async =>
      await _api.get('/parent-portal/students/$studentId/learning-resources') as List<dynamic>;

  Future<List<dynamic>> getResults(String studentId) async =>
      await _api.get('/parent-portal/students/$studentId/results') as List<dynamic>;

  Future<List<dynamic>> getDues(String studentId) async =>
      await _api.get('/parent-portal/students/$studentId/dues') as List<dynamic>;

  Future<Map<String, dynamic>> getBehaviourAndTarbiyah(String studentId) async =>
      Map<String, dynamic>.from(await _api.get('/parent-portal/students/$studentId/behaviour'));

  Future<Map<String, dynamic>?> getTimetable(String studentId) async {
    final data = await _api.get('/parent-portal/students/$studentId/timetable');
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<List<dynamic>> getDatesheet(String studentId) async =>
      await _api.get('/parent-portal/students/$studentId/datesheet') as List<dynamic>;

  Future<List<dynamic>> getLibrary(String studentId) async =>
      await _api.get('/parent-portal/students/$studentId/library') as List<dynamic>;

  Future<List<dynamic>> getConsentRequests(String studentId) async =>
      await _api.get('/parent-portal/students/$studentId/consent') as List<dynamic>;

  Future<void> respondToConsent(String studentId, String consentRequestId, String decision, {String? notes}) =>
      _api.post('/parent-portal/students/$studentId/consent/$consentRequestId/respond', data: {'decision': decision, if (notes != null) 'notes': notes});

  Future<List<dynamic>> getStudentLeaves(String studentId) async =>
      await _api.get('/parent-portal/students/$studentId/leaves') as List<dynamic>;

  Future<void> createStudentLeave(String studentId, {required String fromDate, required String toDate, required String reason, String leaveType = 'other'}) =>
      _api.post('/parent-portal/students/$studentId/leaves', data: {'fromDate': fromDate, 'toDate': toDate, 'reason': reason, 'leaveType': leaveType});

  // ── School-wide ─────────────────────────────────────────────
  Future<List<dynamic>> getCirculars() async => await _api.get('/parent-portal/circulars') as List<dynamic>;

  Future<List<dynamic>> getEvents({String? from, String? to}) async =>
      await _api.get('/parent-portal/events', query: {if (from != null) 'from': from, if (to != null) 'to': to}) as List<dynamic>;

  // ── Notifications / Inbox ──────────────────────────────────
  Future<List<dynamic>> getNotifications({bool unreadOnly = false}) async =>
      await _api.get('/parent-portal/notifications', query: {if (unreadOnly) 'unreadOnly': 'true'}) as List<dynamic>;

  Future<void> markNotificationRead(String id) => _api.post('/parent-portal/notifications/$id/read');
  Future<void> markAllNotificationsRead() => _api.post('/parent-portal/notifications/read-all');

  // ── Messages ────────────────────────────────────────────────
  Future<List<dynamic>> getThreads() async => await _api.get('/parent-portal/threads') as List<dynamic>;

  Future<Map<String, dynamic>> createThread({
    required String subject, String? studentId, String? studentName,
    required String staffId, required String staffName, required String firstMessage,
  }) async => Map<String, dynamic>.from(await _api.post('/parent-portal/threads', data: {
        'subject': subject, if (studentId != null) 'studentId': studentId, if (studentName != null) 'studentName': studentName,
        'staffId': staffId, 'staffName': staffName, 'firstMessage': firstMessage,
      }));

  Future<List<dynamic>> getThreadMessages(String threadId) async =>
      await _api.get('/parent-portal/threads/$threadId/messages') as List<dynamic>;

  Future<void> sendMessage(String threadId, String body) =>
      _api.post('/parent-portal/threads/$threadId/messages', data: {'body': body});

  // ── Feedback (reuses the real Complaints module) ────────────
  Future<void> submitFeedback({required String title, required String description, String priority = 'low'}) =>
      _api.post('/complaints', data: {
        'title': title, 'description': description, 'priority': priority,
        'caseGroup': 'Feedback', 'caseType': 'General Feedback', 'raisedByType': 'parent', 'slaHours': 168,
      });
}
