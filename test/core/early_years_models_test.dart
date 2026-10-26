import 'dart:convert';
import 'package:eldermin_parent_app/core/models/early_years_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EySummary', () {
    test('parses an Early Years child', () {
      final s = EySummary.fromJson({
        'studentId': 's1', 'firstName': 'Ayesha', 'lastName': 'Khan', 'isEarlyYears': true, 'programme': 'early-years',
        'grade': 'Nursery', 'section': 'A', 'keyPerson': 'Ms Sara', 'academicYear': '2025-26',
        'sharedPortfolioCount': 3, 'sharedObservationCount': 1, 'lastSharedAt': '2026-10-02T08:00:00.000Z',
      });
      expect(s.isEarlyYears, isTrue);
      expect(s.classLabel, 'Nursery - A');
      expect(s.keyPerson, 'Ms Sara');
      expect(s.sharedPortfolioCount, 3);
      expect(s.lastSharedAt, isNotNull);
    });

    test('a child outside Early Years carries only the basics and no counts', () {
      final s = EySummary.fromJson({'studentId': 's1', 'firstName': 'A', 'lastName': 'B', 'isEarlyYears': false, 'programme': 'k12'});
      expect(s.isEarlyYears, isFalse);
      expect(s.sharedPortfolioCount, 0);
      expect(s.classLabel, '');
      expect(s.keyPerson, isNull);
    });

    test('anything but a literal true is not Early Years; junk values do not throw', () {
      expect(EySummary.fromJson({'studentId': 's', 'isEarlyYears': 'true'}).isEarlyYears, isFalse);
      expect(EySummary.fromJson({'studentId': 's', 'isEarlyYears': null}).isEarlyYears, isFalse);
      final s = EySummary.fromJson({'studentId': 's', 'isEarlyYears': true, 'sharedPortfolioCount': 'x', 'lastSharedAt': 'not a date', 'keyPerson': ''});
      expect(s.sharedPortfolioCount, 0);
      expect(s.lastSharedAt, isNull);
      expect(s.keyPerson, isNull);
    });
  });

  group('portfolio and observation items', () {
    test('portfolio entry: media with a null url stays (rendered as unavailable), unknown type defaults to photo', () {
      final e = EyPortfolioEntry.fromJson({
        'id': 'e1', 'title': 'Painting', 'narrative': 'n', 'tryThisAtHome': null, 'createdAt': '2026-10-01T10:00:00.000Z',
        'media': [{'type': 'photo', 'url': 'https://x/y?sig=1', 'caption': 'c'}, {'type': 'photo', 'url': null, 'caption': null}, {'url': 'https://x/z'}, 'junk'],
      });
      expect(e.media.length, 3);
      expect(e.media[0].url, 'https://x/y?sig=1');
      expect(e.media[1].url, isNull);
      expect(e.media[2].isPhoto, isTrue);
      expect(e.tryThisAtHome, isNull);
    });

    test('observation: learning areas without a skill name are dropped', () {
      final o = EyObservation.fromJson({
        'id': 'o1', 'type': 'learning_story', 'narrative': 'Built a tower', 'nextStep': 'Count blocks', 'createdAt': '2026-10-01T10:00:00.000Z',
        'learningAreas': [{'skill': 'Pencil Control', 'level': 'Developing'}, {'skill': null, 'level': 'x'}], 'media': [],
      });
      expect(o.learningAreas.length, 1);
      expect(o.learningAreas.first.skill, 'Pencil Control');
      expect(o.nextStep, 'Count blocks');
    });

    test('sensitive-looking extra fields are ignored: nothing outside the documented fields survives parsing', () {
      const secrets = ['CARE-SECRET', 'ALLERGY-SECRET', 'SUPPORT-SECRET', 'MEDICATION-SECRET', 'STAFF-NAME', 'INTERNAL-NOTE'];
      final raw = {
        'id': 'e1', 'title': 'T', 'narrative': 'N', 'createdAt': '2026-10-01T10:00:00.000Z',
        'careNote': 'CARE-SECRET', 'allergies': ['ALLERGY-SECRET'], 'supportCase': {'concern': 'SUPPORT-SECRET'},
        'medicationGiven': [{'name': 'MEDICATION-SECRET'}], 'observedBy': 'STAFF-NAME', 'context': 'INTERNAL-NOTE', 'familyResponse': {'text': 'INTERNAL-NOTE'},
        'media': [{'type': 'photo', 'url': 'https://x/y', 'caption': 'c', 'allergy': 'ALLERGY-SECRET'}],
      };
      final e = EyPortfolioEntry.fromJson(raw);
      final o = EyObservation.fromJson({...raw, 'type': 'spontaneous', 'learningAreas': [{'skill': 'S', 'level': 'L', 'care': 'CARE-SECRET'}]});
      final s = EySummary.fromJson({'studentId': 's', 'isEarlyYears': true, ...raw});
      final dump = jsonEncode([
        [e.id, e.title, e.narrative, e.tryThisAtHome, e.createdAt?.toIso8601String(), for (final m in e.media) [m.type, m.url, m.caption]],
        [o.id, o.type, o.narrative, o.nextStep, for (final a in o.learningAreas) [a.skill, a.level], for (final m in o.media) [m.type, m.url, m.caption]],
        [s.studentId, s.firstName, s.lastName, s.programme, s.grade, s.section, s.keyPerson, s.academicYear],
      ]);
      for (final x in secrets) {
        expect(dump.contains(x), isFalse, reason: x);
      }
    });
  });

  group('EyPage', () {
    test('parses items and paging; entries without an id are dropped', () {
      final p = EyPage.parse({
        'items': [{'id': 'a', 'title': 'A', 'narrative': 'n'}, {'title': 'no id'}, 'junk'], 'page': 2, 'total': 7, 'hasMore': true,
      }, EyPortfolioEntry.fromJson, (e) => e.id);
      expect(p.items.map((e) => e.id), ['a']);
      expect(p.page, 2);
      expect(p.total, 7);
      expect(p.hasMore, isTrue);
    });

    test('a missing or odd body is an empty first page', () {
      final p = EyPage.parse({}, EyObservation.fromJson, (e) => e.id);
      expect(p.items, isEmpty);
      expect(p.page, 1);
      expect(p.hasMore, isFalse);
    });
  });
}
