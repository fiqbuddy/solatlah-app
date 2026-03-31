import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechTestWidget extends StatefulWidget {
  final String expectedText;
  final bool isAlreadyPassed;
  final VoidCallback onPassed;

  const SpeechTestWidget({
    super.key,
    required this.expectedText,
    required this.onPassed,
    this.isAlreadyPassed = false,
  });

  @override
  State<SpeechTestWidget> createState() => _SpeechTestWidgetState();
}

class _SpeechTestWidgetState extends State<SpeechTestWidget> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  String _spokenText = '';
  bool? _passed;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (mounted) setState(() => _isInitialized = available);
  }

  Future<void> _startListening() async {
    if (!_isInitialized) return;
    setState(() {
      _spokenText = '';
      _passed = null;
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() => _spokenText = result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'ar_SA', // Arabic locale for better recognition
    );

    setState(() => _isListening = true);
  }

  Future<void> _stopAndCheck() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _isChecking = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    _checkResult();
  }

  void _checkResult() {
    final spoken = _normalizeText(_spokenText);
    final expected = _normalizeText(widget.expectedText);

    debugPrint('Spoken: "$spoken"');
    debugPrint('Expected: "$expected"');

    if (spoken.isEmpty) {
      setState(() {
        _passed = false;
        _isChecking = false;
      });
      return;
    }

    if (spoken == expected) {
      _setPassed(true);
      return;
    }

    final spokenWords = spoken.split(' ');
    final expectedWords = expected.split(' ');
    int matchedWords = 0;
    for (final expWord in expectedWords) {
      if (spokenWords.any((w) => w == expWord)) matchedWords++;
    }

    final ratio = matchedWords / expectedWords.length;
    debugPrint('Matched: $matchedWords/${expectedWords.length} = $ratio');
    _setPassed(ratio >= 0.8);
  }

  void _setPassed(bool passed) {
    setState(() {
      _passed = passed;
      _isChecking = false;
    });
    if (passed) {
      Future.delayed(const Duration(seconds: 1), widget.onPassed);
    }
  }

  String _normalizeText(String text) {
    return text
        .trim()
        // Remove Arabic diacritics/tashkeel
        .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F]'), '')
        // Remove tatweel
        .replaceAll('\u0640', '')
        // Normalize alef variations (أ إ آ ا) all to bare alef
        .replaceAll(RegExp(r'[\u0623\u0625\u0622]'), '\u0627')
        // Normalize ya variations (ى) to ي
        .replaceAll('ى', 'ي')
        // Remove punctuation
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
        // Normalize spaces
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // Simple similarity check using character overlap
  // double _similarityScore(String a, String b) {
  //   if (a.isEmpty || b.isEmpty) return 0;
  //   final longer = a.length > b.length ? a : b;
  //   final shorter = a.length > b.length ? b : a;
  //   int matches = 0;
  //   for (int i = 0; i < shorter.length; i++) {
  //     if (longer.contains(shorter[i])) matches++;
  //   }
  //   return matches / longer.length;
  // }

  void _retry() {
    setState(() {
      _spokenText = '';
      _passed = null;
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Speech Test',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Read the text below clearly into your microphone',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Expected text to read
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E7D32)),
            ),
            child: Column(
              children: [
                const Text('Read this:',
                    style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  widget.expectedText,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'serif',
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Mic button
          if (_passed == null && !_isChecking) ...[
            GestureDetector(
              onTap: _isListening ? _stopAndCheck : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isListening
                      ? const Color(0xFFE53935)
                      : const Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening
                              ? const Color(0xFFE53935)
                              : const Color(0xFF2E7D32))
                          .withOpacity(0.4),
                      blurRadius: _isListening ? 20 : 10,
                      spreadRadius: _isListening ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isListening ? 'Listening... tap to stop' : 'Tap mic to start',
              style: TextStyle(
                color: _isListening ? const Color(0xFFE53935) : Colors.grey,
                fontSize: 13,
              ),
            ),

            // Live transcript
            if (_spokenText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '"$_spokenText"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],

          // Checking
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            ),

          // Result
          if (_passed != null) ...[
            const SizedBox(height: 8),
            Icon(
              _passed! ? Icons.check_circle : Icons.cancel,
              color:
                  _passed! ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
              size: 56,
            ),
            const SizedBox(height: 8),
            Text(
              _passed!
                  ? 'Well done! Correct recitation.'
                  : widget.isAlreadyPassed
                      ? 'Not quite right, but you already passed this lesson!'
                      : 'Not quite right. Try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _passed!
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE53935),
              ),
            ),
            if (_spokenText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'You said: "$_spokenText"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            if (!_passed!) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isAlreadyPassed
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.isAlreadyPassed
                      ? 'Try Again (Practice)'
                      : 'Try Again'),
                ),
              ),
            ],
          ],

          if (!_isInitialized) ...[
            const SizedBox(height: 12),
            const Text(
              'Microphone not available on this device.',
              style: TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
