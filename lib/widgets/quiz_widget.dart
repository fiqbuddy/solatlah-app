import 'package:flutter/material.dart';

class QuizWidget extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final bool isAlreadyPassed;
  final VoidCallback onPassed;

  const QuizWidget({
    super.key,
    required this.questions,
    required this.isAlreadyPassed,
    required this.onPassed,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  int _currentIndex = 0;
  String? _selectedOption;
  bool _answered = false;
  int _correctCount = 0;
  bool _quizDone = false;

  Map<String, dynamic> get _current => widget.questions[_currentIndex];

  String get _correctOption => _current['correct_option'];

  String _getOptionText(String key) {
    switch (key) {
      case 'a':
        return _current['option_a'] ?? '';
      case 'b':
        return _current['option_b'] ?? '';
      case 'c':
        return _current['option_c'] ?? '';
      case 'd':
        return _current['option_d'] ?? '';
      default:
        return '';
    }
  }

  void _selectOption(String option) {
    if (_answered) return;
    final correct = option == _correctOption;
    setState(() {
      _selectedOption = option;
      _answered = true;
      if (correct) _correctCount++;
    });
  }

  void _next() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      setState(() => _quizDone = true);
      final passed = _correctCount == widget.questions.length;
      if (passed && !widget.isAlreadyPassed) {
        Future.delayed(const Duration(milliseconds: 500), widget.onPassed);
      }
    }
  }

  void _retry() {
    setState(() {
      _currentIndex = 0;
      _selectedOption = null;
      _answered = false;
      _correctCount = 0;
      _quizDone = false;
    });
  }

  Color _optionColor(String option) {
    if (!_answered) return Colors.white;
    if (option == _correctOption) return const Color(0xFFE8F5E9);
    if (option == _selectedOption) return const Color(0xFFFFEBEE);
    return Colors.white;
  }

  Color _optionBorderColor(String option) {
    if (!_answered) {
      return _selectedOption == option
          ? const Color(0xFF2E7D32)
          : Colors.grey.shade200;
    }
    if (option == _correctOption) return const Color(0xFF2E7D32);
    if (option == _selectedOption) return const Color(0xFFE53935);
    return Colors.grey.shade200;
  }

  Widget _optionIcon(String option) {
    if (!_answered) {
      return Icon(
        _selectedOption == option
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color:
            _selectedOption == option ? const Color(0xFF2E7D32) : Colors.grey,
        size: 20,
      );
    }
    if (option == _correctOption) {
      return const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20);
    }
    if (option == _selectedOption) {
      return const Icon(Icons.cancel, color: Color(0xFFE53935), size: 20);
    }
    return const Icon(Icons.radio_button_unchecked,
        color: Colors.grey, size: 20);
  }

  @override
  Widget build(BuildContext context) {
    if (_quizDone) return _buildResult();

    final total = widget.questions.length;
    final progress = (_currentIndex + 1) / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kuiz',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / $total',
                  style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 20),

          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _current['question'],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ...['a', 'b', 'c', 'd'].map((option) {
            final text = _getOptionText(option);
            if (text.isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => _selectOption(option),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _optionColor(option),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _optionBorderColor(option),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    _optionIcon(option),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          color: _answered && option == _correctOption
                              ? const Color(0xFF2E7D32)
                              : _answered && option == _selectedOption
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF2D2D2D),
                          fontWeight: _answered && option == _correctOption
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Feedback
          if (_answered) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedOption == _correctOption
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedOption == _correctOption
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: _selectedOption == _correctOption
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE53935),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedOption == _correctOption
                          ? 'Betul! Syabas!'
                          : 'Jawapan betul: ${_getOptionText(_correctOption)}',
                      style: TextStyle(
                        color: _selectedOption == _correctOption
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE53935),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentIndex < widget.questions.length - 1
                      ? 'Seterusnya →'
                      : 'Selesai',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResult() {
    final total = widget.questions.length;
    final passed = _correctCount == total;
    final alreadyPassed = widget.isAlreadyPassed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            passed || alreadyPassed ? Icons.emoji_events : Icons.replay,
            color: passed || alreadyPassed
                ? const Color(0xFFFFD700)
                : const Color(0xFFE53935),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            passed
                ? 'Tahniah! Semua betul!'
                : alreadyPassed
                    ? 'Cuba lagi! Tapi anda sudah lulus pelajaran ini.'
                    : 'Belum lulus. Cuba lagi!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: passed || alreadyPassed
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_correctCount / $total soalan betul',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _correctCount / total,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor: AlwaysStoppedAnimation<Color>(
                passed ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              if (!passed) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cuba Lagi'),
                  ),
                ),
                if (alreadyPassed) const SizedBox(width: 12),
              ],
              if (passed || alreadyPassed)
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onPassed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Teruskan'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
