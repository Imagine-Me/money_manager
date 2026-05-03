import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/report_filter_entity.dart';

class ReportDetailSection extends ConsumerWidget {
  const ReportDetailSection({
    super.key,
    required this.entity,
    this.embedded = false,
    this.onOpenFormSheet,
  });

  final ReportFilterEntity entity;
  final bool embedded;
  final void Function(BuildContext outer, ReportFilterEntity? initial)?
      onOpenFormSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}

/// Single-report screen (e.g. deep link). Reports tab uses [ReportDetailSection]
/// embedded in [ReportListView] instead.
class ReportDetailView extends StatelessWidget {
  const ReportDetailView({super.key, required this.entity});

  final ReportFilterEntity entity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: SizedBox.expand(),
      ),
    );
  }
}
