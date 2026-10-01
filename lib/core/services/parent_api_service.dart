import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../network/base_client.dart';
import '../network/dio_exception_handler.dart';

/// Every method here maps 1:1 to a real, already-built backend endpoint
/// under /parent-portal - nothing here is a placeholder or mock. See
/// eldermin-backend/src/parent-portal for the server-side implementation.
class ParentApiService {
  final BaseClient _client;
  ParentApiService(this._client);

  Future<dynamic> _get(String url, {Map<String, dynamic>? query, bool requiresAuth = true}) async {
    try {
      final res = await _client.get(url, queryParameters: query, requiresAuth: requiresAuth);
      return res.data;
    } on DioException catch (e) {
      throw DioExceptionHandler.handle(e);
    }
  }

  Future<dynamic> _post(String url, {dynamic data, bool requiresAuth = true}) async {
    try {
      final res = await _client.post(url, data: data, requiresAuth: requiresAuth);
      return res.data;
    } on DioException catch (e) {
      throw DioExceptionHandler.handle(e);
    }
  }

  // ── Auth ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> requestOtp(String phone) async => Map<String, dynamic>.from(
      await _post(ApiConstants.requestOtp, data: {'phone': phone}, requiresAuth: false));

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async => Map<String, dynamic>.from(
      await _post(ApiConstants.verifyOtp, data: {'phone': phone, 'code': code}, requiresAuth: false));

  // ── My Students ─────────────────────────────────────────────
  Future<List<dynamic>> getMyStudents() async => await _get(ApiConstants.myStudents) as List<dynamic>;

  // ── Per-student ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudentProfile(String studentId) async =>
      Map<String, dynamic>.from(await _get(ApiConstants.studentProfile(studentId)));

  Future<Map<String, dynamic>> getMedical(String studentId) async =>
      Map<String, dynamic>.from(await _get(ApiConstants.medical(studentId)));

  Future<List<dynamic>> getAcademicDocuments(String studentId) async =>
      await _get(ApiConstants.academicDocuments(studentId)) as List<dynamic>;

  Future<List<dynamic>> getAttendance(String studentId, {String? from, String? to}) async => await _get(
        ApiConstants.attendance(studentId),
        query: {if (from != null) 'from': from, if (to != null) 'to': to},
      ) as List<dynamic>;

  Future<List<dynamic>> getHomework(String studentId) async =>
      await _get(ApiConstants.homework(studentId)) as List<dynamic>;

  Future<List<dynamic>> getLearningResources(String studentId) async =>
      await _get(ApiConstants.learningResources(studentId)) as List<dynamic>;

  Future<List<dynamic>> getResults(String studentId) async =>
      await _get(ApiConstants.results(studentId)) as List<dynamic>;

  Future<List<dynamic>> getDues(String studentId) async =>
      await _get(ApiConstants.dues(studentId)) as List<dynamic>;

  Future<Map<String, dynamic>> getBehaviourAndTarbiyah(String studentId) async =>
      Map<String, dynamic>.from(await _get(ApiConstants.behaviourAndTarbiyah(studentId)));

  Future<Map<String, dynamic>?> getTimetable(String studentId) async {
    final data = await _get(ApiConstants.timetable(studentId));
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<List<dynamic>> getDatesheet(String studentId) async =>
      await _get(ApiConstants.datesheet(studentId)) as List<dynamic>;

  Future<List<dynamic>> getLibrary(String studentId) async =>
      await _get(ApiConstants.library(studentId)) as List<dynamic>;

  Future<List<dynamic>> getConsentRequests(String studentId) async =>
      await _get(ApiConstants.consentRequests(studentId)) as List<dynamic>;

  Future<void> respondToConsent(String studentId, String consentRequestId, String decision, {String? notes}) =>
      _post(ApiConstants.respondToConsent(studentId, consentRequestId),
          data: {'decision': decision, if (notes != null) 'notes': notes});

  Future<List<dynamic>> getStudentLeaves(String studentId) async =>
      await _get(ApiConstants.studentLeaves(studentId)) as List<dynamic>;

  Future<void> createStudentLeave(String studentId,
          {required String fromDate, required String toDate, required String reason, String leaveType = 'other'}) =>
      _post(ApiConstants.studentLeaves(studentId),
          data: {'fromDate': fromDate, 'toDate': toDate, 'reason': reason, 'leaveType': leaveType});

  // ── School-wide ─────────────────────────────────────────────
  Future<List<dynamic>> getCirculars() async => await _get(ApiConstants.circulars) as List<dynamic>;

  Future<List<dynamic>> getEvents({String? from, String? to}) async => await _get(
        ApiConstants.events,
        query: {if (from != null) 'from': from, if (to != null) 'to': to},
      ) as List<dynamic>;

  // ── Notifications / Inbox ──────────────────────────────────
  Future<List<dynamic>> getNotifications({bool unreadOnly = false}) async => await _get(
        ApiConstants.notifications,
        query: {if (unreadOnly) 'unreadOnly': 'true'},
      ) as List<dynamic>;

  Future<void> markNotificationRead(String id) => _post(ApiConstants.markNotificationRead(id));
  Future<void> markAllNotificationsRead() => _post(ApiConstants.markAllNotificationsRead);

  // ── Parent-Teacher Meetings ─────────────────────────────────
  Future<List<dynamic>> getPTMHistory(String studentId) async =>
      await _get(ApiConstants.ptmHistory(studentId)) as List<dynamic>;

  // ── LMS: My Courses ─────────────────────────────────────────
  Future<List<dynamic>> getMyCourses(String studentId) async =>
      await _get(ApiConstants.myCourses(studentId)) as List<dynamic>;

  Future<void> markLessonProgress(
    String studentId, {
    required String syllabusId,
    required int unitNo,
    required int topicNo,
    required int lessonNo,
    required String status,
  }) =>
      _post(ApiConstants.lessonProgress(studentId), data: {
        'syllabusId': syllabusId, 'unitNo': unitNo, 'topicNo': topicNo,
        'lessonNo': lessonNo, 'status': status,
      });

  // ── LMS: My Quizzes ──────────────────────────────────────────
  Future<List<dynamic>> getMyQuizzes(String studentId) async =>
      await _get(ApiConstants.myQuizzes(studentId)) as List<dynamic>;

  Future<Map<String, dynamic>> startQuiz(String studentId,
          {required String assessmentId, required String subject}) async =>
      Map<String, dynamic>.from(await _post(ApiConstants.startQuiz(studentId),
          data: {'assessmentId': assessmentId, 'subject': subject}));

  Future<Map<String, dynamic>> submitQuiz(
    String studentId,
    String attemptId,
    List<Map<String, dynamic>> answers,
  ) async =>
      Map<String, dynamic>.from(await _post(
          ApiConstants.submitQuiz(studentId, attemptId),
          data: {'answers': answers}));

  // ── Messages ────────────────────────────────────────────────
  Future<List<dynamic>> getThreads() async => await _get(ApiConstants.threads) as List<dynamic>;

  Future<Map<String, dynamic>> createThread({
    required String subject, String? studentId, String? studentName,
    required String staffId, required String staffName, required String firstMessage,
  }) async => Map<String, dynamic>.from(await _post(ApiConstants.threads, data: {
        'subject': subject, if (studentId != null) 'studentId': studentId, if (studentName != null) 'studentName': studentName,
        'staffId': staffId, 'staffName': staffName, 'firstMessage': firstMessage,
      }));

  Future<List<dynamic>> getThreadMessages(String threadId) async =>
      await _get(ApiConstants.threadMessages(threadId)) as List<dynamic>;

  Future<void> sendMessage(String threadId, String body) =>
      _post(ApiConstants.threadMessages(threadId), data: {'body': body});

  // ── Feedback (reuses the real Complaints module) ────────────
  Future<void> submitFeedback({
    required String title,
    required String description,
    required String raisedByName,
    String priority = 'medium',
  }) =>
      _post(ApiConstants.complaints, data: {
        'title': title, 'description': description, 'raisedByName': raisedByName, 'priority': priority,
        'caseGroup': 'Feedback', 'caseType': 'General Feedback', 'raisedByType': 'parent', 'slaHours': 168,
      });
}
