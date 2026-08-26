import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuangan/features/auth/auth_provider.dart';
import 'package:kuangan/shared/widgets/app_feedback.dart';
import 'package:kuangan/features/settings/settings_provider.dart';
import 'package:kuangan/features/settings/wallet_form.dart';
import 'package:kuangan/shared/utils/currency.dart';
import 'package:kuangan/features/settings/category_form.dart';
import 'package:kuangan/features/settings/edit_profile_form.dart';
import 'package:kuangan/features/settings/change_password_form.dart';
import 'package:kuangan/shared/widgets/app_bottom_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _telegramController = TextEditingController();
  bool _isSavingTelegram = false;
  bool _telegramInitialized = false;
  String? _savedTelegramId;
  String? _telegramInlineMessage;
  bool _telegramMessageIsError = false;

  @override
  void dispose() {
    _telegramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);

    if (!_telegramInitialized) {
      _savedTelegramId = auth.user?.telegramId;
      _telegramController.text = _savedTelegramId ?? '';
      _telegramInitialized = true;
    }

    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileCard(context, auth.user?.name ?? 'User',
                        auth.user?.email ?? ''),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Finansial'),
                    _buildSettingsGroup([
                      _buildSettingsTile(
                        context,
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Dompet Saya',
                        subtitle: '${settings.wallets.length} Terdaftar',
                        onTap: () => _showWalletManager(context, settings),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.category_rounded,
                        title: 'Kategori',
                        subtitle: '${settings.categories.length} Kategori',
                        onTap: () => _showCategoryManager(context, settings),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Integrasi'),
                    _buildTelegramCard(context, ref),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Akun'),
                    _buildSettingsGroup([
                      _buildSettingsTile(
                        context,
                        icon: Icons.lock_outline_rounded,
                        title: 'Ubah Sandi',
                        onTap: () => _showChangePassword(context),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Keluar',
                        titleColor: Colors.redAccent,
                        onTap: () => _showLogoutDialog(context, ref),
                      ),
                    ]),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ));
  }

  String _maskEmail(String email) {
    final trimmed = email.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 1 || atIndex == trimmed.length - 1) {
      return trimmed;
    }

    final local = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex);

    if (local.length <= 2) {
      return '${local[0]}***$domain';
    }

    final visibleStart = local.substring(0, 2);
    final visibleEnd =
        local.length > 5 ? local.substring(local.length - 1) : '';
    return '$visibleStart***$visibleEnd$domain';
  }

  Widget _buildProfileCard(BuildContext context, String name, String email) {
    final maskedEmail = _maskEmail(email);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  maskedEmail,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfile(context),
            icon:
                const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (titleColor ?? Theme.of(context).primaryColor)
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: titleColor ?? Theme.of(context).primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: titleColor ?? const Color(0xFF0F172A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 13))
          : null,
      trailing:
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTelegramCard(BuildContext context, WidgetRef ref) {
    final hasSavedTelegramId =
        _savedTelegramId != null && _savedTelegramId!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF24A1DE).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.telegram_rounded,
                    color: Color(0xFF24A1DE), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Telegram Bot',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Hubungkan Telegram ID untuk mencatat transaksi lebih cepat via bot.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showTelegramGuide(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              foregroundColor: const Color(0xFF2563EB),
            ),
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: const Text(
              'Cara pakai Telegram Bot',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (hasSavedTelegramId) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID terdaftar: $_savedTelegramId',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _telegramController,
                  enabled: !hasSavedTelegramId && !_isSavingTelegram,
                  decoration: InputDecoration(
                    hintText: hasSavedTelegramId
                        ? 'Hapus ID dulu untuk ganti'
                        : 'Masukkan ID...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSavingTelegram
                    ? null
                    : () async {
                        setState(() => _isSavingTelegram = true);
                        final result = await ref
                            .read(settingsProvider.notifier)
                            .updateTelegramId(
                              hasSavedTelegramId
                                  ? ''
                                  : _telegramController.text,
                            );

                        if (!mounted) return;

                        setState(() {
                          _isSavingTelegram = false;
                          _telegramInlineMessage = result.message;
                          _telegramMessageIsError = !result.success;
                          _savedTelegramId = result.telegramId;
                          _telegramController.text = result.telegramId ?? '';
                        });
                        if (!context.mounted) return;
                        showAppFeedback(
                          context,
                          title: result.success
                              ? (hasSavedTelegramId
                                  ? 'Telegram ID Dihapus'
                                  : 'Telegram Tersambung')
                              : 'Telegram Belum Tersimpan',
                          message: result.message,
                          type: result.success
                              ? AppFeedbackType.success
                              : AppFeedbackType.error,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSavingTelegram
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(hasSavedTelegramId ? 'Hapus ID' : 'Simpan'),
              ),
            ],
          ),
          if (_telegramInlineMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _telegramInlineMessage!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _telegramMessageIsError
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF2563EB),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTelegramGuide(BuildContext context) {
    showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.telegram_rounded,
                      color: Color(0xFF24A1DE), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Panduan Pakai Telegram Bot',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Panduan ini buat user yang bingung isi Telegram ID. Semua langkah bisa dilakukan langsung dari HP.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              _buildGuideStep(
                number: '1',
                title: 'Buka Telegram dan cari bot Kuangan',
                description:
                    'Masuk ke aplikasi Telegram, cari bot Kuangan, lalu buka chat-nya.',
              ),
              _buildGuideStep(
                number: '2',
                title: 'Kirim pesan `/start` atau pesan biasa',
                description:
                    'Kalau akun belum tertaut, bot akan membalas dan menampilkan Telegram ID kamu.',
              ),
              _buildGuideStep(
                number: '3',
                title: 'Salin angka Telegram ID',
                description:
                    'Ambil angka ID yang dikirim bot, lalu tempel ke kolom Telegram ID di halaman Pengaturan ini.',
              ),
              _buildGuideStep(
                number: '4',
                title: 'Tekan tombol `Simpan`',
                description:
                    'Kalau berhasil, akun Telegram kamu langsung tersambung ke aplikasi Kuangan.',
              ),
              _buildGuideStep(
                number: '5',
                title: 'Mulai catat transaksi dari Telegram',
                description:
                    'Setelah tersambung, user bisa kirim catatan pengeluaran, pemasukan, atau foto struk langsung ke bot.',
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contoh pesan yang bisa dikirim ke bot',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('• Beli kopi 25rb'),
                    SizedBox(height: 6),
                    Text('• Gaji masuk 3jt'),
                    SizedBox(height: 6),
                    Text('• Kirim foto struk belanja'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Kalau bot belum menampilkan ID, minta user kirim pesan lagi ke bot. Biasanya balasan ID muncul saat akun Telegram belum tertaut.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWalletManager(BuildContext context, dynamic settings) {
    showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Manajemen Dompet',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => _showAddWallet(context),
                    icon: const Icon(Icons.add_circle_rounded,
                        color: Color(0xFF2563EB), size: 32),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: settings.wallets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final wallet = settings.wallets[index];
                  final color =
                      Color(int.parse(wallet.color.replaceFirst('#', '0xFF')));
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(wallet.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(formatIDR(wallet.balance),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent),
                            onPressed: () => _confirmDelete(
                                    context, 'Dompet', wallet.name, () {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .deleteWallet(wallet.id);
                                })),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWallet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WalletForm(),
    );
  }

  void _showCategoryManager(BuildContext context, dynamic settings) {
    showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Manajemen Kategori',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => _showAddCategory(context),
                    icon: const Icon(Icons.add_circle_rounded,
                        color: Color(0xFF2563EB), size: 32),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: settings.categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = settings.categories[index];
                  final color = Color(
                      int.parse(category.color.replaceFirst('#', '0xFF')));
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            category.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(category.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent),
                            onPressed: () => _confirmDelete(
                                    context, 'Kategori', category.name, () {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .deleteCategory(category.id);
                                })),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategory(BuildContext context) {
    showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CategoryForm(),
    );
  }

  void _confirmDelete(BuildContext context, String title, String itemName,
      VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus $title?'),
        content: Text('Apakah kamu yakin ingin menghapus "$itemName"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child:
                const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Aplikasi?'),
        content: const Text('Kamu perlu login kembali untuk mengakses datamu.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Ya, Keluar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditProfileForm(),
    );
  }

  void _showChangePassword(BuildContext context) {
    showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordForm(),
    );
  }
}
