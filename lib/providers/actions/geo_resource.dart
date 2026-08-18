part of '../action.dart';

@Riverpod(keepAlive: true)
class GeoResourceAction extends _$GeoResourceAction {
  @override
  void build() {}

  /// Resources the user asked to update from the resources page.
  ///
  /// The core reports automatic and manual updates through the same hook, and
  /// only a manual one is worth announcing: the automatic updater runs on a
  /// timer and on every config apply, so announcing all four databases there
  /// would bury the user in notifications they never asked for.
  final _requested = <GeoResource>{};

  Future<void> updateGeoResource(GeoResource geoResource) async {
    markRequested(geoResource);
    await coreController.updateGeoData(geoResource.name);
  }

  @visibleForTesting
  void markRequested(GeoResource geoResource) => _requested.add(geoResource);

  bool isRequested(GeoResource geoResource) => _requested.contains(geoResource);

  bool takeRequested(GeoResource geoResource) =>
      _requested.remove(geoResource);

  void updateGeoResourceUrl(GeoResource geoResource, String newUrl) {
    if (!newUrl.isUrl) {
      throw 'Invalid url';
    }
    ref.read(patchClashConfigProvider.notifier).update((state) {
      return state.copyWith(geoXUrl: {...state.geoXUrl, geoResource: newUrl});
    });
  }
}
