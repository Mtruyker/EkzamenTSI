import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final String examTitle;
  final TextEditingController nameController;
  final TextEditingController groupController;
  final VoidCallback onStartExam;

  const LoginScreen({
    super.key,
    required this.examTitle,
    required this.nameController,
    required this.groupController,
    required this.onStartExam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F131C), Color(0xFF1E2636), Color(0xFF0A0D12)],
        ),
      ),
      child: Center(
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF161D2B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF38BDF8).withValues(alpha: 0.2),
                      const Color(0xFF38BDF8).withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 48,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                examTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE2E8F0),
                  letterSpacing: -0.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: nameController,
                label: 'ФИО студента',
                hint: 'Иванов Иван Иванович',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: groupController,
                label: 'Учебная группа',
                hint: 'П-21',
                icon: Icons.group_outlined,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C2D12).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE9A568).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9A568).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: Color(0xFFE9A568),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Режим Анти-чит',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE9A568),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildWarningRow('Полноэкранный режим без выхода'),
                    const SizedBox(height: 8),
                    _buildWarningRow('Блокировка Alt+Tab, Win, второго монитора'),
                    const SizedBox(height: 8),
                    _buildWarningRow('Отключение буфера обмена (Ctrl+V)'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildStartButton(onStartExam),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F131C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            ),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFF94A3B8).withValues(alpha: 0.4),
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningRow(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE9A568).withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(VoidCallback onPressed) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Начать тестирование',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
