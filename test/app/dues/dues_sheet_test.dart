import 'package:eldermin_parent_app/app/modules/dues/views/dues_detail_sheet.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/widgets/detail_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/route_harness.dart';

Map<String, dynamic> invoice({String status = 'partial', num balance = 1500, Map<String, dynamic> extra = const {}}) => {
      'invoiceNumber': 'INV-2026-0042',
      'type': 'fee',
      'month': '2026-11',
      'academicYear': '2026-27',
      'dueDate': '2026-11-10T00:00:00.000Z',
      'status': status,
      'items': [
        {'description': 'Tuition', 'feeHead': 'Tuition fee', 'amount': 4000, 'discount': 500, 'netAmount': 3500},
        {'description': 'Lab', 'amount': 250.5, 'discount': 0},
      ],
      'subtotal': 4250.5,
      'totalDiscount': 500,
      'totalTax': 0,
      'lateFine': 75,
      'totalAmount': 3825.5,
      'paidAmount': 2325.5,
      'balanceDue': balance,
      // internal fields that must never be shown
      'notes': 'INTERNAL: chase the parent',
      'exchangeRate': 1.7,
      'baseCurrencyAmount': 99999,
      'createdBy': 'finance-user-id',
      ...extra,
    };

String? value(DetailSheetData d, String label) => d.fields.where((f) => f.label == label).firstOrNull?.value;

void main() {
  group('duesSheetData', () {
    test('status chip: paid, partial, overdue, unpaid, waived', () {
      expect(duesSheetData(invoice(status: 'paid', balance: 0)).statusLabel, 'Paid');
      expect(duesSheetData(invoice(status: 'partial')).statusLabel, 'Partially paid');
      expect(duesSheetData(invoice(status: 'overdue')).statusLabel, 'Overdue');
      expect(duesSheetData(invoice(status: 'overdue')).statusTone, EmTone.error);
      expect(duesSheetData(invoice(status: 'sent')).statusLabel, 'Unpaid');
      expect(duesSheetData(invoice(status: 'waived', balance: 0)).statusLabel, 'Waived');
    });

    test('money, dates and optional amounts', () {
      final d = duesSheetData(invoice());
      expect(d.title, 'INV-2026-0042');
      expect(value(d, 'Type'), 'Fee');
      expect(value(d, 'Month'), 'Nov 2026');
      expect(value(d, 'Due date'), '10 Nov 2026');
      expect(value(d, 'Subtotal'), 'Rs 4250.50');
      expect(value(d, 'Discount'), 'Rs 500');
      expect(value(d, 'Tax'), isNull); // zero => hidden
      expect(value(d, 'Late fine'), 'Rs 75');
      expect(value(d, 'Total'), 'Rs 3825.50');
      expect(value(d, 'Paid'), 'Rs 2325.50');
      expect(value(d, 'Balance due'), 'Rs 1500');
    });

    test('fee items list the head, the net amount and any discount', () {
      final items = duesSheetData(invoice()).sections.single;
      expect(items.title, 'Fee items');
      expect([for (final f in items.fields) '${f.label}=${f.value}'], ['Tuition fee=Rs 3500 (after Rs 500 discount)', 'Lab=Rs 250.50']);
    });

    test('a foreign currency code replaces "Rs"', () {
      expect(value(duesSheetData(invoice(extra: {'currencyCode': 'USD'})), 'Total'), 'USD 3825.50');
    });

    test('internal fields are never part of the sheet', () {
      final d = duesSheetData(invoice());
      final all = [d.title, ...d.fields.map((f) => '${f.label} ${f.value}'), ...d.sections.expand((s) => s.fields.map((f) => '${f.label} ${f.value}'))].join(' | ');
      for (final secret in ['INTERNAL', '1.7', '99999', 'finance-user-id']) {
        expect(all, isNot(contains(secret)));
      }
    });

    test('a bare invoice does not crash and hides what is missing', () {
      final d = duesSheetData({'invoiceNumber': 'X'});
      expect(d.fields.where((f) => f.visible), isEmpty);
      expect(d.sections, isEmpty);
    });
  });

  testWidgets('tapping an invoice row opens the sheet with that invoice', (t) async {
    setUpRouteDeps((m, u) => u.endsWith('/dues') ? [invoice(), {...invoice(status: 'paid', balance: 0), 'invoiceNumber': 'INV-2026-0001'}] : <dynamic>[]);
    await pumpRoute(t, Routes.dues);
    expect(find.byKey(const Key('detail_sheet')), findsNothing);
    await t.ensureVisible(find.text('INV-2026-0042'));
    await t.tap(find.text('INV-2026-0042'));
    await settle(t);
    final sheet = find.byKey(const Key('detail_sheet'));
    expect(sheet, findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('INV-2026-0042')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Partially paid')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Rs 1500')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Fee items')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.textContaining('INTERNAL')), findsNothing);
    t.state<NavigatorState>(find.byType(Navigator).first).pop(); // close the sheet, stay on the screen
    await settle(t);
    await t.ensureVisible(find.text('INV-2026-0001'));
    await t.tap(find.text('INV-2026-0001'));
    await settle(t);
    expect(find.descendant(of: find.byKey(const Key('detail_sheet')), matching: find.text('INV-2026-0001')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('detail_sheet')), matching: find.text('Paid')), findsWidgets);
    t.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(t);
    await disposeApp(t);
  });
}
