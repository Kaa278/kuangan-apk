import 'package:flutter/material.dart';

enum AppFeedbackType { success, error, info }

void showAppFeedback(
  BuildContext context, {
  required String title,
  required String message,
  AppFeedbackType type = AppFeedbackType.info,
}) {
  final messenger = ScaffoldMessenger.of(context);

  Color backgroundColor;
  Color borderColor;
  Color iconBackground;
  Color iconColor;
  IconData icon;

  switch (type) {
    case AppFeedbackType.success:
      backgroundColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      iconBackground = const Color(0xFFD1FAE5);
      iconColor = const Color(0xFF047857);
      icon = Icons.mark_email_unread_rounded;
      break;
    case AppFeedbackType.error:
      backgroundColor = const Color(0xFFFFF1F2);
      borderColor = const Color(0xFFFECDD3);
      iconBackground = const Color(0xFFFFE4E6);
      iconColor = const Color(0xFFBE123C);
      icon = Icons.error_outline_rounded;
      break;
    case AppFeedbackType.info:
      backgroundColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
      iconBackground = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF334155);
      icon = Icons.info_outline_rounded;
      break;
  }

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
