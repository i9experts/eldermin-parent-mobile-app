import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_providers.dart';

class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String currentGrade;
  final String? currentSection;
  final String? admissionNo;
  final String? photoUrl;
  final String? status;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.currentGrade,
    this.currentSection,
    this.admissionNo,
    this.photoUrl,
    this.status,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
  String get gradeSection => currentSection != null && currentSection!.isNotEmpty ? '$currentGrade - $currentSection' : currentGrade;

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['_id'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        currentGrade: json['currentGrade'] as String? ?? '',
        currentSection: json['currentSection'] as String?,
        admissionNo: json['admissionNo'] as String?,
        photoUrl: json['photoUrl'] as String?,
        status: json['status'] as String?,
      );
}

final myStudentsProvider = FutureProvider<List<Student>>((ref) async {
  final api = ref.watch(parentApiProvider);
  final raw = await api.getMyStudents();
  return raw.map((e) => Student.fromJson(Map<String, dynamic>.from(e))).toList();
});

/// The full Student object for whichever id is currently selected -
/// every screen that needs "the current child's name/grade" reads this
/// instead of re-fetching the list itself.
final selectedStudentProvider = Provider<Student?>((ref) {
  final studentsAsync = ref.watch(myStudentsProvider);
  final selectedId = ref.watch(selectedStudentIdProvider);
  return studentsAsync.maybeWhen(
    data: (students) {
      if (students.isEmpty) return null;
      if (selectedId == null) return students.first;
      return students.firstWhere((s) => s.id == selectedId, orElse: () => students.first);
    },
    orElse: () => null,
  );
});
