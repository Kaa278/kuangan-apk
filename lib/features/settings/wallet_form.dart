import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuangan/features/settings/settings_provider.dart';

class WalletForm extends ConsumerStatefulWidget {
  const WalletForm({super.key});

  @override
  ConsumerState<WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends ConsumerState<WalletForm> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedColor = '#2563EB';
  bool _isLoading = false;

  final List<String> _presets = [
    '#2563EB',
    '#6366F1',
    '#EC4899',
    '#F59E0B',
    '#10B981',
    '#3B82F6',
    '#8B5CF6',
    '#06B6D4'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 32,
        right: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tambah Dompet',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text('Pisahkan sumber danamu untuk pelacakan yang lebih baik.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(height: 32),
          _buildTextField(_nameController, 'Nama Dompet', 'Misal: Tabungan BCA',
              Icons.account_balance_rounded),
          const SizedBox(height: 20),
          _buildTextField(
              _balanceController, 'Saldo Awal', '0', Icons.payments_rounded,
              isNumber: true, prefix: 'Rp '),
          const SizedBox(height: 32),
          const Text('Pilih Warna Tema',
              style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children:
                _presets.map((color) => _buildColorPicker(color)).toList(),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18))),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Buat Dompet Sekarang',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon,
      {bool isNumber = false, String? prefix}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        prefixText: prefix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildColorPicker(String colorHex) {
    final isSelected = _selectedColor == colorHex;
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = colorHex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
            : null,
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await ref.read(settingsProvider.notifier).addWallet({
      'name': _nameController.text,
      'balance': double.tryParse(_balanceController.text) ?? 0,
      'color': _selectedColor,
      'icon': 'wallet',
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) Navigator.pop(context);
    }
  }
}
