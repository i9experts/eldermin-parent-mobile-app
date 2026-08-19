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
