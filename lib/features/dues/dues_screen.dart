import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final duesListProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, studentId) async {
  final api = ref.watch(parentApiProvider);
  return api.getDues(studentId);
});

class DuesScreen extends ConsumerWidget {
  final String studentId;
  const DuesScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(duesListProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Fees & dues')),
      body: asyncData.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorView(message: 'Could not load fee invoices', onRetry: () => ref.invalidate(duesListProvider(studentId))),
        data: (invoices) {
          final unpaid = invoices.where((i) => (i['balanceDue'] ?? 0) > 0).toList();
          final totalDue = unpaid.fold<num>(0, (sum, i) => sum + (i['balanceDue'] ?? 0));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(duesListProvider(studentId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: totalDue > 0 ? AppColors.redBg : AppColors.greenBg,
                    border: Border.all(color: totalDue > 0 ? AppColors.red : AppColors.green),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total outstanding', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('Rs ${totalDue.toStringAsFixed(0)}', style: TextStyle(color: totalDue > 0 ? AppColors.red : AppColors.green, fontSize: 22, fontWeight: FontWeight.w800)),
                  ]),
                ),
                const SizedBox(height: AppSpacing.md),
                if (invoices.isEmpty)
                  const AppEmptyView(icon: Icons.receipt_long_outlined, title: 'No invoices on file')
                else
                  ...invoices.map((inv) {
                    final due = inv['dueDate'] != null ? DateTime.tryParse(inv['dueDate'].toString()) : null;
                    final isUnpaid = (inv['balanceDue'] ?? 0) > 0;
                    return AppCard(
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inv['invoiceNumber'] ?? 'Invoice', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.navy)),
                              const SizedBox(height: 3),
                              Text(due != null ? 'Due ${due.day}/${due.month}/${due.year}' : '', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                            ],
                          ),
                        ),
                        AppTag(isUnpaid ? 'Unpaid' : 'Paid', style: isUnpaid ? TagStyle.red : TagStyle.green),
                      ]),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
