// P1: null-safe parsing of what the parent portal sends, kind derivation, sorting, filters.
import 'package:eldermin_parent_app/core/models/behaviour_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParentBehaviourRecord.fromJson', () {
    test('the allowlisted fields parse', () {
      final r = ParentBehaviourRecord.fromJson({
        '_id': 'r1', 'studentId': 's1', 'date': '2026-09-15T00:00:00.000Z', 'type': 'negative', 'category': 'late_coming', 'title': 'Late', 'description': 'Came after the bell', 'points': -2,
      });
      expect(r.id, 'r1');
      expect(r.kind, BehaviourKind.concern);
      expect(r.points, -2);
      expect(r.date!.toUtc().day, 15);
      expect(r.displayTitle, 'Late');
    });

    test('an empty map, null and a non-map never throw and give neutral defaults', () {
      for (final raw in [<String, dynamic>{}, null, 'oops', 5, <dynamic>[]]) {
        final r = ParentBehaviourRecord.fromJson(raw);
        expect(r.id, '');
        expect(r.date, isNull);
        expect(r.points, 0);
        expect(r.kind, BehaviourKind.note);
        expect(r.displayTitle, 'Observation');
        expect(r.description, '');
      }
    });

    test('wrongly typed fields: points as a string / double / junk, literal "null" text, bad date', () {
      expect(ParentBehaviourRecord.fromJson({'points': '3'}).points, 3);
      expect(ParentBehaviourRecord.fromJson({'points': 2.6}).points, 3);
      expect(ParentBehaviourRecord.fromJson({'points': 'abc'}).points, 0);
      expect(ParentBehaviourRecord.fromJson({'points': null}).points, 0);
      expect(ParentBehaviourRecord.fromJson({'title': 'null', 'description': null}).title, '');
      expect(ParentBehaviourRecord.fromJson({'date': 'not a date'}).date, isNull);
      expect(ParentBehaviourRecord.fromJson({'title': 12}).title, '12');
    });

    test('kind: the school\'s type wins, else the sign of the points', () {
      expect(ParentBehaviourRecord.fromJson({'type': 'positive', 'points': -1}).kind, BehaviourKind.merit);
      expect(ParentBehaviourRecord.fromJson({'type': 'neutral', 'points': 5}).kind, BehaviourKind.note);
      expect(ParentBehaviourRecord.fromJson({'points': 4}).kind, BehaviourKind.merit);
      expect(ParentBehaviourRecord.fromJson({'points': -4}).kind, BehaviourKind.concern);
      expect(ParentBehaviourRecord.fromJson({'type': 'unheard_of', 'points': 0}).kind, BehaviourKind.note);
    });

    test('title falls back to a readable category, then to a generic word', () {
      expect(ParentBehaviourRecord.fromJson({'category': 'helping_others'}).displayTitle, 'Helping others');
      expect(ParentBehaviourRecord.fromJson({'category': 'brand_new'}).displayTitle, 'Brand new');
      expect(categoryLabel(''), '');
    });

    test('a teacher note carries its source and action taken', () {
      final r = ParentBehaviourRecord.fromJson({'source': 'teacher_note', 'actionTaken': 'Spoke to him', 'type': 'negative'});
      expect(r.source, 'teacher_note');
      expect(r.actionTaken, 'Spoke to him');
    });
  });

  group('TarbiyahReport.fromJson', () {
    test('a full allowlisted assessment', () {
      final a = TarbiyahReport.fromJson({
        '_id': 't1', 'period': 'Term 1', 'periodType': 'termly', 'assessmentDate': '2026-09-10T00:00:00.000Z',
        'traits': [{'traitKey': 'sidq', 'traitName': 'Truthfulness', 'percentage': 75, 'score': 4, 'observation': 'Honest'}],
        'overallPercentage': 75, 'overallScore': 4, 'overallRating': 'good', 'teacherObservations': 'Doing well', 'areasOfStrength': ['Honesty'],
        'areasForImprovement': ['Focus'], 'recommendedActions': 'Read at home', 'programName': 'Tarbiyah', 'ratingScale': {'min': 1, 'max': 5},
      });
      expect(a.displayPeriod, 'Term 1');
      expect(a.traits.single.name, 'Truthfulness');
      expect(a.traits.single.observation, 'Honest');
      expect(a.overallPercentage, 75);
      expect(a.ratingLabel, 'Good');
      expect(a.areasForImprovement, ['Focus']);
      expect(a.recommendedActions, 'Read at home');
      expect(a.scaleMax, 5);
      expect(a.hasAnyContent, isTrue);
    });

    test('a bare / junk assessment does not throw and says so', () {
      for (final raw in [<String, dynamic>{}, null, 7, 'x']) {
        final a = TarbiyahReport.fromJson(raw);
        expect(a.displayPeriod, 'Assessment');
        expect(a.traits, isEmpty);
        expect(a.overallPercentage, isNull);
        expect(a.hasAnyContent, isFalse);
        expect(a.ratingLabel, '');
      }
    });

    test('traits: a missing name falls back to the readable key, percentage clamps to 0-100, junk entries are skipped', () {
      final a = TarbiyahReport.fromJson({
        'traits': [{'traitKey': 'adab'}, {'traitKey': 'helps_others', 'percentage': 250}, {'traitKey': 'x', 'percentage': -5}, 'junk', null, {'percentage': '60'}],
      });
      expect(a.traits.map((t) => t.name), ['Adab', 'Helps others', 'X', 'Trait']);
      expect(a.traits.map((t) => t.percentage), [0, 100, 0, 60]);
    });

    test('lists tolerate null / non-lists / blank entries; period falls back to the period type', () {
      final a = TarbiyahReport.fromJson({'areasOfStrength': null, 'areasForImprovement': 'oops', 'periodType': 'monthly'});
      expect(a.areasOfStrength, isEmpty);
      expect(a.areasForImprovement, isEmpty);
      expect(a.displayPeriod, 'Monthly assessment');
      expect(TarbiyahReport.fromJson({'areasOfStrength': ['A', '', null, '  ', 'B']}).areasOfStrength, ['A', 'B']);
    });

    test('rating labels, including a value this version does not know', () {
      expect(TarbiyahReport.fromJson({'overallRating': 'needs_improvement'}).ratingLabel, 'Needs improvement');
      expect(TarbiyahReport.fromJson({'overallRating': 'critical'}).ratingLabel, 'Needs support');
      expect(TarbiyahReport.fromJson({'overallRating': 'outstanding_plus'}).ratingLabel, 'Outstanding plus');
    });
  });

  group('BehaviourAndTarbiyah.fromJson', () {
    test('records and assessments come out newest first; undated ones last', () {
      final b = BehaviourAndTarbiyah.fromJson({
        'behaviourRecords': [
          {'_id': 'old', 'date': '2026-08-01T00:00:00.000Z'},
          {'_id': 'none'},
          {'_id': 'new', 'date': '2026-09-20T00:00:00.000Z'},
        ],
        'tarbiyahAssessments': [
          {'_id': 'a1', 'assessmentDate': '2026-03-01T00:00:00.000Z'},
          {'_id': 'a2', 'assessmentDate': '2026-09-01T00:00:00.000Z'},
        ],
      });
      expect(b.records.map((r) => r.id), ['new', 'old', 'none']);
      expect(b.assessments.map((a) => a.id), ['a2', 'a1']);
    });

    test('missing keys, nulls and wrong types give empty lists', () {
      for (final raw in [<String, dynamic>{}, null, 'x', {'behaviourRecords': null, 'tarbiyahAssessments': 'no'}]) {
        final b = BehaviourAndTarbiyah.fromJson(raw);
        expect(b.records, isEmpty);
        expect(b.assessments, isEmpty);
      }
    });

    test('a list that contains junk still parses the good rows', () {
      final b = BehaviourAndTarbiyah.fromJson({'behaviourRecords': [null, 'x', {'_id': 'ok', 'title': 'T'}]});
      expect(b.records.where((r) => r.id == 'ok'), hasLength(1));
    });
  });

  group('RecordFilter', () {
    final merit = ParentBehaviourRecord.fromJson({'type': 'positive', 'date': '2026-09-10T00:00:00.000Z'});
    final concern = ParentBehaviourRecord.fromJson({'type': 'negative', 'date': '2026-09-20T00:00:00.000Z'});
    final undated = ParentBehaviourRecord.fromJson({'type': 'neutral'});

    test('none accepts everything and is inactive', () {
      expect(RecordFilter.none.isActive, isFalse);
      for (final r in [merit, concern, undated]) {
        expect(RecordFilter.none.accepts(r), isTrue);
      }
    });

    test('kind filter', () {
      const f = RecordFilter(kind: BehaviourKind.concern);
      expect([merit, concern, undated].where(f.accepts), [concern]);
      expect(f.count, 1);
    });

    test('date range is inclusive on both ends, by calendar day', () {
      expect(RecordFilter(from: DateTime(2026, 9, 10), to: DateTime(2026, 9, 10)).accepts(merit), isTrue);
      expect(RecordFilter(from: DateTime(2026, 9, 11)).accepts(merit), isFalse);
      expect(RecordFilter(to: DateTime(2026, 9, 19)).accepts(concern), isFalse);
      expect(RecordFilter(from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 30)).accepts(concern), isTrue);
    });

    test('a record without a date never passes a date filter', () {
      expect(RecordFilter(from: DateTime(2020)).accepts(undated), isFalse);
      expect(const RecordFilter(kind: BehaviourKind.note).accepts(undated), isTrue);
    });

    test('copyWith sets and clears independently', () {
      const f = RecordFilter(kind: BehaviourKind.merit);
      final g = f.copyWith(from: DateTime(2026, 1, 1));
      expect(g.kind, BehaviourKind.merit);
      expect(g.from, isNotNull);
      expect(g.copyWith(kind: null).kind, isNull);
      expect(g.copyWith(kind: null).from, isNotNull);
    });
  });

  test('the server limits are the ones the backend applies (parent-portal.service.ts: 50 records, 20 assessments)', () {
    expect(kParentRecordsServerLimit, 50);
    expect(kParentAssessmentsServerLimit, 20);
  });
}
