import 'package:flutter/material.dart';
import '../services/anti_cheat_service.dart';
import '../widgets/question_navigator.dart';

class ExamScreen extends StatefulWidget {
  final String studentName;
  final String studentGroup;
  final List<dynamic> questions;
  final int currentIndex;
  final Map<int, Map<String, dynamic>> answers;
  final int remainingSeconds;
  final bool linkLost;

  final Function(int) onSwitchQuestion;
  final VoidCallback onConfirmSubmit;
  final bool Function(Map<String, dynamic>?) isAnswered;
  final Function(int qId) onSendProgress;
  final Function(int qId, String key, dynamic value) onAnswerChanged;
  final Map<String, dynamic> Function(int qId) answerOrEmpty;
  final TextEditingController textAnswerController;

  const ExamScreen({
    super.key,
    required this.studentName,
    required this.studentGroup,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.remainingSeconds,
    required this.linkLost,
    required this.onSwitchQuestion,
    required this.onConfirmSubmit,
    required this.isAnswered,
    required this.onSendProgress,
    required this.onAnswerChanged,
    required this.answerOrEmpty,
    required this.textAnswerController,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  String _formatTimer(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(
        child: Text(
          'Нет доступных вопросов в билете',
          style: TextStyle(color: Color(0xFFE2E8F0)),
        ),
      );
    }

    final q = widget.questions[widget.currentIndex];
    final int qId = q['id'];
    final String qType = q['type'];
    final ans = widget.answerOrEmpty(qId);
    final List<int> selected = ans['selected'] as List<int>;
    final bool isFlagged = ans['flagged'] == true;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0D12), Color(0xFF161D2B), Color(0xFF0F131C)],
        ),
      ),
      child: Column(
        children: [
          _TopBar(
            studentName: widget.studentName,
            studentGroup: widget.studentGroup,
            currentIndex: widget.currentIndex,
            totalQuestions: widget.questions.length,
            remainingSeconds: widget.remainingSeconds,
            linkLost: widget.linkLost,
            formatTimer: _formatTimer,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuestionNavigator(
                  questions: widget.questions,
                  answers: widget.answers,
                  currentIndex: widget.currentIndex,
                  onQuestionSelected: widget.onSwitchQuestion,
                  onSubmit: widget.onConfirmSubmit,
                  isAnswered: widget.isAnswered,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161D2B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.05),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 18,
                                      color: Color(0xFF38BDF8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${q['points']} ${_pluralPoints(q['points'])}',
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    widget.onAnswerChanged(qId, 'flagged', !isFlagged);
                                    widget.onSendProgress(qId);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isFlagged
                                          ? const Color(0xFFE9A568).withValues(alpha: 0.15)
                                          : const Color(0xFF0F131C),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isFlagged
                                            ? const Color(0xFFE9A568).withValues(alpha: 0.4)
                                            : const Color(0xFF38BDF8).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isFlagged
                                              ? Icons.flag_rounded
                                              : Icons.outlined_flag_rounded,
                                          size: 18,
                                          color: isFlagged
                                              ? const Color(0xFFE9A568)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isFlagged ? 'Отмечен' : 'Вернуться позже',
                                          style: TextStyle(
                                            color: isFlagged
                                                ? const Color(0xFFE9A568)
                                                : const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            q['text'] ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE2E8F0),
                              height: 1.5,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildAnswerInput(context, q, qId, qType, selected),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildNavButton(
                                onPressed: widget.currentIndex > 0
                                    ? () => widget.onSwitchQuestion(widget.currentIndex - 1)
                                    : null,
                                icon: Icons.arrow_back_rounded,
                                label: 'Назад',
                                isPrimary: false,
                              ),
                              _buildNavButton(
                                onPressed: widget.currentIndex < widget.questions.length - 1
                                    ? () => widget.onSwitchQuestion(widget.currentIndex + 1)
                                    : widget.onConfirmSubmit,
                                icon: widget.currentIndex < widget.questions.length - 1
                                    ? Icons.arrow_forward_rounded
                                    : Icons.done_all_rounded,
                                label: widget.currentIndex < widget.questions.length - 1
                                    ? 'Далее'
                                    : 'Завершить',
                                isPrimary: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pluralPoints(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'балл';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) return 'балла';
    return 'баллов';
  }

  Widget _buildNavButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    final bool enabled = onPressed != null;
    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: isPrimary && enabled
                  ? const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                    )
                  : null,
              color: !isPrimary
                  ? (enabled
                      ? const Color(0xFF0F131C)
                      : const Color(0xFF0F131C).withValues(alpha: 0.3))
                  : (enabled ? null : const Color(0xFF38BDF8).withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(999),
              border: !isPrimary
                  ? Border.all(
                      color: enabled
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.1),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isPrimary) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: enabled
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF94A3B8).withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary
                        ? (enabled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3))
                        : (enabled
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF94A3B8).withValues(alpha: 0.3)),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (isPrimary) ...[
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 20,
                    color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> q,
    int qId,
    String qType,
    List<int> selected,
  ) {
    final List<dynamic> options = q['options'] ?? [];

    if (qType == 'single') {
      return Column(
        children: List.generate(options.length, (idx) {
          final isSelected = selected.contains(idx);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onAnswerChanged(qId, 'selected', <int>[idx]);
                  widget.onSendProgress(qId);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                        : const Color(0xFF0F131C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF38BDF8).withValues(alpha: 0.3),
                            width: 2,
                          ),
                          color: isSelected
                              ? const Color(0xFF38BDF8)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.circle, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          options[idx].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF94A3B8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    if (qType == 'multiple') {
      return Column(
        children: List.generate(options.length, (idx) {
          final isSelected = selected.contains(idx);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final sel = List<int>.from(selected);
                  if (isSelected) {
                    sel.remove(idx);
                  } else {
                    sel.add(idx);
                  }
                  widget.onAnswerChanged(qId, 'selected', sel);
                  widget.onSendProgress(qId);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                        : const Color(0xFF0F131C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF38BDF8).withValues(alpha: 0.3),
                            width: 2,
                          ),
                          color: isSelected
                              ? const Color(0xFF38BDF8)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          options[idx].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF94A3B8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    // text / essay
    final bool isEssay = qType == 'essay';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
        ),
      ),
      child: TextField(
        controller: widget.textAnswerController,
        maxLines: isEssay ? 10 : 1,
        enableInteractiveSelection: false,
        contextMenuBuilder: (context, editableTextState) =>
            const SizedBox.shrink(),
        inputFormatters: [AntiPasteFormatter()],
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 16,
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText: isEssay
              ? 'Введите развёрнутый ответ своими словами...'
              : 'Введите краткий ответ...',
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8).withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
        onChanged: (val) {
          widget.onAnswerChanged(qId, 'text_answer', val);
          widget.onSendProgress(qId);
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String studentName;
  final String studentGroup;
  final int currentIndex;
  final int totalQuestions;
  final int remainingSeconds;
  final bool linkLost;
  final String Function(int) formatTimer;

  const _TopBar({
    required this.studentName,
    required this.studentGroup,
    required this.currentIndex,
    required this.totalQuestions,
    required this.remainingSeconds,
    required this.linkLost,
    required this.formatTimer,
  });

  @override
  Widget build(BuildContext context) {
    final bool timeWarning = remainingSeconds < 120;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2B),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Группа $studentGroup',
                  style: TextStyle(
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F131C),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Вопрос ${currentIndex + 1} из $totalQuestions',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: timeWarning
                  ? const LinearGradient(
                      colors: [Color(0xFF7C2D12), Color(0xFF991B1B)],
                    )
                  : null,
              color: timeWarning ? null : const Color(0xFF0F131C),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: timeWarning
                    ? const Color(0xFFE9A568).withValues(alpha: 0.4)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.2),
                width: timeWarning ? 2 : 1,
              ),
              boxShadow: timeWarning
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE9A568).withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: timeWarning
                      ? const Color(0xFFE9A568)
                      : const Color(0xFF38BDF8),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  formatTimer(remainingSeconds),
                  style: TextStyle(
                    color:
                        timeWarning ? const Color(0xFFE9A568) : const Color(0xFF38BDF8),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (linkLost) ...[
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9A568).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            color: Color(0xFFE9A568), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Нет связи',
                          style: TextStyle(
                            color: Color(0xFFE9A568),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
