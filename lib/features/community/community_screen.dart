import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/press.dart';
import '../../data/models/generation.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../routing/app_router.dart';
import '../../state/auth_controller.dart';
import '../../state/gallery_controller.dart';
import '../shell/brand_mark.dart';
import '../works/work_card.dart';
import '../works/work_viewer.dart';

/// Highlights, ranked by how often work has been favourited.
///
/// **This is not a public feed.** `/api/gallery` is scoped to the signed-in
/// user on the server — there is no endpoint that returns other people's work,
/// even though `ai_generations.is_public` exists and clearly anticipates one.
/// So this screen ranks *your* library instead of pretending to be a community,
/// and says so in a line at the top. When a public feed endpoint lands, only
/// [GalleryRepository] has to change.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _scroll = ScrollController();
  GallerySort _sort = GallerySort.trending;

  GalleryScope get _scope => (filter: GalleryFilter.all, sort: _sort);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
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
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final featured = state.items.isEmpty ? null : state.items.first;
    final rest = state.items.length > 1 ? state.items.sublist(1) : const <Generation>[];

    return RefreshIndicator(
      color: XdrColors.ice,
      backgroundColor: XdrColors.wellFill,
      onRefresh: controller.refresh,
      child: XdrEnter(
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    for (final sort in GallerySort.values) ...[
                      PressSink(
                        radius: 8,
                        depth: 1.5,
                        onTap: () => setState(() => _sort = sort),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
                          child: Column(
                            children: [
                              Text(
                                sort.labelTh,
                                style: XdrType.thai(
                                  size: 13.5,
                                  weight: sort == _sort ? FontWeight.w600 : FontWeight.w400,
                                  color: sort == _sort
                                      ? XdrColors.textPrimary
                                      : XdrColors.textMuted,
                                ).copyWith(shadows: engraved),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 2,
                                width: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: sort == _sort
                                      ? const LinearGradient(
                                          colors: [XdrColors.cyan, XdrColors.violet],
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(color: XdrColors.hairline)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: MetalSurface(
                  radius: 12,
                  dropShadows: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: XdrColors.lilac),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ฟีดสาธารณะยังไม่เปิด — ตอนนี้แสดงผลงานของคุณเรียงตามความนิยม',
                          style: XdrType.thai(size: 10.5, color: XdrColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (state.loading)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(height: 210, child: ShimmerTile(radius: 20)),
                ),
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
                  icon: Icons.hexagon_outlined,
                  title: 'ยังไม่มีผลงานให้จัดอันดับ',
                  body: 'สร้างผลงานชิ้นแรก แล้วกลับมาดูว่าชิ้นไหนได้รับความนิยมที่สุด',
                  actionLabel: 'ไปที่สตูดิโอ',
                  onAction: () => context.go(Routes.studio),
                ),
              )
            else ...[
              if (featured != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  sliver: SliverToBoxAdapter(
                    child: _FeaturedCard(
                      item: featured,
                      handle: user?.handle ?? 'creator',
                      initial: user?.initial ?? '?',
                      onTap: () => WorkViewer.open(
                        context,
                        item: featured,
                        onToggleFavourite: () => controller.toggleFavourite(featured),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(childCount: rest.length, (context, i) {
                    final item = rest[i];
                    return WorkCard(
                      item: item,
                      height: double.infinity,
                      showFavouriteCount: true,
                      onTap: () => WorkViewer.open(
                        context,
                        item: item,
                        onToggleFavourite: () => controller.toggleFavourite(item),
                      ),
                    );
                  }),
                ),
              ),
            ],

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
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.item,
    required this.handle,
    required this.initial,
    required this.onTap,
  });

  final Generation item;
  final String handle;
  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      radius: 20,
      onTap: onTap,
      child: SizedBox(
        height: 210,
        child: BevelRing(
          radius: 20,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RemoteArt(url: item.thumbnailUrl ?? item.resultUrl),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00030612), Color(0xEB030612)],
                      stops: [0.35, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: XdrColors.violet.withValues(alpha: 0.28),
                    border: Border.all(color: XdrColors.lilac.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 11, color: Color(0xFFDDD6FE)),
                      const SizedBox(width: 5),
                      Text(
                        'ผลงานเด่นของคุณ',
                        style: XdrType.thai(size: 10.5, color: const Color(0xFFDDD6FE)),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.prompt ?? 'ไม่มีคำอธิบาย',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: XdrType.thai(
                        size: 14.5,
                        weight: FontWeight.w500,
                        color: XdrColors.textPrimary,
                      ).copyWith(shadows: engraved),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AvatarRing(initial: initial, size: 22),
                        const SizedBox(width: 7),
                        Text('@$handle', style: XdrType.thai(size: 11, color: XdrColors.textBody)),
                        const Spacer(),
                        Text(
                          '♥ ${item.favoritesCount}',
                          style: XdrType.latin(size: 11, color: XdrColors.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
