import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_state.dart';

const String kLifetimeProductId = 'dmaas_lifetime_199';
const String _kPurchasedKey = 'dmaas_purchased';
const String _kTaskCountKey = 'dmaas_task_count';
const String _kFirstTaskDateKey = 'dmaas_first_task_date';
const String _kBaseUrl = 'http://74.208.213.94:3302';

class PurchaseCubit extends Cubit<PurchaseState> {
  PurchaseCubit({required this.tokenProvider}) : super(const PurchaseState()) {
    _init();
  }

  final Future<String?> Function() tokenProvider;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  Future<void> _init() async {
    emit(state.copyWith(status: AppPurchaseStatus.loading));

    final prefs = await SharedPreferences.getInstance();
    final taskCount = prefs.getInt(_kTaskCountKey) ?? 0;
    final firstTaskStr = prefs.getString(_kFirstTaskDateKey);
    final firstTaskDate =
        firstTaskStr != null ? DateTime.tryParse(firstTaskStr) : null;

    // Local cache: trust if set, then verify with backend
    final localPurchased = prefs.getBool(_kPurchasedKey) ?? false;

    emit(state.copyWith(
      status: localPurchased
          ? AppPurchaseStatus.purchased
          : AppPurchaseStatus.notPurchased,
      taskCount: taskCount,
      firstTaskDate: firstTaskDate,
    ));

    // Always verify purchase status with backend (source of truth)
    _syncPurchaseStatus();

    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {},
    );
  }

  /// Sync with backend — backend is source of truth for purchase status.
  Future<void> _syncPurchaseStatus() async {
    try {
      final token = await tokenProvider();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_kBaseUrl/purchase/status'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final purchased = data['purchased'] as bool? ?? false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kPurchasedKey, purchased);
        emit(state.copyWith(
          status: purchased
              ? AppPurchaseStatus.purchased
              : AppPurchaseStatus.notPurchased,
        ));
      }
    } catch (_) {
      // Silently fall back to local cache — no UI disruption
    }
  }

  /// Call this every time a task is created.
  Future<void> onTaskCreated() async {
    if (state.isPurchased) return;

    final prefs = await SharedPreferences.getInstance();
    final newCount = state.taskCount + 1;
    await prefs.setInt(_kTaskCountKey, newCount);

    DateTime? firstDate = state.firstTaskDate;
    if (firstDate == null) {
      firstDate = DateTime.now();
      await prefs.setString(_kFirstTaskDateKey, firstDate.toIso8601String());
    }

    emit(state.copyWith(taskCount: newCount, firstTaskDate: firstDate));
  }

  Future<void> purchase() async {
    emit(state.copyWith(isPurchasing: true, errorMessage: null));

    final available = await _iap.isAvailable();
    if (!available) {
      emit(state.copyWith(
        isPurchasing: false,
        errorMessage: 'Store not available. Try again later.',
      ));
      return;
    }

    final response = await _iap.queryProductDetails({kLifetimeProductId});
    if (response.productDetails.isEmpty) {
      emit(state.copyWith(
        isPurchasing: false,
        errorMessage: 'Product not found. Please contact support.',
      ));
      return;
    }

    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
    // Result comes through purchaseStream → _onPurchaseUpdates
  }

  Future<void> restorePurchases() async {
    emit(state.copyWith(isPurchasing: true, errorMessage: null));
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != kLifetimeProductId) continue;

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _verifyWithBackendAndUnlock(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        emit(state.copyWith(
          isPurchasing: false,
          errorMessage: purchase.error?.message ?? 'Purchase failed.',
        ));
      } else if (purchase.status == PurchaseStatus.canceled) {
        emit(state.copyWith(isPurchasing: false));
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Send receipt to backend for server-side Apple validation before unlocking.
  Future<void> _verifyWithBackendAndUnlock(PurchaseDetails purchase) async {
    try {
      final token = await tokenProvider();
      if (token == null) throw Exception('Not authenticated');

      // The local verification data contains the base64 receipt on iOS
      final receiptData =
          purchase.verificationData.localVerificationData;

      final response = await http.post(
        Uri.parse('$_kBaseUrl/purchase/verify-ios'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'receiptData': receiptData}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final verified = data['purchased'] as bool? ?? false;
        if (verified) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_kPurchasedKey, true);
          emit(state.copyWith(
            status: AppPurchaseStatus.purchased,
            isPurchasing: false,
          ));
          return;
        }
      }

      // Backend rejected the receipt
      emit(state.copyWith(
        isPurchasing: false,
        errorMessage: 'We couldn\'t verify your purchase. Please contact support.',
      ));
    } catch (_) {
      // Network failure — fall back to completing locally (better than losing the purchase)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPurchasedKey, true);
      emit(state.copyWith(
        status: AppPurchaseStatus.purchased,
        isPurchasing: false,
      ));
    }
  }

  // For dev/testing — force unlock without real IAP
  Future<void> debugUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPurchasedKey, true);
    emit(state.copyWith(status: AppPurchaseStatus.purchased));
  }

  @override
  Future<void> close() {
    _purchaseSubscription?.cancel();
    return super.close();
  }
}
