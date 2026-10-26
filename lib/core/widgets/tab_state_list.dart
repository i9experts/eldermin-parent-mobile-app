import 'package:flutter/material.dart';
import '../design/design.dart';
import 'app_widgets.dart';
import 'locked_feature_view.dart';
import 'shimmer_widgets.dart';

/// The state of a tab root's list. The caller maps its controller to one of these in the app's fixed precedence:
/// loading, then error, then locked, then empty / data.
enum TabListState { loading, error, locked, empty, data }

/// A tab root's scrolling body in the teacher app's pattern: a [RefreshIndicator] over an always-scrollable [ListView]
/// that shows the [header] (tab title, chips ...) in EVERY state, then the state body (skeleton, error with retry,
/// locked, empty, or the data children). Ported from `design-kit-v1` `lib/core/widgets/screen_state_view.dart:12-102`
/// (`ScreenStateView`), without its teacher-only 403 / 404 states.
class TabStateList extends StatelessWidget {
  const TabStateList({
    super.key,
    required this.state,
    required this.onRefresh,
    this.header = const [],
    this.skeleton,
    this.skeletonRows = 5,
    this.errorMessage,
    this.onRetry,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Nothing here',
    this.emptySubtitle,
    this.data = const [],
  });

  final TabListState state;
  final Future<void> Function() onRefresh;

  /// Always shown above the state body.
  final List<Widget> header;

  /// Loading layout (wrapped in the shimmer); defaults to [skeletonRows] list-row skeletons.
  final List<Widget>? skeleton;
  final int skeletonRows;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final List<Widget> data;

  Widget _centered(Widget child) => Padding(padding: const EdgeInsets.only(top: EmSpacing.s24), child: child);

  List<Widget> _body() {
    switch (state) {
      case TabListState.loading:
        return [
          AppShimmer(
            key: const Key('screen_loading'),
            child: Column(children: skeleton ?? List.generate(skeletonRows, (_) => const ShimmerListRowSkeleton())),
          ),
        ];
      case TabListState.error:
        return [_centered(AppErrorView(key: const Key('screen_error'), message: errorMessage ?? 'Something went wrong', onRetry: onRetry))];
      case TabListState.locked:
        return [_centered(const LockedFeatureView())];
      case TabListState.empty:
        return [_centered(AppEmptyView(key: const Key('screen_empty'), icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle))];
      case TabListState.data:
        return data;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EmSpacing.listPadding,
        children: [...header, ..._body()],
      ),
    );
  }
}
