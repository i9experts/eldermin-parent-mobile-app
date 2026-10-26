import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A golden comparator that accepts a small pixel difference. Screens that print the current month or date (the month chip,
/// "Today", the calendar grid) differ by a few glyphs from one month to the next, which must not fail the suite; a real
/// layout change moves far more than [tolerance] (a fraction, 0.02 = 2 % of the pixels).
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.tolerance = 0.02});
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

void useTolerantGoldens(Uri testFile, {double tolerance = 0.02}) {
  goldenFileComparator = TolerantGoldenComparator(testFile, tolerance: tolerance);
}
