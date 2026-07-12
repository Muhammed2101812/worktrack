import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/constants.dart';
import '../providers/settings_provider.dart';

/// Result of a purchase / restore attempt.
enum IapResult { success, cancelled, error, notAvailable }

/// Wrapper around `in_app_purchase`. Mobile-only: on web/desktop every call
/// returns [IapResult.notAvailable] and no store connection is made.
class IapService {
  IapService(this._ref);
  final Ref _ref;

  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _available = false;
  bool _initialized = false;

  ProductDetails? _removeAdsProduct;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;

  // Completion forwarded from the purchase stream for the active buy flow.
  Completer<IapResult>? _buyCompleter;

  /// Initialises the store connection and querys the product. Safe to call
  /// multiple times.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!_isMobilePlatform) return;

    _available = await _store.isAvailable();
    if (!_available) return;

    _sub = _store.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (e) => debugPrint('IAP stream error: $e'),
    );

    await _queryProducts();
    // Restore any previously purchased entitlement on startup.
    await restorePurchases();
  }

  static bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _queryProducts() async {
    final resp = await _store.queryProductDetails(AppConstants.iapProductIds.toSet());
    if (resp.error != null) {
      debugPrint('IAP query error: ${resp.error}');
      return;
    }
    if (resp.productDetails.isNotEmpty) {
      _removeAdsProduct = resp.productDetails.first;
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      _handlePurchase(p);
    }
  }

  void _handlePurchase(PurchaseDetails p) {
    switch (p.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (p.productID == AppConstants.iapRemoveAdsProductId) {
          _ref.read(isPremiumProvider.notifier).enablePremium();
          if (p.status == PurchaseStatus.purchased && _buyCompleter != null && !_buyCompleter!.isCompleted) {
            _buyCompleter!.complete(IapResult.success);
          }
        }
        break;
      case PurchaseStatus.error:
        debugPrint('IAP purchase error: ${p.error}');
        if (_buyCompleter != null && !_buyCompleter!.isCompleted) {
          _buyCompleter!.complete(IapResult.error);
        }
        break;
      case PurchaseStatus.canceled:
        if (_buyCompleter != null && !_buyCompleter!.isCompleted) {
          _buyCompleter!.complete(IapResult.cancelled);
        }
        break;
      case PurchaseStatus.pending:
        // No-op: wait for a terminal status.
        break;
    }

    // Acknowledge/consume the purchase on the platform side.
    if (p.pendingCompletePurchase) {
      _store.completePurchase(p);
    }
  }

  /// Starts the buy flow for "remove ads". Returns the terminal result.
  Future<IapResult> buyRemoveAds() async {
    if (!_isMobilePlatform || !_available) return IapResult.notAvailable;
    final product = _removeAdsProduct;
    if (product == null) return IapResult.notAvailable;

    _buyCompleter = Completer<IapResult>();
    final ok = await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!ok) {
      return IapResult.error;
    }
    return _buyCompleter!.future;
  }

  /// Restores previous purchases across reinstalls / new devices.
  Future<void> restorePurchases() async {
    if (!_isMobilePlatform || !_available) return;
    try {
      await _store.restorePurchases();
    } catch (e) {
      debugPrint('IAP restore failed: $e');
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}

/// Riverpod provider keeping a single [IapService] instance alive for the app.
final iapServiceProvider = Provider<IapService>((ref) {
  final svc = IapService(ref);
  ref.onDispose(svc.dispose);
  return svc;
});
