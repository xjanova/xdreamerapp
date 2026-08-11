import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/api_exception.dart';
import '../data/models/generation.dart';
import '../data/repositories/gallery_repository.dart';
import 'providers.dart';

/// The family key. A record, so two scopes with the same filter and sort share
/// one controller and one cache instead of refetching per rebuild.
typedef GalleryScope = ({GalleryFilter filter, GallerySort sort});

class GalleryState {
  const GalleryState({
    this.items = const [],
    this.page = 0,
    this.pages = 1,
    this.total = 0,
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  final List<Generation> items;
  final int page;
  final int pages;
  final int total;

  /// First load or refresh — the screen shows skeletons.
  final bool loading;

  /// Appending a page — the list stays put and the footer shows the spinner.
  /// Kept separate so a "load more" never flashes the whole screen back to
  /// skeletons.
  final bool loadingMore;
  final String? error;

  bool get hasMore => page < pages;
  bool get isEmpty => items.isEmpty && !loading && error == null;

  GalleryState copyWith({
    List<Generation>? items,
    int? page,
    int? pages,
    int? total,
    bool? loading,
    bool? loadingMore,
    String? Function()? error,
  }) => GalleryState(
    items: items ?? this.items,
    page: page ?? this.page,
    pages: pages ?? this.pages,
    total: total ?? this.total,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error == null ? this.error : error(),
  );
}

class GalleryController extends FamilyNotifier<GalleryState, GalleryScope> {
  @override
  GalleryState build(GalleryScope arg) {
    Future.microtask(refresh);
    return const GalleryState(loading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: () => null);
    try {
      final page = await ref
          .read(galleryRepositoryProvider)
          .page(page: 1, filter: arg.filter, sort: arg.sort);
      state = GalleryState(
        items: page.items,
        page: page.page,
        pages: page.pages,
        total: page.total,
      );
    } on ApiException catch (error) {
      state = state.copyWith(loading: false, error: () => error.message);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;

    state = state.copyWith(loadingMore: true, error: () => null);
    try {
      final next = await ref
          .read(galleryRepositoryProvider)
          .page(page: state.page + 1, filter: arg.filter, sort: arg.sort);
      state = state.copyWith(
        items: [...state.items, ...next.items],
        page: next.page,
        pages: next.pages,
        total: next.total,
        loadingMore: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(loadingMore: false, error: () => error.message);
    }
  }

  /// Optimistic: the heart fills instantly and rolls back if the server says
  /// no. A favourite is not worth a spinner.
  Future<void> toggleFavourite(Generation item) async {
    final wasFavourited = item.isFavorited;
    _replace(
      item.copyWith(
        isFavorited: !wasFavourited,
        favoritesCount: (item.favoritesCount + (wasFavourited ? -1 : 1)).clamp(0, 1 << 31),
      ),
    );

    try {
      final repository = ref.read(galleryRepositoryProvider);
      if (wasFavourited) {
        await repository.unfavourite(item.id);
      } else {
        await repository.favourite(item.id);
      }
    } on ApiException {
      _replace(item);
    }
  }

  void _replace(Generation updated) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == updated.id) updated else item,
      ],
    );
  }
}

final galleryControllerProvider =
    NotifierProvider.family<GalleryController, GalleryState, GalleryScope>(GalleryController.new);
