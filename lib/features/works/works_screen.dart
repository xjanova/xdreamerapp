import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/press.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../routing/app_router.dart';
import '../../state/gallery_controller.dart';
import '../shell/app_shell.dart';
import 'work_card.dart';
import 'work_viewer.dart';

class WorksScreen extends ConsumerStatefulWidget {
  const WorksScreen({super.key});

  @override
  ConsumerState<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends ConsumerState<WorksScreen> {
  final _scroll = ScrollController();
  GalleryFilter _filter = GalleryFilter.all;

  GalleryScope get _scope => (filter: _filter, sort: GallerySort.newest);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    // Start the next page a screenful early so the grid never visibly stalls.
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      ref.read(galleryControllerProvider(_scope).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    final state = ref.watch(galleryControllerProvider(scope));
    final controller = ref.read(galleryControllerProvider(scope).notifier);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      color: XdrColors.ice,
      backgroundColor: XdrColors.wellFill,
      onRefresh: controller.refresh,
      child: XdrEnter(
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ผลงานของฉัน', style: XdrType.pageTitle()),
                    const SizedBox(width: 9),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        state.loading ? '' : '${groupDigits(state.total)} ชิ้น',
                        style: XdrType.thai(size: 11, color: XdrColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  itemCount: GalleryFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (context, i) {
                    final filter = GalleryFilter.values[i];
                    final active = filter == _filter;
                    return PressSink(
                      radius: 999,
                      depth: 2,
                      onTap: () => setState(() => _filter = filter),
                      child: MetalSurface(
                        finish: active ? MetalFinish.anodized : MetalFinish.keycap,
                        radius: 999,
                        dropShadows: false,
                        borderColor: active ? XdrColors.ice.withValues(alpha: 0.4) : null,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        child: Center(
                          child: Text(
                            filter.labelTh,
                            style: XdrType.thai(
                              size: 12,
                              weight: active ? FontWeight.w600 : FontWeight.w400,
                              color: active ? XdrColors.ice : XdrColors.textMuted,
                            ).copyWith(shadows: engraved),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            if (state.loading)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
                sliver: _SkeletonGrid(),
              )
            else if (state.error != null && state.items.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: ErrorPanel(message: state.error!, onRetry: controller.refresh),
                ),
              )
            else if (state.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: _filter == GalleryFilter.all ? 'ยังไม่มีผลงาน' : 'ไม่มีผลงานในหมวดนี้',
                  body: 'เริ่มจากใส่คำอธิบายภาพที่อยากได้ในสตูดิโอ แล้วกดสร้าง',
                  actionLabel: 'ไปที่สตูดิโอ',
                  onAction: () => context.go(Routes.studio),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    // Alternating heights would need a real masonry sliver;
                    // a fixed 3:4 keeps the grid honest and the scroll smooth.
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(childCount: state.items.length, (
                    context,
                    i,
                  ) {
                    final item = state.items[i];
                    return WorkCard(
                      item: item,
                      height: double.infinity,
                      onTap: () => WorkViewer.open(
                        context,
                        item: item,
                        onToggleFavourite: () => controller.toggleFavourite(item),
                      ),
                      onToggleFavourite: () => controller.toggleFavourite(item),
                    );
                  }),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 16, 14, bottomInset + 20),
                child: state.loadingMore
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: XdrColors.ice),
                        ),
                      )
                    : state.hasMore
                    ? GhostButton(
                        label: 'โหลดเพิ่ม · Load more',
                        fontSize: 13,
                        onPressed: controller.loadMore,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      delegate: SliverChildBuilderDelegate(
        childCount: 6,
        (context, i) => ShimmerTile(radius: 16, index: i % 4),
      ),
    );
  }
}
