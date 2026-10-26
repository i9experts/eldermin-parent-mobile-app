import 'package:eldermin_parent_app/core/constants/api_constants.dart';
import 'package:eldermin_parent_app/core/network/api_exception.dart';
import 'package:eldermin_parent_app/core/services/parent_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/early_years_fakes.dart';

void main() {
  test('only parent-portal early-years URLs are built, never a staff /ece route', () {
    expect(ApiConstants.earlyYearsSummary('s1'), endsWith('/parent-portal/students/s1/early-years/summary'));
    expect(ApiConstants.earlyYearsPortfolio('s1'), endsWith('/parent-portal/students/s1/early-years/portfolio'));
    expect(ApiConstants.earlyYearsPortfolioEntry('s1', 'e9'), endsWith('/parent-portal/students/s1/early-years/portfolio/e9'));
    expect(ApiConstants.earlyYearsObservations('s1'), endsWith('/parent-portal/students/s1/early-years/observations'));
    for (final u in [
      ApiConstants.earlyYearsSummary('s1'), ApiConstants.earlyYearsPortfolio('s1'),
      ApiConstants.earlyYearsPortfolioEntry('s1', 'e'), ApiConstants.earlyYearsObservations('s1'),
    ]) {
      expect(u.contains('/ece'), isFalse);
    }
  });

  test('service calls hit the right URLs with paging, and return decoded maps', () async {
    final client = FakeBaseClient((url, q) => url.endsWith('/summary') ? eySummaryJson('s1') : eyPage([eyItem('e1')]));
    final api = ParentApiService(client);
    expect((await api.getEarlyYearsSummary('s1'))['isEarlyYears'], true);
    await api.getEarlyYearsPortfolio('s1', page: 2, limit: 10);
    await api.getEarlyYearsObservations('s1');
    await api.getEarlyYearsEntry('s1', 'e1');
    expect(client.calls.length, 4);
    expect(client.calls.every((u) => u.contains('/parent-portal/students/s1/early-years/')), isTrue);
    expect(client.queries[1], {'page': 2, 'limit': 10});
    expect(client.queries[2], {'page': 1, 'limit': 20});
  });

  test('an undecoded JSON string body is accepted (existing _asMap behaviour)', () async {
    final api = ParentApiService(FakeBaseClient((_, __) => '{"studentId":"s1","isEarlyYears":false}'));
    expect((await api.getEarlyYearsSummary('s1'))['studentId'], 's1');
  });

  test('403 and 404 come back as ApiException with the status code; a non-map body is rejected', () async {
    for (final code in [403, 404]) {
      final api = ParentApiService(FakeBaseClient((_, __) => code));
      await expectLater(api.getEarlyYearsSummary('s1'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', code)));
    }
    final bad = ParentApiService(FakeBaseClient((_, __) => [1, 2]));
    await expectLater(bad.getEarlyYearsPortfolio('s1'), throwsA(isA<ApiException>()));
  });
}
