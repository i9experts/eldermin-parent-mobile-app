import 'dart:async';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/p5_fixtures.dart';
import '../support/route_harness.dart';

/// PROOF that the layout rebuild drops no Map key: every key a P5 view reads carries a distinct sentinel value in the
/// fixtures (`test/support/p5_fixtures.dart`); each test asserts that value is rendered (or, for a key that is used rather than
/// shown, that its effect happens). The same assertions pass on the pre-redesign screens and on the rebuilt ones.
Future<FakeClientHandle> _open(WidgetTester t, String route, {double w = 390, double h = 844, double scale = 1, Map<String, dynamic>? profile}) async {
  final client = setUpRouteDeps(p5Api(profile: profile));
  await pumpApp(t, width: w, height: h, textScale: scale);
  unawaited(Get.toNamed(route));
  await settle(t);
  return client;
}

typedef FakeClientHandle = FakeClient;

Finder _text(String s) => find.textContaining(s);

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(f, 200, scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
  }
}

void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  for (final (w, h, scale) in [(390.0, 3200.0, 1.0), (320.0, 3200.0, 1.3)]) {
    group('PTM keys @${w}dp @${scale}x', () {
      testWidgets('teacherName, status, scheduledDate, startTime, endTime, discussionPoints, meetingNotes, actionItems (description + status) are all shown', (t) async {
        await _open(t, Routes.ptm, w: w, h: h, scale: scale);
        for (final s in [
          'TeacherSentinelOne', // teacherName
          'requested', // status -> tag
          '5/11/2026', // scheduledDate
          '10:15–10:45', // startTime + endTime
          'PointSentinelA', 'PointSentinelB', // discussionPoints
          'NotesSentinel', // meetingNotes
          'ActionSentinelDone', 'ActionSentinelOpen', // actionItems[].description
        ]) {
          await _scrollTo(t, _text(s));
          expect(_text(s), findsWidgets, reason: s);
        }
        expect(find.text('Done'), findsWidgets, reason: 'actionItems[].status == done');
        expect(find.text('Pending'), findsWidgets, reason: 'actionItems[].status != done');
        for (final s in ['no show', 'completed', 'confirmed']) {
          await _scrollTo(t, find.text(s));
          expect(find.text(s), findsWidgets, reason: 'status $s (underscore -> space)');
        }
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });

      testWidgets('_id is used by Cancel request (requested / confirmed only), and the counts come from status', (t) async {
        final client = await _open(t, Routes.ptm, w: w, h: h, scale: scale);
        expect(find.text('Cancel request'), findsNWidgets(2), reason: 'requested + confirmed');
        // Total 4, Upcoming 2 (requested + confirmed), Completed 1
        expect(find.text('4'), findsWidgets);
        await t.tap(find.text('Cancel request').first);
        await settle(t);
        expect(client.calls.where((c) => c.startsWith('POST') && c.contains('/ptm/$ptmMeetingId/cancel')).length, 1);
        await t.pump(const Duration(seconds: 4));
        await disposeApp(t);
      });
    });

    group('Leaves keys @${w}dp @${scale}x', () {
      testWidgets('status, fromDate, toDate, reason, approverName + approverNote (not for pending) are shown', (t) async {
        await _open(t, Routes.leaves, w: w, h: h, scale: scale);
        for (final s in [
          'ReasonSentinelApproved', 'ReasonSentinelPending', 'ReasonSentinelRejected', // reason
          '2/11 – 4/11/2026', // fromDate + toDate range
          '10/11/2026', // same-day range
          '5/10 – 6/10/2026',
          'ApproverSentinel: ApproverNoteSentinel', // approverName + approverNote
          'School: RejectNoteSentinel', // approverName missing -> "School"
        ]) {
          await _scrollTo(t, _text(s));
          expect(_text(s), findsWidgets, reason: s);
        }
        expect(_text('HiddenNote'), findsNothing, reason: 'a pending request shows no approver note');
        for (final tag in ['Approved', 'Pending', 'Rejected']) {
          await _scrollTo(t, find.text(tag));
          expect(find.text(tag), findsWidgets, reason: 'status tag $tag');
        }
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });
    });

    group('Profile keys @${w}dp @${scale}x', () {
      testWidgets('every profile key is rendered or used', (t) async {
        await _open(t, Routes.profile, w: w, h: h, scale: scale);
        for (final s in [
          'FirstSent LastSent', // firstName + lastName
          'Grade GradeSent', 'Section SecSent', 'Roll RollSent', // currentGrade / currentSection / currentRollNumber
          'Active', // status
          'AdmissionSent', // admissionNumber
          '4/3/2015', // dateOfBirth
          'GenderSent', // gender
          'BGSent', // medical.bloodGroup
          'HouseSent', // houseGroup
          'ClassTeacherSent', // classTeacher
          'GuardianSentOne', 'RelationSent', 'PhoneSent', // guardians[0] name / relation / phone
          'GuardianSentTwo', 'RelTwoSent', // guardians[1]
        ]) {
          await _scrollTo(t, _text(s));
          expect(_text(s), findsWidgets, reason: s);
        }
        expect(find.text('Primary'), findsOneWidget, reason: 'guardians[0].isPrimary');
        // documents (3) and guardians (2) are counted; completeness comes from 7 core fields (all present: 100 %)
        await t.scrollUntilVisible(find.text('Guardians'), -200, scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
        expect(find.text('3'), findsWidgets, reason: 'documents.length');
        expect(find.text('2'), findsWidgets, reason: 'guardians.length');
        expect(find.text('100%'), findsWidgets, reason: 'profile completeness');
        // photoUrl is handed to the avatar
        final avatar = t.widget<EmAvatar>(find.byType(EmAvatar).first);
        expect(avatar.imageUrl, 'https://example.com/PhotoSent.png');
        expect(avatar.initials, 'FL');
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });

      testWidgets('the legacy `photo` key is used when photoUrl is absent; missing fields show a dash; completeness drops', (t) async {
        final p = profileBody()
          ..remove('photoUrl')
          ..['photo'] = 'https://example.com/LegacyPhoto.png'
          ..remove('gender')
          ..remove('houseGroup')
          ..remove('classTeacher')
          ..['medical'] = <String, dynamic>{};
        await _open(t, Routes.profile, w: w, h: h, scale: scale, profile: p);
        expect(t.widget<EmAvatar>(find.byType(EmAvatar).first).imageUrl, 'https://example.com/LegacyPhoto.png');
        await _scrollTo(t, find.text('Record details'));
        expect(find.text('—'), findsWidgets, reason: 'gender / house group / class teacher / blood group are missing');
        // 5 of the 7 core fields are present -> 71 %
        await t.scrollUntilVisible(find.text('Profile complete'), -200, scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
        expect(find.text('71%'), findsWidgets);
        await disposeApp(t);
      });
    });

    group('Dues keys @${w}dp @${scale}x', () {
      testWidgets('invoiceNumber, dueDate, academicYear, balanceDue, paidAmount, lateFine drive exactly the text shown today', (t) async {
        await _open(t, Routes.dues, w: w, h: h, scale: scale);
        for (final s in [
          'INV-SENT-1', 'INV-SENT-2', 'INV-SENT-3', // invoiceNumber
          'Due 10/11/2026', 'Due 1/9/2026', 'Due 31/12/2026', // dueDate
          '2026-27', // academicYear
          'Rs 1751', // current outstanding / Due: 1500 + 0 + 250.5 -> toStringAsFixed(0)
          'Rs 2500', // Paid: 500 + 2000 + 0
          'Rs 85', // Late fee: 75 + 0 + 10
          'Rs 2500 of Rs 4251 paid', // Annual payment progress: totalBilled = paid + due
          'Due by 10/11/2026', // earliest due date with a balance
        ]) {
          await _scrollTo(t, _text(s));
          expect(_text(s), findsWidgets, reason: s);
        }
        expect(find.text('Unpaid'), findsNWidgets(2), reason: 'balanceDue > 0 (1500, 250.5)');
        expect(find.text('Paid'), findsWidgets);
        expect(find.text('59%'), findsWidgets, reason: 'percent paid: 2500 / 4251');
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });
    });
  }
}
