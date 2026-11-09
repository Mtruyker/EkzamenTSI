import 'package:flutter/material.dart';

class QuestionNavigator extends StatelessWidget {
  final List<dynamic> questions;
  final Map<int, Map<String, dynamic>> answers;
  final int currentIndex;
  final Function(int) onQuestionSelected;
  final VoidCallback onSubmit;
  final bool Function(Map<String, dynamic>?) isAnswered;

  const QuestionNavigator({
    super.key,
    required this.questions,
    required this.answers,
    required this.currentIndex,
    required this.onQuestionSelected,
    required this.onSubmit,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2B),
        border: Border(
          right: BorderSide(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Билет',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFFE2E8F0),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: questions.length,
              itemBuilder: (ctx, idx) {
                final itemQ = questions[idx];
                final itemAns = answers[itemQ['id']];
                final bool hasAnswered = isAnswered(itemAns);
                final bool itemFlagged =
                    itemAns != null && itemAns['flagged'] == true;
                final bool isCurrent = idx == currentIndex;

                Color bgColor = const Color(0xFF0F131C);
                Color borderColor = const Color(0xFF38BDF8).withValues(alpha: 0.15);
                Color txtColor = const Color(0xFF94A3B8);
                double borderWidth = 1;

                if (isCurrent) {
                  bgColor = const Color(0xFF38BDF8).withValues(alpha: 0.2);
                  borderColor = const Color(0xFF38BDF8);
                  txtColor = const Color(0xFF38BDF8);
                  borderWidth = 2;
                } else if (itemFlagged) {
                  bgColor = const Color(0xFFE9A568).withValues(alpha: 0.15);
                  borderColor = const Color(0xFFE9A568).withValues(alpha: 0.4);
                  txtColor = const Color(0xFFE9A568);
                } else if (hasAnswered) {
                  bgColor = const Color(0xFF6EE7B7).withValues(alpha: 0.12);
                  borderColor = const Color(0xFF6EE7B7).withValues(alpha: 0.4);
                  txtColor = const Color(0xFF6EE7B7);
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onQuestionSelected(idx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: borderWidth),
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: txtColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
          _buildLegendRow(
            color: const Color(0xFF6EE7B7),
            label: 'Отвечен',
          ),
          const SizedBox(height: 10),
          _buildLegendRow(
            color: const Color(0xFFE9A568),
            label: 'Отмечен',
          ),
          const SizedBox(height: 10),
          _buildLegendRow(
            color: const Color(0xFF94A3B8),
            label: 'Не отвечен',
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSubmit,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6EE7B7), Color(0xFF34D399)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6EE7B7).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Завершить тест',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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
    );
  }

  Widget _buildLegendRow({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
