import 'package:flutter/material.dart';
import '../models/exam_session.dart';

class ResultScreen extends StatelessWidget {
  final ExamResult result;
  final VoidCallback onNextStudent;

  const ResultScreen({
    super.key,
    required this.result,
    required this.onNextStudent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBlocked = result.isBlocked;

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
            border: Border.all(
              color: isBlocked
                  ? const Color(0xFFE9A568).withValues(alpha: 0.3)
                  : const Color(0xFF6EE7B7).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isBlocked
                        ? const Color(0xFFE9A568)
                        : const Color(0xFF6EE7B7))
                    .withValues(alpha: 0.15),
                blurRadius: 50,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isBlocked
                        ? [
                            const Color(0xFFE9A568).withValues(alpha: 0.2),
                            const Color(0xFFE9A568).withValues(alpha: 0.05),
                          ]
                        : [
                            const Color(0xFF6EE7B7).withValues(alpha: 0.2),
                            const Color(0xFF6EE7B7).withValues(alpha: 0.05),
                          ],
                  ),
                ),
                child: Icon(
                  isBlocked ? Icons.block_rounded : Icons.check_circle_rounded,
                  size: 64,
                  color: isBlocked
                      ? const Color(0xFFE9A568)
                      : const Color(0xFF6EE7B7),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                isBlocked
                    ? 'Попытка заблокирована'
                    : 'Тестирование завершено',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE2E8F0),
                  letterSpacing: -0.5,
                ),
              ),
              if (result.reason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9A568).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE9A568).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    result.reason,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE9A568),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF38BDF8).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildStatRow(
                label: 'Набрано баллов',
                value: '${result.score} из ${result.maxScore}',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(height: 20),
              _buildStatRow(
                label: 'Процент выполнения',
                value: '${result.percentage.toStringAsFixed(1)}%',
                color: const Color(0xFF6EE7B7),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getGradeColor(result.grade).withValues(alpha: 0.15),
                      _getGradeColor(result.grade).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getGradeColor(result.grade).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Рекомендуемая оценка',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.grade}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: _getGradeColor(result.grade),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onNextStudent,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
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
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBlocked
                                  ? Icons.refresh_rounded
                                  : Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isBlocked
                                  ? 'Повторить вход'
                                  : 'Следующий студент',
                              style: const TextStyle(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(int grade) {
    if (grade >= 4) return const Color(0xFF6EE7B7);
    if (grade == 3) return const Color(0xFFE9A568);
    return const Color(0xFFE74C3C);
  }
}
