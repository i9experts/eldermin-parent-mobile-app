import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import '../../../../core/utils/detail_format.dart';
import '../../../../core/widgets/detail_bottom_sheet.dart';

num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

String _capitalise(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Opens the invoice detail sheet (read-only: there is no payment flow in the app).
Future<void> showDuesDetailSheet(BuildContext context, Map<String, dynamic> invoice) =>
    DetailBottomSheet.show<void>(context, data: () => duesSheetData(invoice));

/// What the sheet shows for [invoice]. Only fields meant for the family: the invoice also carries internal ones (notes, exchange rate, base
/// currency amount, creator) that are deliberately not shown.
DetailSheetData duesSheetData(Map<String, dynamic> invoice) {
  final cur = invoice['currencyCode']?.toString().trim();
  final currency = cur == null || cur.isEmpty ? 'Rs' : cur;
  String money(num v) => formatMoney(v, currency: currency);
  String? positive(dynamic v) => _n(v) > 0 ? money(_n(v)) : null;

  final balance = _n(invoice['balanceDue']);
  final status = invoice['status']?.toString() ?? '';
  final (label, tone) = switch (status) {
    'paid' => ('Paid', EmTone.success),
    'overdue' => ('Overdue', EmTone.error),
    'partial' => ('Partially paid', EmTone.warning),
    'waived' => ('Waived', EmTone.neutral),
    _ => balance > 0 ? ('Unpaid', EmTone.warning) : ('Paid', EmTone.success),
  };

  final items = [for (final i in (invoice['items'] as List? ?? const [])) Map<String, dynamic>.from(i as Map)];
  return DetailSheetData(
    title: invoice['invoiceNumber']?.toString() ?? 'Invoice',
    statusLabel: label,
    statusTone: tone,
    fields: [
      DetailField('Type', _capitalise(invoice['type']?.toString() ?? '')),
      DetailField('Month', formatMonthOf(invoice['month'])),
      DetailField('Academic year', invoice['academicYear']?.toString()),
      DetailField('Due date', formatDayOf(invoice['dueDate'], utcDay: true)),
      DetailField('Subtotal', positive(invoice['subtotal'])),
      DetailField('Discount', positive(invoice['totalDiscount'])),
      DetailField('Tax', positive(invoice['totalTax'])),
      DetailField('Late fine', positive(invoice['lateFine'])),
      DetailField('Total', invoice['totalAmount'] == null ? null : money(_n(invoice['totalAmount']))),
      DetailField('Paid', invoice['paidAmount'] == null ? null : money(_n(invoice['paidAmount']))),
      DetailField('Balance due', invoice['balanceDue'] == null ? null : money(balance)),
    ],
    sections: [
      if (items.isNotEmpty)
        DetailSection('Fee items', [
          for (final i in items)
            DetailField(
              (i['feeHead'] ?? i['description'])?.toString() ?? 'Item',
              _n(i['discount']) > 0
                  ? '${money(_n(i['netAmount'] ?? (_n(i['amount']) - _n(i['discount']))))} (after ${money(_n(i['discount']))} discount)'
                  : money(_n(i['netAmount'] ?? i['amount'])),
            ),
        ]),
    ],
  );
}
