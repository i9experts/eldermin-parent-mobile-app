import 'package:dio/dio.dart';
import 'package:eldermin_parent_app/app/modules/students/controllers/student_controller.dart';
import 'package:eldermin_parent_app/core/models/student.dart';
import 'package:eldermin_parent_app/core/network/base_client.dart';
import 'package:eldermin_parent_app/core/services/parent_api_service.dart';

/// A [BaseClient] that never touches the network: answers from [handler]
/// (url + query -> body) or throws a bad-response [DioException] with [status].
class FakeBaseClient extends BaseClient {
  final List<String> calls = [];
  final List<Map<String, dynamic>?> queries = [];
  final dynamic Function(String url, Map<String, dynamic>? query) handler;
  FakeBaseClient(this.handler);

  @override
  Future<Response> get(String url, {Map<String, dynamic>? queryParameters, bool requiresAuth = true}) async {
    calls.add(url);
    queries.add(queryParameters);
    final body = handler(url, queryParameters);
    final req = RequestOptions(path: url);
    if (body is int) {
      throw DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: req, statusCode: body, data: {'message': 'status $body'}),
      );
    }
    return Response(requestOptions: req, statusCode: 200, data: body);
  }
}

/// A [ParentApiService] whose Early Years calls are scripted, for controller/widget tests.
class FakeEyApi extends ParentApiService {
  FakeEyApi() : super(FakeBaseClient((_, __) => <String, dynamic>{}));

  Future<Map<String, dynamic>> Function(String studentId) summary = (id) async => {'studentId': id, 'isEarlyYears': false};
  Future<Map<String, dynamic>> Function(String studentId, int page) portfolio = (id, p) async => {'items': [], 'page': p, 'total': 0, 'hasMore': false};
  Future<Map<String, dynamic>> Function(String studentId, String entryId) entry = (id, e) async => throw StateError('no entry scripted');
  Future<Map<String, dynamic>> Function(String studentId, int page) observations = (id, p) async => {'items': [], 'page': p, 'total': 0, 'hasMore': false};
  final List<String> log = [];

  @override
  Future<Map<String, dynamic>> getEarlyYearsSummary(String studentId) {
    log.add('summary:$studentId');
    return summary(studentId);
  }

  @override
  Future<Map<String, dynamic>> getEarlyYearsPortfolio(String studentId, {int page = 1, int limit = 20}) {
    log.add('portfolio:$studentId:$page');
    return portfolio(studentId, page);
  }

  @override
  Future<Map<String, dynamic>> getEarlyYearsEntry(String studentId, String entryId) {
    log.add('entry:$studentId:$entryId');
    return entry(studentId, entryId);
  }

  @override
  Future<Map<String, dynamic>> getEarlyYearsObservations(String studentId, {int page = 1, int limit = 20}) {
    log.add('observations:$studentId:$page');
    return observations(studentId, page);
  }
}

Student kid(String id, {String name = 'Ayesha'}) => Student(id: id, firstName: name, lastName: 'Khan', currentGrade: 'Nursery');

StudentController studentsOf(FakeEyApi api, List<Student> list, {String? selected}) {
  final c = StudentController(api);
  c.students.value = list;
  if (selected != null) c.selectedId.value = selected;
  return c;
}

Map<String, dynamic> eyItem(String id, {String title = 'Painting', List<Map<String, dynamic>>? media}) => {
      'id': id,
      'title': title,
      'narrative': 'Mixed colours',
      'tryThisAtHome': null,
      'createdAt': '2026-10-01T10:00:00.000Z',
      'media': media ?? [],
    };

Map<String, dynamic> eyPage(List<Map<String, dynamic>> items, {int page = 1, int? total, bool hasMore = false}) =>
    {'items': items, 'page': page, 'limit': 20, 'total': total ?? items.length, 'hasMore': hasMore};

Map<String, dynamic> eySummaryJson(String id, {bool ey = true, int portfolio = 2, int observations = 0}) => ey
    ? {
        'studentId': id, 'firstName': 'Ayesha', 'lastName': 'Khan', 'isEarlyYears': true, 'programme': 'early-years',
        'grade': 'Nursery', 'section': 'A', 'keyPerson': 'Ms Sara', 'academicYear': '2025-26',
        'sharedPortfolioCount': portfolio, 'sharedObservationCount': observations, 'lastSharedAt': '2026-10-02T08:00:00.000Z',
      }
    : {'studentId': id, 'firstName': 'Ayesha', 'lastName': 'Khan', 'isEarlyYears': false, 'programme': 'k12'};
