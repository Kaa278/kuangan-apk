import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:kuangan/shared/demo/demo_data.dart';
import 'package:kuangan/features/auth/auth_provider.dart';
import 'package:kuangan/shared/models/wallet.dart';
import 'package:kuangan/shared/models/category.dart';
import 'package:dio/dio.dart';

class SettingsState {
  final List<Wallet> wallets;
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  SettingsState({
    this.wallets = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    List<Wallet>? wallets,
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TelegramUpdateResult {
  final bool success;
  final String message;
  final String? telegramId;

  const TelegramUpdateResult({
    required this.success,
    required this.message,
    this.telegramId,
  });
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  return SettingsNotifier(userId);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final String? _userId;
  final _supabase = sb.Supabase.instance.client;
  sb.RealtimeChannel? _subscription;

  SettingsNotifier(this._userId) : super(SettingsState()) {
    if (isDemoUser(_userId)) {
      state = state.copyWith(
        wallets: buildDemoWallets(),
        categories: buildDemoCategories(),
      );
    } else if (_userId != null) {
      fetchData();
      _setupRealtime();
    }
  }

  void _setupRealtime() {
    _subscription = _supabase
        .channel('public:wallets:$_userId')
        .onPostgresChanges(
            event: sb.PostgresChangeEvent.all,
            schema: 'public',
            table: 'wallets',
            filter: sb.PostgresChangeFilter(
              type: sb.PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _userId!,
            ),
            callback: (sb.PostgresChangePayload payload) {
              fetchDataSilent();
            })
        .subscribe();
  }

  Future<void> fetchDataSilent() async {
    if (_userId == null) return;
    if (isDemoUser(_userId)) return;
    try {
      final walletsList =
          await _supabase.from('wallets').select().eq('user_id', _userId!);

      final categoriesList =
          await _supabase.from('categories').select().eq('user_id', _userId!);

      state = state.copyWith(
        wallets: (walletsList as List)
            .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
            .toList(),
        categories: (categoriesList as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      debugPrint('SILENT SETTINGS FETCH ERROR: $e');
    }
  }

  Future<void> fetchData() async {
    if (_userId == null) return;
    if (isDemoUser(_userId)) {
      state = state.copyWith(
        wallets: buildDemoWallets(),
        categories: buildDemoCategories(),
        isLoading: false,
      );
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final walletsList =
          await _supabase.from('wallets').select().eq('user_id', _userId!);

      final categoriesList =
          await _supabase.from('categories').select().eq('user_id', _userId!);

      state = state.copyWith(
        wallets: (walletsList as List)
            .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
            .toList(),
        categories: (categoriesList as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('SETTINGS FETCH ERROR: $e');
      state = state.copyWith(
          isLoading: false, error: 'Gagal memuat data pengaturan');
    }
  }

  Future<bool> addWallet(Map<String, dynamic> data) async {
    if (_userId == null) return false;
    if (isDemoUser(_userId)) {
      final newWallet = Wallet(
        id: 'demo-wallet-${DateTime.now().millisecondsSinceEpoch}',
        name: data['name'] as String? ?? 'Wallet Demo',
        color: data['color'] as String? ?? '#0F766E',
        icon: data['icon'] as String? ?? '💳',
        balance: (data['balance'] as num?)?.toDouble() ?? 0,
      );
      state = state.copyWith(wallets: [...state.wallets, newWallet]);
      return true;
    }
    try {
      final newData = Map<String, dynamic>.from(data);
      newData['user_id'] = _userId;
      await _supabase.from('wallets').insert(newData);
      await fetchData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteWallet(String id) async {
    if (_userId == null) return false;
    if (isDemoUser(_userId)) {
      state = state.copyWith(
        wallets: state.wallets.where((wallet) => wallet.id != id).toList(),
      );
      return true;
    }
    try {
      await _supabase
          .from('wallets')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);
      await fetchData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addCategory(Map<String, dynamic> data) async {
    if (_userId == null) return false;
    if (isDemoUser(_userId)) {
      final newCategory = Category(
        id: 'demo-category-${DateTime.now().millisecondsSinceEpoch}',
        name: data['name'] as String? ?? 'Kategori Demo',
        color: data['color'] as String? ?? '#F59E0B',
        icon: data['icon'] as String? ?? '📝',
        type: data['type'] as String? ?? 'expense',
      );
      state = state.copyWith(categories: [...state.categories, newCategory]);
      return true;
    }
    try {
      final newData = Map<String, dynamic>.from(data);
      newData['user_id'] = _userId;
      await _supabase.from('categories').insert(newData);
      await fetchData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    if (_userId == null) return false;
    if (isDemoUser(_userId)) {
      state = state.copyWith(
        categories:
            state.categories.where((category) => category.id != id).toList(),
      );
      return true;
    }
    try {
      await _supabase
          .from('categories')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);
      await fetchData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<TelegramUpdateResult> updateTelegramId(String telegramId) async {
    if (_userId == null) {
      return const TelegramUpdateResult(
        success: false,
        message: 'Sesi pengguna tidak ditemukan.',
      );
    }
    final normalizedTelegramId = telegramId.trim();
    if (isDemoUser(_userId)) {
      return TelegramUpdateResult(
        success: true,
        message: normalizedTelegramId.isEmpty
            ? 'Telegram ID demo berhasil dihapus.'
            : 'Telegram ID demo berhasil disimpan.',
        telegramId: normalizedTelegramId.isEmpty ? null : normalizedTelegramId,
      );
    }
    try {
      if (normalizedTelegramId.isNotEmpty) {
        final existingTelegramUser = await _supabase
            .from('users')
            .select('id')
            .eq('telegram_id', normalizedTelegramId)
            .neq('id', _userId!)
            .maybeSingle();

        if (existingTelegramUser != null) {
          return const TelegramUpdateResult(
            success: false,
            message:
                'ID Telegram ini sudah terdaftar di akun lain. Hapus dulu dari akun tersebut sebelum dipakai di sini.',
          );
        }
      }

      await _supabase.auth.updateUser(
        sb.UserAttributes(
          data: {'telegram_id': normalizedTelegramId},
        ),
      );

      // Update data pada public.users
      await _supabase.from('users').update({
        'telegram_id':
            normalizedTelegramId.isEmpty ? null : normalizedTelegramId,
      }).eq('id', _userId!);

      // Kirim pesan selamat datang jika telegramId tidak kosong
      if (normalizedTelegramId.isNotEmpty) {
        try {
          final dio = Dio();
          await dio.post(
            'https://api.telegram.org/bot8675616917:AAFe6A_jG-YRoW2xaTyVx47oFDdsHbCQzWc/sendMessage',
            data: {
              'chat_id': normalizedTelegramId,
              'text':
                  '🔔 *Kuangan Bot*\n\nSelamat! Telegram ID Anda berhasil dihubungkan dengan aplikasi *Kuangan*.\nSekarang Anda dapat mencatat pengeluaran maupun pemasukan dengan cepat langsung dari sini! 🎉',
              'parse_mode': 'Markdown',
            },
          );
        } catch (botError) {
          debugPrint('TELEGRAM BOT ERROR: $botError');
          // Jika gagal kirim pesan, tetap anggap simpan sukses
        }
      }

      return TelegramUpdateResult(
        success: true,
        message: normalizedTelegramId.isEmpty
            ? 'Telegram ID berhasil dihapus. Sekarang kamu bisa memasukkan ID baru.'
            : 'Telegram ID berhasil disimpan dan siap dipakai.',
        telegramId: normalizedTelegramId.isEmpty ? null : normalizedTelegramId,
      );
    } catch (e) {
      debugPrint('UPDATE TELEGRAM ERROR: $e');
      return const TelegramUpdateResult(
        success: false,
        message: 'Masih ada kendala saat menyimpan Telegram ID.',
      );
    }
  }

  @override
  void dispose() {
    if (!isDemoUser(_userId)) {
      _subscription?.unsubscribe();
    }
    super.dispose();
  }

  void applyDemoWalletBalanceDelta({
    required String walletId,
    required double amount,
    required String type,
  }) {
    if (!isDemoUser(_userId)) return;
    final updatedWallets = state.wallets.map((wallet) {
      if (wallet.id != walletId) return wallet;
      final nextBalance =
          type == 'income' ? wallet.balance + amount : wallet.balance - amount;
      return Wallet(
        id: wallet.id,
        name: wallet.name,
        color: wallet.color,
        icon: wallet.icon,
        balance: nextBalance,
      );
    }).toList();

    state = state.copyWith(wallets: updatedWallets);
  }
}
