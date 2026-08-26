import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kuangan/shared/models/category.dart';
import 'package:kuangan/shared/models/wallet.dart';
import 'package:kuangan/shared/utils/currency.dart';
import 'package:kuangan/shared/widgets/app_feedback.dart';
import 'package:kuangan/shared/widgets/app_bottom_sheet.dart';
import 'package:kuangan/features/settings/settings_provider.dart';
import 'package:kuangan/features/transactions/transactions_provider.dart';
import 'package:kuangan/shared/models/ai_scan_result.dart';

class TransactionModal extends ConsumerStatefulWidget {
  final AiScanResult? initialScanResult;

  const TransactionModal({super.key, this.initialScanResult});

  static Future<void> show(BuildContext context, {AiScanResult? scanResult}) {
    return showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionModal(initialScanResult: scanResult),
    );
  }

  @override
  ConsumerState<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends ConsumerState<TransactionModal>
    with SingleTickerProviderStateMixin {
  String _type = 'expense';
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  Category? _selectedCategory;
  Wallet? _selectedWallet;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;
  bool _categoryAutoSelected = false;
  bool _walletAutoSelected = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    // Populate form if scanned result is given
    if (widget.initialScanResult != null) {
      final res = widget.initialScanResult!;

      if (res.total != null && res.total! > 0) {
        final formatter = NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
        _amountController.text =
            formatter.format(res.total).replaceAll('Rp', '').trim();
      }

      String noteText = res.store ?? '';
      if (res.items != null && res.items!.isNotEmpty) {
        final itemsText =
            res.items!.map((i) => '${i.quantity}x ${i.name}').join(', ');
        if (noteText.isNotEmpty) noteText += ' - ';
        noteText += itemsText;
      }
      _noteController.text = noteText;
    }

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    if (widget.initialScanResult != null && !_categoryAutoSelected) {
      final res = widget.initialScanResult!;
      if (res.suggestedCategory != null && res.suggestedCategory!.isNotEmpty) {
        if (!settings.isLoading && settings.categories.isNotEmpty) {
          final suggestedLower = res.suggestedCategory!.toLowerCase();
          Category? matchedCat;

          for (final c in settings.categories) {
            if (c.type == 'expense') {
              final catName = c.name.toLowerCase();
              // Check for exact, contains, or reversed contains
              if (catName == suggestedLower ||
                  catName.contains(suggestedLower) ||
                  suggestedLower.contains(catName)) {
                matchedCat = c;
                break;
              }
            }
          }

          if (matchedCat != null) {
            _categoryAutoSelected = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedCategory == null) {
                setState(() {
                  _selectedCategory = matchedCat;
                });
              }
            });
          }
        }
      }
    }

    if (!_walletAutoSelected &&
        !settings.isLoading &&
        settings.wallets.isNotEmpty) {
      _walletAutoSelected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedWallet == null) {
          setState(() {
            _selectedWallet = settings.wallets.first;
          });
        }
      });
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final safeBottom = MediaQuery.of(context).padding.bottom;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.only(
              top: 16,
              left: 24,
              right: 24,
              bottom: bottomInset + safeBottom + 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Tambah Transaksi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTypeToggle(),
                  ],
                ),
                const SizedBox(height: 36),
                _buildAmountInput(),
                const SizedBox(height: 32),
                _buildFieldLabel('Kategori'),
                const SizedBox(height: 10),
                _buildCategoryPicker(),
                const SizedBox(height: 24),
                _buildFieldLabel('Dompet'),
                const SizedBox(height: 10),
                _buildWalletPicker(),
                const SizedBox(height: 24),
                _buildDatePicker(),
                const SizedBox(height: 24),
                _buildFieldLabel('Catatan (Opsional)'),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Beli kopi atau bayar parkir...',
                    hintStyle:
                        TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Simpan Transaksi'),
                  ),
                ),
                // Add extra space at the very bottom of the scrollable content
                // to ensure the button can be scrolled completely above the FAB/NavBar
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypeButton('income', 'Masuk'),
          _buildTypeButton('expense', 'Keluar'),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, String label) {
    final isSelected = _type == type;
    final color = type == 'income' ? Colors.greenAccent : Colors.redAccent;

    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
          _selectedCategory = null; // Clear category when type changes
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Rp',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _amountController,
            autofocus: true,
            style: const TextStyle(
              fontSize: 40, // Slightly smaller than 48 for better fit
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.3)),
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return GestureDetector(
      onTap: _showCategoryPicker,
      child: _buildDropdownPlaceholder(
        _selectedCategory?.name ?? 'Pilih Kategori',
        Icons.category_rounded,
        iconLabel: _selectedCategory?.icon,
        iconColor: _selectedCategory != null
            ? Color(
                int.parse(_selectedCategory!.color.replaceFirst('#', '0xFF')))
            : null,
      ),
    );
  }

  Widget _buildWalletPicker() {
    return GestureDetector(
      onTap: _showWalletPicker,
      child: _buildDropdownPlaceholder(
        _selectedWallet?.name ?? 'Pilih Dompet',
        Icons.account_balance_wallet_rounded,
        iconColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showCategoryPicker() {
    showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);
          final filteredCategories =
              settings.categories.where((c) => c.type == _type).toList();

          return _PickerSheet(
            title: 'Pilih Kategori',
            isLoading: settings.isLoading,
            isEmpty: filteredCategories.isEmpty,
            emptyMessage:
                'Belum ada kategori ${_type == 'income' ? 'pemasukan' : 'pengeluaran'}',
            items: filteredCategories
                .map((c) => _PickerItem(
                      label: c.name,
                      icon: c.icon,
                      color:
                          Color(int.parse(c.color.replaceFirst('#', '0xFF'))),
                      onTap: () {
                        setState(() => _selectedCategory = c);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  void _showWalletPicker() {
    showAppBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);
          return _PickerSheet(
            title: 'Pilih Dompet',
            isLoading: settings.isLoading,
            isEmpty: settings.wallets.isEmpty,
            emptyMessage: 'Belum ada dompet',
            items: settings.wallets
                .map((w) => _PickerItem(
                      label: w.name,
                      icon: '💳',
                      color: Theme.of(context).primaryColor,
                      onTap: () {
                        setState(() => _selectedWallet = w);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildDropdownPlaceholder(String hint, IconData icon,
      {String? iconLabel, Color? iconColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget leadingIcon;
    if (iconColor != null) {
      leadingIcon = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: iconLabel != null
            ? Text(iconLabel, style: const TextStyle(fontSize: 20))
            : Icon(icon, size: 20, color: iconColor),
      );
    } else {
      leadingIcon = iconLabel != null
          ? Text(iconLabel, style: const TextStyle(fontSize: 20))
          : Icon(icon,
              size: 20,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.7));
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // Slightly less vertical padding
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          leadingIcon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 15,
                fontWeight: iconLabel != null ||
                        (hint != 'Pilih Kategori' && hint != 'Pilih Dompet')
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (d != null) setState(() => _date = d);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Tanggal'),
          const SizedBox(height: 10),
          _buildDropdownPlaceholder(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date),
            Icons.calendar_today_rounded,
          ),
        ],
      ),
    );
  }

  void _saveTransaction() async {
    final amountText = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(amountText) ?? 0;

    if (amount <= 0) {
      _showError('Masukkan nominal lebih dari 0');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Pilih kategori terlebih dahulu');
      return;
    }
    if (_selectedWallet == null) {
      _showError('Pilih dompet terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(transactionsProvider.notifier)
          .addTransaction(
            amount: amount,
            type: _type,
            source: widget.initialScanResult != null ? 'ai_scan' : 'manual',
            date: _date,
            categoryId: _selectedCategory!.id,
            walletId: _selectedWallet!.id,
            note: _noteController.text.isEmpty ? null : _noteController.text,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          showAppFeedback(
            context,
            title: 'Transaksi Tersimpan',
            message: 'Catatan transaksi kamu sudah berhasil masuk.',
            type: AppFeedbackType.success,
          );
          // Small delay before closing to let user see success
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          _showError('Gagal menyimpan transaksi (DB Error)');
        }
      }
    } catch (e) {
      debugPrint('Transaction save error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Kesalahan sistem: $e');
      }
    }
  }

  void _showError(String message) {
    showAppFeedback(
      context,
      title: 'Transaksi Belum Tersimpan',
      message: message,
      type: AppFeedbackType.error,
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerItem> items;
  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;

  const _PickerSheet({
    required this.title,
    required this.items,
    this.isLoading = false,
    this.isEmpty = false,
    this.emptyMessage = 'Data tidak ditemukan',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 40, color: Colors.grey.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      emptyMessage,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) => items[index],
              ),
            ),
        ],
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _PickerItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Text(icon, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
