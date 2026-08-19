import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_text.dart';
import '../controllers/documents_controller.dart';

class DocumentsScreen extends GetView<DocumentsController> {
  const DocumentsScreen({super.key});

  TagStyle _styleFor(String status) {
    switch (status) {
      case 'verified':
        return TagStyle.green;
      case 'expired':
        return TagStyle.red;
      default:
        return TagStyle.amber;
    }
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'report_card':
        return Icons.grade_outlined;
      case 'transfer_certificate':
        return Icons.swap_horiz_rounded;
      case 'birth_certificate':
        return Icons.child_care_outlined;
      case 'medical_report':
        return Icons.medical_information_outlined;
      case 'id_card':
        return Icons.badge_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Future<void> _open(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      CustomAppSnackbar.warning('This document has no attached file.');
      return;
    }
    final uri = Uri.tryParse(fileUrl);
    if (uri == null || !await canLaunchUrl(uri)) {
      CustomAppSnackbar.error('Could not open this document.');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
        text: 'Academic documents',
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      )),
      body: Obx(() {
        if (controller.loading.value && controller.documents.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(withChip: false),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(6),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }

        final documents = controller.documents;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(title: 'Academic documents', caption: 'Certificates and records on file'),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${documents.length}', 'Documents', null),
                (
                  '${documents.where((d) => Map<String, dynamic>.from(d as Map)['status'] == 'verified').length}',
                  'Verified',
                  null
                ),
                (
                  '${documents.where((d) => Map<String, dynamic>.from(d as Map)['status'] == 'pending').length}',
                  'Pending',
                  null
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              if (documents.isEmpty)
                const AppEmptyView(
                  icon: Icons.folder_off_outlined,
                  title: 'No documents on file',
                  subtitle: 'Documents uploaded by the school will appear here.',
                )
              else
                ...documents.map((raw) {
                  final d = Map<String, dynamic>.from(raw as Map);
                  final status = d['status']?.toString() ?? 'pending';
                  final type = d['type']?.toString() ?? '';
                  final uploadedAt = DateTime.tryParse(d['uploadedAt']?.toString() ?? '');
                  return ListCardRow(
                    icon: _iconFor(type),
                    title: d['name']?.toString() ?? 'Document',
                    subtitle: [
                      if (type.isNotEmpty) type.replaceAll('_', ' '),
                      if (uploadedAt != null) 'uploaded ${uploadedAt.day}/${uploadedAt.month}/${uploadedAt.year}',
                    ].join(' · '),
                    trailing: AppTag(status[0].toUpperCase() + status.substring(1), style: _styleFor(status)),
                    onTap: () => _open(d['fileUrl']?.toString()),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
