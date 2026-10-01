/// Same production API every other Eldermin client (web ERP) talks to.
/// Override via --dart-define=API_BASE_URL=... for local backend testing.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.eldermin.com',
  );

  static const String apiPrefix = '$baseUrl/api/v1';
  static const String parentPortal = '$apiPrefix/parent-portal';

  // Timeouts
  static const int connectTimeout = 20000; // 20 seconds
  static const int receiveTimeout = 20000;

  // ── Auth ─────────────────────────────────────────────────────
  static const String requestOtp = '$parentPortal/auth/request-otp';
  static const String verifyOtp = '$parentPortal/auth/verify-otp';

  // ── My Students ──────────────────────────────────────────────
  static const String myStudents = '$parentPortal/my-students';

  // ── Per-student ──────────────────────────────────────────────
  static String studentProfile(String id) => '$parentPortal/students/$id/profile';
  static String medical(String id) => '$parentPortal/students/$id/medical';
  static String academicDocuments(String id) => '$parentPortal/students/$id/documents';
  static String attendance(String id) => '$parentPortal/students/$id/attendance';
  static String homework(String id) => '$parentPortal/students/$id/homework';
  static String learningResources(String id) => '$parentPortal/students/$id/learning-resources';
  static String results(String id) => '$parentPortal/students/$id/results';
  static String dues(String id) => '$parentPortal/students/$id/dues';
  static String behaviourAndTarbiyah(String id) => '$parentPortal/students/$id/behaviour';
  static String timetable(String id) => '$parentPortal/students/$id/timetable';
  static String datesheet(String id) => '$parentPortal/students/$id/datesheet';
  static String library(String id) => '$parentPortal/students/$id/library';
  static String consentRequests(String id) => '$parentPortal/students/$id/consent';
  static String respondToConsent(String id, String consentRequestId) =>
      '$parentPortal/students/$id/consent/$consentRequestId/respond';
  static String studentLeaves(String id) => '$parentPortal/students/$id/leaves';
  static String ptmHistory(String id) => '$parentPortal/students/$id/ptm';

  // ── LMS: My Courses ─────────────────────────────────────────
  static String myCourses(String id) => '$parentPortal/students/$id/courses';
  static String lessonProgress(String id) => '$parentPortal/students/$id/lessons/progress';

  // ── LMS: My Quizzes ──────────────────────────────────────────
  static String myQuizzes(String id) => '$parentPortal/students/$id/quizzes';
  static String startQuiz(String id) => '$parentPortal/students/$id/quizzes/start';
  static String submitQuiz(String id, String attemptId) =>
      '$parentPortal/students/$id/quizzes/$attemptId/submit';

  // ── School-wide ──────────────────────────────────────────────
  static const String circulars = '$parentPortal/circulars';
  static const String events = '$parentPortal/events';

  // ── Notifications / Inbox ───────────────────────────────────
  static const String notifications = '$parentPortal/notifications';
  static String markNotificationRead(String id) => '$parentPortal/notifications/$id/read';
  static const String markAllNotificationsRead = '$parentPortal/notifications/read-all';

  // ── Messages ─────────────────────────────────────────────────
  static const String threads = '$parentPortal/threads';
  static String threadMessages(String threadId) => '$parentPortal/threads/$threadId/messages';

  // ── Feedback (reuses the real Complaints module) ─────────────
  static const String complaints = '$apiPrefix/complaints';
}
