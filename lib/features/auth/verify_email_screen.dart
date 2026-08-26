import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kuangan/features/auth/auth_provider.dart';
import 'package:kuangan/shared/utils/responsive.dart';
import 'package:kuangan/shared/widgets/app_feedback.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  final String name;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  // UI countdown only. Backend OTP validity stays controlled by the server.
  static const int _otpLifetimeSeconds = 300;
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isSubmitting = false;
  bool _isResending = false;
  int _remainingSeconds = _otpLifetimeSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _codeFocusNode.addListener(() => setState(() {}));
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _remainingSeconds = _otpLifetimeSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  String _formatRemainingTime() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleVerify() async {
    if (_remainingSeconds == 0) {
      showAppFeedback(
        context,
        title: 'Kode Sudah Kedaluwarsa',
        message: 'Masa berlaku kode sudah habis. Kirim ulang kode baru, ya.',
        type: AppFeedbackType.error,
      );
      return;
    }

    final code = _codeController.text.trim();
    if (code.length != 6) {
      showAppFeedback(
        context,
        title: 'Kode Belum Lengkap',
        message: 'Masukkan 6 digit kode verifikasi yang kamu terima.',
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref.read(authProvider.notifier).verifySignupOtp(
          email: widget.email,
          token: code,
          name: widget.name,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      showAppFeedback(
        context,
        title: 'Verifikasi Berhasil',
        message: 'Email kamu sudah aktif dan akun siap dipakai.',
        type: AppFeedbackType.success,
      );
      context.go('/dashboard');
      return;
    }

    final error = ref.read(authProvider).error;
    showAppFeedback(
      context,
      title: 'Verifikasi Gagal',
      message: error ?? 'Kode verifikasi belum cocok. Coba lagi, ya.',
      type: AppFeedbackType.error,
    );
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    final success =
        await ref.read(authProvider.notifier).resendSignupOtp(widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (success) {
      _startCountdown();
      showAppFeedback(
        context,
        title: 'Kode Baru Terkirim',
        message: 'Kami sudah kirim ulang kode verifikasi ke email kamu.',
        type: AppFeedbackType.success,
      );
      return;
    }

    final error = ref.read(authProvider).error;
    showAppFeedback(
      context,
      title: 'Belum Bisa Kirim Ulang',
      message: error ?? 'Coba tunggu sebentar lalu kirim ulang lagi.',
      type: AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final horizontalPadding = Responsive.horizontalPadding(context);
    final maxFormWidth = Responsive.maxFormWidth(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verifikasi Email'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/register'),
        ),
      ),
      body: SafeArea(
        child: Center(
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
                  Text(
                    'Kami sudah mengirim kode 6 digit ke ${widget.email}. Masukkan kode itu dalam 5 menit untuk mengaktifkan akunmu.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _remainingSeconds == 0
                            ? const Color(0xFFFECDD3)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _remainingSeconds == 0
                                ? const Color(0xFFFFE4E6)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _remainingSeconds == 0
                                ? Icons.timer_off_rounded
                                : Icons.timer_outlined,
                            color: _remainingSeconds == 0
                                ? const Color(0xFFBE123C)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _remainingSeconds == 0
                                    ? 'Kode sudah kedaluwarsa'
                                    : 'Kode berlaku sampai',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _remainingSeconds == 0
                                    ? 'Kirim ulang kode untuk mendapatkan OTP baru.'
                                    : _formatRemainingTime(),
                                style: TextStyle(
                                  fontSize: _remainingSeconds == 0 ? 13 : 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing:
                                      _remainingSeconds == 0 ? 0 : 1.2,
                                  color: _remainingSeconds == 0
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _codeController,
                    focusNode: _codeFocusNode,
                    label: 'Kode Verifikasi',
                    hint: '123456',
                    icon: Icons.mark_email_read_outlined,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_isSubmitting || _remainingSeconds == 0)
                        ? null
                        : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verifikasi Kode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isResending ? null : _handleResend,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _isResending
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          )
                        : Icon(Icons.refresh_rounded, color: primaryColor),
                    label: Text(
                      _isResending ? 'Mengirim ulang...' : 'Kirim Ulang Kode',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final showHint = !focusNode.hasFocus;
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
              fontSize: 14,
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: showHint ? hint : '',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              letterSpacing: 6,
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: const Color(0xFF64748B),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }
}
