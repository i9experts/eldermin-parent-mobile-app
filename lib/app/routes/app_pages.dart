import 'package:get/get.dart';
import '../modules/attendance/bindings/attendance_binding.dart';
import '../modules/attendance/views/attendance_screen.dart';
import '../modules/auth/bindings/otp_verify_binding.dart';
import '../modules/auth/views/otp_verify_screen.dart';
import '../modules/circulars/bindings/circulars_binding.dart';
import '../modules/circulars/views/circulars_screen.dart';
import '../modules/consent/bindings/consent_binding.dart';
import '../modules/consent/views/consent_screen.dart';
import '../modules/datesheet/bindings/datesheet_binding.dart';
import '../modules/datesheet/views/datesheet_screen.dart';
import '../modules/documents/bindings/documents_binding.dart';
import '../modules/documents/views/documents_screen.dart';
import '../modules/dues/bindings/dues_binding.dart';
import '../modules/dues/views/dues_screen.dart';
import '../modules/feedback/bindings/feedback_binding.dart';
import '../modules/feedback/views/feedback_screen.dart';
import '../modules/homework/bindings/homework_binding.dart';
import '../modules/homework/views/homework_screen.dart';
import '../modules/leaves/bindings/leaves_binding.dart';
import '../modules/leaves/views/leaves_screen.dart';
import '../modules/learning_resources/bindings/learning_resources_binding.dart';
import '../modules/learning_resources/views/learning_resources_screen.dart';
import '../modules/library/bindings/library_binding.dart';
import '../modules/library/views/library_screen.dart';
import '../modules/medical/bindings/medical_binding.dart';
import '../modules/medical/views/medical_screen.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_screen.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_screen.dart';
import '../modules/ptm/bindings/ptm_binding.dart';
import '../modules/ptm/views/ptm_screen.dart';
import '../modules/students/views/student_selector_screen.dart';
import '../modules/tarbiyah/bindings/tarbiyah_binding.dart';
import '../modules/tarbiyah/views/tarbiyah_screen.dart';
import '../modules/timetable/bindings/timetable_binding.dart';
import '../modules/timetable/views/timetable_screen.dart';
import 'app_routes.dart';

/// Every screen the app can push on top of the auth-gated root (login or
/// home shell). The root screens themselves aren't routed here - AuthGate
/// swaps between them directly, matching the original app's navigation.
class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
        name: Routes.otpVerify,
        page: () => const OtpVerifyScreen(),
        binding: OtpVerifyBinding()),
    GetPage(
        name: Routes.studentSelector,
        page: () => const StudentSelectorScreen()),
    GetPage(
        name: Routes.notifications,
        page: () => const NotificationsScreen(),
        binding: NotificationsBinding()),
    GetPage(
        name: Routes.dues,
        page: () => const DuesScreen(),
        binding: DuesBinding()),
    GetPage(
        name: Routes.attendance,
        page: () => const AttendanceScreen(),
        binding: AttendanceBinding()),
    GetPage(
        name: Routes.homework,
        page: () => const HomeworkScreen(),
        binding: HomeworkBinding()),
    GetPage(
        name: Routes.timetable,
        page: () => const TimetableScreen(),
        binding: TimetableBinding()),
    GetPage(
        name: Routes.tarbiyah,
        page: () => const TarbiyahScreen(),
        binding: TarbiyahBinding()),
    GetPage(
        name: Routes.library,
        page: () => const LibraryScreen(),
        binding: LibraryBinding()),
    GetPage(
        name: Routes.leaves,
        page: () => const LeavesScreen(),
        binding: LeavesBinding()),
    GetPage(
        name: Routes.circulars,
        page: () => const CircularsScreen(),
        binding: CircularsBinding()),
    GetPage(
        name: Routes.consent,
        page: () => const ConsentScreen(),
        binding: ConsentBinding()),
    GetPage(
        name: Routes.profile,
        page: () => const ProfileScreen(),
        binding: ProfileBinding()),
    GetPage(
        name: Routes.medical,
        page: () => const MedicalScreen(),
        binding: MedicalBinding()),
    GetPage(
        name: Routes.documents,
        page: () => const DocumentsScreen(),
        binding: DocumentsBinding()),
    GetPage(
        name: Routes.learningResources,
        page: () => const LearningResourcesScreen(),
        binding: LearningResourcesBinding()),
    GetPage(
        name: Routes.datesheet,
        page: () => const DatesheetScreen(),
        binding: DatesheetBinding()),
    GetPage(name: Routes.ptm, page: () => const PtmScreen(), binding: PtmBinding()),
    GetPage(
        name: Routes.feedback,
        page: () => const FeedbackScreen(),
        binding: FeedbackBinding()),
  ];
}
