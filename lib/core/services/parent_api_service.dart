import 'dart:convert';

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../network/api_exception.dart';
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

  /// Some responses arrive as an already-decoded [Map] and some (e.g. a
  /// body dio didn't auto-parse) arrive as a raw JSON [String]; normalize
  /// either into a Map instead of letting `Map.from` throw a TypeError.
  Map<String, dynamic> _asMap(dynamic x) {
    if (x is Map) return Map<String, dynamic>.from(x);
    if (x is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(x) as Map);
      } on FormatException {
        throw ApiException('Unexpected response format from server.');
      }
    }
    throw ApiException('Unexpected response format from server.');
  }

  // ── Auth ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> requestOtp(String phone) async => _asMap(
      await _post(ApiConstants.requestOtp, data: {'phone': phone}, requiresAuth: false));

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async => _asMap(
      await _post(ApiConstants.verifyOtp, data: {'phone': phone, 'code': code}, requiresAuth: false));

  Future<Map<String, dynamic>> registerLead(Map<String, dynamic> data) async =>
      Map<String, dynamic>.from(await _post(ApiConstants.registerLead, data: data, requiresAuth: false));

  Future<Map<String, dynamic>> loginLead(String email, String password) async =>
      Map<String, dynamic>.from(await _post(ApiConstants.loginLead,
          data: {'email': email, 'password': password}, requiresAuth: false));

  // ── My Students ─────────────────────────────────────────────
  Future<List<dynamic>> getMyStudents() async => await _get(ApiConstants.myStudents) as List<dynamic>;

  // ── Device activation ping ──────────────────────────────────
  // Fire-and-forget: a failed ping (offline, server hiccup) should never
  // block login or app startup, so callers don't await/surface errors
  // from this - see DeviceActivationService.
  Future<void> pingDevice({required String deviceId, required String platform, String? appVersion}) =>
      _post(ApiConstants.devicePing, data: {
        'deviceId': deviceId, 'platform': platform, if (appVersion != null) 'appVersion': appVersion,
      });

  // ── Per-student ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudentProfile(String studentId) async =>
      _asMap(await _get(ApiConstants.studentProfile(studentId)));

  Future<Map<String, dynamic>> getMedical(String studentId) async =>
      _asMap(await _get(ApiConstants.medical(studentId)));

  Future<List<dynamic>> getAcademicDocuments(String studentId) async =>
      await _get(ApiConstants.academicDocuments(studentId)) as List<dynamic>;

  Future<List<dynamic>> getAttendance(String studentId, {String? from, String? to}) async => await _get(
        ApiConstants.attendance(studentId),
        query: {if (from != null) 'from': from, if (to != null) 'to': to},
      ) as List<dynamic>;

  Future<List<dynamic>> getHomework(String studentId) async =>
      await _get(ApiConstants.homework(studentId)) as List<dynamic>;

  Future<void> submitHomework(String studentId, String assignmentId, {required String textResponse}) =>
      _post(ApiConstants.submitHomework(studentId, assignmentId), data: {'textResponse': textResponse});

  // ── LMS: courses + quizzes ──────────────────────────────────
  Future<List<dynamic>> getCourses(String studentId) async =>
      await _get(ApiConstants.courses(studentId)) as List<dynamic>;

  Future<void> markLessonProgress(String studentId, {
    required String syllabusId, required int unitNo, required int topicNo, required int lessonNo, required String status,
  }) => _post(ApiConstants.lessonProgress(studentId), data: {
        'syllabusId': syllabusId, 'unitNo': unitNo, 'topicNo': topicNo, 'lessonNo': lessonNo, 'status': status,
      });

  Future<List<dynamic>> getQuizzes(String studentId) async =>
      await _get(ApiConstants.quizzes(studentId)) as List<dynamic>;

  Future<Map<String, dynamic>> startQuiz(String studentId, {required String assessmentId, required String subject}) async =>
      _asMap(await _post(ApiConstants.startQuiz(studentId), data: {'assessmentId': assessmentId, 'subject': subject}));

  Future<Map<String, dynamic>> submitQuiz(String studentId, String attemptId, List<Map<String, dynamic>> answers) async =>
      _asMap(await _post(ApiConstants.submitQuiz(studentId, attemptId), data: {'answers': answers}));

  Future<List<dynamic>> getClassDiary(String studentId) async =>
      await _get(ApiConstants.classDiary(studentId)) as List<dynamic>;

  Future<List<int>> downloadClassDiaryPdf(String studentId, String diaryId) async {
    try {
      final res = await _client.getBytes(ApiConstants.classDiaryPdf(studentId, diaryId));
      return res.data ?? const <int>[];
    } on DioException catch (e) {
      throw DioExceptionHandler.handle(e);
    }
  }

  Future<List<dynamic>> getLearningResources(String studentId) async =>
      await _get(ApiConstants.learningResources(studentId)) as List<dynamic>;

  Future<List<dynamic>> getResults(String studentId) async =>
      await _get(ApiConstants.results(studentId)) as List<dynamic>;

  Future<List<dynamic>> getDues(String studentId) async =>
      await _get(ApiConstants.dues(studentId)) as List<dynamic>;

  Future<Map<String, dynamic>> getBehaviourAndTarbiyah(String studentId) async =>
      _asMap(await _get(ApiConstants.behaviourAndTarbiyah(studentId)));

  Future<Map<String, dynamic>?> getTimetable(String studentId) async {
    final data = await _get(ApiConstants.timetable(studentId));
    if (data == null || (data is String && data.trim().isEmpty)) return null;
    return _asMap(data);
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

  // ── Home Tasks (Tarbiyah-at-home) ───────────────────────────
  Future<List<dynamic>> getHomeTasks(String studentId) async =>
      await _get(ApiConstants.homeTasks(studentId)) as List<dynamic>;

  Future<void> completeHomeTask(String studentId, String taskId, {String? parentNotes}) =>
      _post(ApiConstants.completeHomeTask(studentId, taskId),
          data: {if (parentNotes != null) 'parentNotes': parentNotes});

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

  Future<List<dynamic>> getPTMTeachers(String studentId) async =>
      await _get(ApiConstants.ptmTeachers(studentId)) as List<dynamic>;

  Future<void> requestPTM(String studentId,
          {required String teacherId, required String scheduledDate, String? startTime, String? reason}) =>
      _post(ApiConstants.ptmHistory(studentId), data: {
        'teacherId': teacherId, 'scheduledDate': scheduledDate,
        if (startTime != null) 'startTime': startTime,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

  Future<void> cancelPTM(String studentId, String meetingId) =>
      _post(ApiConstants.ptmCancel(studentId, meetingId));

  Future<void> acknowledgeCircular(String id) => _post(ApiConstants.acknowledgeCircular(id));

  // ── Messages ────────────────────────────────────────────────
  Future<List<dynamic>> getThreads() async => await _get(ApiConstants.threads) as List<dynamic>;

  Future<Map<String, dynamic>> createThread({
    required String subject, String? studentId, String? studentName,
    required String staffId, required String staffName, required String firstMessage,
  }) async => _asMap(await _post(ApiConstants.threads, data: {
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
