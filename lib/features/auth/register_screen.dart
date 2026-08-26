import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kuangan/features/auth/auth_provider.dart';
import 'package:kuangan/shared/utils/responsive.dart';
import 'package:kuangan/shared/widgets/app_feedback.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isValidGmail(String email) {
    final normalized = email.trim().toLowerCase();
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    return gmailRegex.hasMatch(normalized);
  }

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_nameController.text.trim().isEmpty) {
      showAppFeedback(
        context,
        title: 'Nama Masih Kosong',
        message: 'Isi nama lengkap dulu sebelum lanjut daftar.',
        type: AppFeedbackType.error,
      );
      return;
    }

    if (!_isValidGmail(_emailController.text)) {
      showAppFeedback(
        context,
        title: 'Email Belum Valid',
        message:
            'Gunakan alamat email Gmail yang benar, misalnya nama@gmail.com.',
        type: AppFeedbackType.error,
      );
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      showAppFeedback(
        context,
        title: 'Password Terlalu Pendek',
        message: 'Password minimal harus 6 karakter.',
        type: AppFeedbackType.error,
      );
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      showAppFeedback(
        context,
        title: 'Password Belum Cocok',
        message: 'Coba samakan password dan konfirmasi password dulu.',
        type: AppFeedbackType.error,
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );

    if (success && mounted) {
      showAppFeedback(
        context,
        title: 'Cek Email Kamu',
        message:
            'Akun hampir siap. Kami sudah kirim kode verifikasi ke email kamu.',
        type: AppFeedbackType.success,
      );
      context.go(
        '/verify-email',
        extra: {
          'email': _emailController.text.trim().toLowerCase(),
          'name': _nameController.text.trim(),
        },
      );
    } else if (mounted) {
      final error = ref.read(authProvider).error;
      showAppFeedback(
        context,
        title: 'Belum Bisa Dilanjutkan',
        message:
            error ?? 'Pendaftaran belum berhasil. Coba cek lagi datanya, ya.',
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final primaryColor = Theme.of(context).primaryColor;
    final horizontalPadding = Responsive.horizontalPadding(context);
    final maxFormWidth = Responsive.maxFormWidth(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buat Akun Baru'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxFormWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Langkah awal menuju kebebasan finansial kamu dimulai di sini.',
                  style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildInputField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  label: 'Nama Lengkap',
                  hint: 'John Doe',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  label: 'Email',
                  hint: 'nama@gmail.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  label: 'Password',
                  hint: 'Minimal 6 karakter',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  isPasswordVisible: _isPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _confirmController,
                  focusNode: _confirmFocusNode,
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi sandi kamu',
                  icon: Icons.lock_reset_rounded,
                  isPassword: true,
                  isPasswordVisible: _isConfirmPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Daftar Akun',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text.rich(
                      TextSpan(
                        text: 'Sudah punya akun? ',
                        style: TextStyle(color: Colors.grey[600]),
                        children: [
                          TextSpan(
                              text: 'Masuk',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType? keyboardType,
  }) {
    final showHint = focusNode == null || !focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF334155),
                fontSize: 14),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: showHint ? hint : '',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: onVisibilityToggle,
                    splashRadius: 24,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }
}
